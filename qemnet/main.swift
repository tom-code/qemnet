//
//  main.swift
//  qemnet
//
//  Created by tom on 03.04.2022.
//

import Foundation
import vmnet

let queue = DispatchQueue(label: "qemnet")

class link {
    private var udpsocket: udp2?
    private var vmn: vmnet?

    init(local_port: Int, remote_port: Int, mode: vmnet.Mode) {
        udpsocket = udp2()
        udpsocket!.set_port(local: local_port, remote: remote_port)
        vmn = vmnet()
        vmn!.setMode(mode: mode)
    }
    func start() {
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

var links: [String: link] = [:]


let config = config_decode()
print("ready...")
for lnk in config?.links ?? [] {
    var type = vmnet.Mode.Shared
    if (lnk.type != nil) && (lnk.type == NetLink.Typex.host) {
        type = vmnet.Mode.Host
    }
    let l = link(local_port: lnk.local_port, remote_port: lnk.remote_port, mode: type)
    l.start()
    links[lnk.id] = l
}


print("commands:")
print(" create <link_name> <local_port> <remote_port>")
print(" delete <link_name>")
print(" quit")


while true {
    let line = readLine()
    if line == nil {
        break
    }
    if line!.contains("quit") {
        break
    }
    let parts = line?.split(whereSeparator: { chr in
        if (chr == " ") || (chr == "\t") {
            return true
        } else {
            return false
        }
    })
    if let partsu = parts {
        if (partsu.count > 0) && (partsu[0] == "list") {
            for link in links {
                print("\(link.key)")
            }
        }
        if (partsu.count == 4) && (partsu[0] == "create") {
            let name = partsu[1]
            let local_port = Int((partsu[2]))!
            let remote_port = Int((partsu[3]))!
            let l = link(local_port: local_port, remote_port: remote_port, mode: vmnet.Mode.Shared)
            l.start()
            links[String(name)] = l
        }
        if (partsu.count == 2) && (partsu[0] == "delete") {
            let name = partsu[1]
            let l = links[String(name)]
            if l == nil {
                print("link \(name) not exists")
            } else {
                l!.stop()
                links.removeValue(forKey: String(name))
            }

        }
    }
}

for link in links {
    link.value.stop()
}

//l.stop()
