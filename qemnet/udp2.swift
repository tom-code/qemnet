//
//  udp2.swift
//  qemnet
//
//  Created by tom on 05.04.2022.
//

import Foundation
import Network


class udp2 {
    private var connection: NWConnection?

    private var data_callback: Optional<(Data) -> Void> = nil
    private var local_port = 9999
    private var remote_port = 9998
    private var verbose = false

    func set_verbose(verbose: Bool) {
        self.verbose = verbose
    }
    func set_port(local: Int, remote: Int) {
        self.local_port = local
        self.remote_port = remote
    }
    func on_data(callback: @escaping (Data)->Void) {
        data_callback = callback
    }
    private func receiver(con: NWConnection) -> Void {
        con.receiveMessage { completeContent, contentContext, isComplete, error in
            if (completeContent == nil) || (error != nil) {
                print("[udp2] connection terminated")
                return
            }
            if self.verbose {
                print(String(format: "[udp] got data %d", completeContent!.count))
            }
            if self.data_callback != nil {
                self.data_callback!(completeContent!)
            }
            self.receiver(con: con)
        }
    }
    func send(data: Data) {
        if connection == nil {
            return
        }
        connection?.send(content: data, completion: .contentProcessed({ error in
            if self.verbose {
                print("[udp2] did send")
            }
        }))
    }
    func stop() {
        self.connection?.cancel()
    }
    func start(queue: DispatchQueue) {
        let params = NWParameters(dtls: nil, udp: .init())
        let local_port_tmp = NWEndpoint.Port(rawValue: UInt16(local_port))
        let remote_port_tmp = NWEndpoint.Port(rawValue: UInt16(remote_port))
        params.requiredLocalEndpoint = NWEndpoint.hostPort(host: .ipv4(.any), port: local_port_tmp!)
        connection = NWConnection(host: "127.0.0.1", port: remote_port_tmp!, using: params)

        connection?.stateUpdateHandler = { (state) in
            print("[udp2] state: \(state) \(self.connection?.endpoint as Optional)")
        }
        receiver(con: connection!)

        connection?.start(queue: queue)
    }
}
