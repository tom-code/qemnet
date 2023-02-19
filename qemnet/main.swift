//
//  main.swift
//  qemnet
//
//  Created by tom on 03.04.2022.
//

import Foundation

class VMNetLink {
    private var udpsocket: udp2
    private var vmn: vmnet
    private var parent_dev = ""
    private var mode: vmnet.Mode
    private var net_id = ""

    init(local_port: Int, remote_port: Int, mode: vmnet.Mode) {
        udpsocket = udp2()
        udpsocket.set_port(local: local_port, remote: remote_port)
        vmn = vmnet()
        vmn.setMode(mode: mode)
        self.mode = mode
    }
    func set_verbose(verbose: Bool) {
        udpsocket.set_verbose(verbose: verbose)
        vmn.set_verbose(verbose: verbose)
    }
    func set_parent_dev(dev: String) {
        parent_dev = dev
    }
    func set_net_id(id: String) {
        net_id = id
    }
    func start(queue: DispatchQueue) {
        if mode == vmnet.Mode.Bridged {
            vmn.setBridgeDev(dev: parent_dev)
        }
        vmn.setNetId(id: net_id)
        vmn.on_data { data in
            self.udpsocket.send(data: data)
        }

        udpsocket.on_data { data in
            self.vmn.send(data: data)
        }
        udpsocket.start(queue: queue)
        _ = vmn.start(queue: queue)
    }
    func stop() {
        udpsocket.stop()
        vmn.stop()
    }
}

class VMInstance {

    private var links: [String: VMNetLink] = [:]
    private let config: VMConfig;
    private var verbose = false;
    private let queue: DispatchQueue;
    private let semaphore = DispatchSemaphore(value:0)

    init?(config_file: String, dispatch_queue: DispatchQueue) {
        let config_res = config_decode(filename: config_file);
        if config_res == nil {
            return nil
        } else {
            config = config_res!
        }
        queue = dispatch_queue;
    }

    private func init_links() {
        for lnk in config.links {
            var type = vmnet.Mode.Shared
            if (lnk.type != nil) && (lnk.type == NetLink.Typex.host) {
                type = vmnet.Mode.Host
            }
            var parent = ""
            if (lnk.type != nil) && (lnk.type == NetLink.Typex.bridged) {
                type = vmnet.Mode.Bridged
                parent = lnk.parent ?? ""
            }
            let l = VMNetLink(local_port: lnk.local_port, remote_port: lnk.remote_port, mode: type)
            l.set_parent_dev(dev: parent)
            var netid = ""
            if let id = lnk.netid {
                netid = id
            }
            l.set_net_id(id: netid)
            l.set_verbose(verbose: verbose)
            l.start(queue: queue)
            links[lnk.id] = l
        }
    }
    private func stop_links() {
        for link in links {
            print("stopping link \(link)")
            link.value.stop()
        }
    }

    func start() {
        init_links()
        exec(config: config) {
            self.semaphore.signal()
        }
    }
    func wait_for_finish() {
        semaphore.wait()
    }
    deinit {
        print("deinit")
    }
    func close() {
        stop_links()
    }
}


let uid = getuid()
print("running with uid: \(uid)")
if uid != 0 {
    print("networking not supported for regular user. run wih sudo!")
    exit(1)
}

var config_file = "config.json"
if CommandLine.arguments.count > 1 {
    config_file = CommandLine.arguments[1]
}

let queue = DispatchQueue(label: "qemnet")
var vmOpt = VMInstance(config_file: config_file, dispatch_queue: queue)
if let vm = vmOpt {
    vm.start()
    vm.wait_for_finish()
    vm.close()
}
