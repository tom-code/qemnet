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
        var arch = "x86_64"
        if let a = config.architecture {
            arch = a
        }
        task.executableURL = URL(fileURLWithPath: "/usr/local/bin/qemu-system-\(arch)")
        task.arguments = []
        task.arguments!.append("-m")
        task.arguments!.append("\(config.ram)")

        task.arguments!.append("-hda")
        task.arguments!.append(config.image)

        if let accel = config.accel {
            task.arguments!.append("-accel")
            task.arguments!.append(accel)
        }

        if let machine = config.machine {
            task.arguments!.append("-M")
            task.arguments!.append(machine)
        }

        if let cores = config.cores {
            task.arguments!.append("-smp")
            task.arguments!.append("cores=\(cores)")
        }
        if let kernel = config.kernel {
            task.arguments!.append("-kernel")
            task.arguments!.append(kernel)
        }

        if let args = config.args {
            let spl = args.components(separatedBy: " ")
            task.arguments!.append(contentsOf: spl)
        }

        var id = 0
        for link in config.links {
            var device = "e1000"
            if let dev = link.device {
                device = dev
            }
            task.arguments!.append("-device")
            task.arguments!.append("\(device),netdev=net\(id)")

            task.arguments!.append("-netdev")
            task.arguments!.append("socket,id=net\(id),udp=:\(link.local_port),localaddr=:\(link.remote_port)")
            id = id + 1
        }
        print("vm args: \(task.arguments!)")
        for arg in task.arguments! {
            print("  \(arg)")
        }
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
            print(String.init(decoding: out, as: UTF8.self), terminator: "")
            if !task.isRunning {
                break
            }
        }
    } catch {
        print("except \(error)")
    }
}
