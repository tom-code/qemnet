//
//  exec.swift
//  qemnet
//
//  Created by tom on 10.04.2022.
//

import Foundation



func exec(config: Config) {
    do {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/local/bin/qemu-system-x86_64")
        task.arguments = []
        task.arguments!.append("-m")
        task.arguments!.append("\(config.ram)")
        task.arguments!.append("-hda")
        task.arguments!.append(config.image)
        task.arguments!.append("-accel")
        task.arguments!.append("hvf")

        if let cores = config.cores {
            task.arguments!.append("-smp")
            task.arguments!.append("cores=\(cores)")
        }

        var id = 0
        for link in config.links {
            task.arguments!.append("-device")
            task.arguments!.append("e1000,netdev=net\(id)")

            task.arguments!.append("-netdev")
            task.arguments!.append("socket,id=net\(id),udp=:\(link.local_port),localaddr=:\(link.remote_port)")
            id = id + 1
        }
        print("vm args: \(task.arguments!)")
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        try task.run()
        //task.waitUntilExit()
        let sem = DispatchSemaphore(value: 0)
        while true {
            pipe.fileHandleForReading.readabilityHandler =  { handle in
                sem.signal()
            }
            sem.wait()
            let out = pipe.fileHandleForReading.availableData
            print(String.init(decoding: out, as: UTF8.self))
            if !task.isRunning {
                break
            }
        }
    } catch {
        print("except \(error)")
    }
}
