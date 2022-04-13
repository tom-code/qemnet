//
//  main.swift
//  qemnet
//
//  Created by tom on 03.04.2022.
//

import Foundation

class link {
    private var udpsocket: udp2?
    private var vmn: vmnet?
    private var parent_dev = ""
    private var mode: vmnet.Mode
    private var net_id = ""

    init(local_port: Int, remote_port: Int, mode: vmnet.Mode) {
        udpsocket = udp2()
        udpsocket!.set_port(local: local_port, remote: remote_port)
        vmn = vmnet()
        vmn!.setMode(mode: mode)
        self.mode = mode
    }
    func set_verbose(verbose: Bool) {
        udpsocket?.set_verbose(verbose: verbose)
        vmn?.set_verbose(verbose: verbose)
    }
    func set_parent_dev(dev: String) {
        parent_dev = dev
    }
    func set_net_id(id: String) {
        net_id = id
    }
    func start() {
        if mode == vmnet.Mode.Bridged {
            vmn?.setBridgeDev(dev: parent_dev)
        }
        vmn?.setNetId(id: net_id)
        vmn!.on_data { data in
            self.udpsocket!.send(data: data)
        }

        udpsocket!.on_data { data in
            self.vmn!.send(data: data)
        }
        udpsocket!.start(queue: queue)
        _ = vmn!.start(queue: queue)
    }
    func stop() {
        udpsocket!.stop()
        vmn!.stop()
    }
}

var config_file = "config.json"

print(CommandLine.arguments)
if CommandLine.arguments.count > 1 {
    config_file = CommandLine.arguments[1]
}

var links: [String: link] = [:]
let queue = DispatchQueue(label: "qemnet")


let config = config_decode(filename: config_file)
if config == nil {
    print("can't read configuration")
    exit(1)
}
var verbose = false;
if config?.verbose != nil {
    verbose = config?.verbose == true
}
for lnk in config?.links ?? [] {
    var type = vmnet.Mode.Shared
    if (lnk.type != nil) && (lnk.type == NetLink.Typex.host) {
        type = vmnet.Mode.Host
    }
    var parent = ""
    if (lnk.type != nil) && (lnk.type == NetLink.Typex.bridged) {
        type = vmnet.Mode.Bridged
        parent = lnk.parent ?? ""
    }
    let l = link(local_port: lnk.local_port, remote_port: lnk.remote_port, mode: type)
    l.set_parent_dev(dev: parent)
    var netid = ""
    if let id = lnk.netid {
        netid = id
    }
    l.set_net_id(id: netid)
    l.set_verbose(verbose: verbose)
    l.start()
    links[lnk.id] = l
}


exec(config: config!)

for link in links {
    link.value.stop()
}

