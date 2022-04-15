//
//  cmdloop.swift
//  qemnet
//
//  Created by tom on 10.04.2022.
//

import Foundation

class thrc {
    @objc func f1() {
        //cmdloop()
        print("olee1")
        sleep(1)
        print("olee2")
    }
}

func run_cmdloop() {
    let t = thrc()
    let tid = Thread(target: t, selector: #selector(thrc.f1), object: nil)
    tid.start()
}

func cmdloop() {

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
            print("quit!")
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
}

