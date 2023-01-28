//
//  udp.swift
//  qemnet
//
//  Created by tom on 03.04.2022.
//
/*
import Foundation
import Network

class udp {
    private var listener: NWListener?
    private var connection: NWConnection?

    private var data_callback: Optional<(Data) -> Void> = nil
    private var port = 9999

    func set_port(port: Int) {
        self.port = port
    }
    func on_data(callback: @escaping (Data)->Void) {
        data_callback = callback
    }
    private func receiver(con: NWConnection) -> Void {
        con.receiveMessage { completeContent, contentContext, isComplete, error in
            if (completeContent == nil) || (error != nil) {
                print("[udp] connection terminated")
                return
            }
            print(String(format: "[udp] got data %d", completeContent!.count))
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
            print("[udp] did send")
        }))
    }

    func start(queue: DispatchQueue) {
        do {
            print("[udp] start")
            let lst = try NWListener(using: .udp, on: NWEndpoint.Port(String(self.port))!)
            lst.newConnectionHandler = { con in
                self.connection = con
                print("new con")
                print(con.endpoint)
                self.receiver(con: con)
                con.stateUpdateHandler =  { state in
                    print("[udp] state change ", state)
                }
                con.viabilityUpdateHandler = { state in
                    print("[udp] viability update ", state)
                }
                con.start(queue: queue)
            }
            lst.stateUpdateHandler = { state in
                print("[udp] listener state ", state)
            }
            lst.start(queue: queue)
            self.listener = lst
        } catch {
            
        }
    }

    func stop() {
        self.listener?.cancel()
        self.connection?.cancel()
    }
}
*/
