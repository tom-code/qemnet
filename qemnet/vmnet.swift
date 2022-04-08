//
//  vmnet.swift
//  qemnet
//
//  Created by tom on 03.04.2022.
//

import Foundation
import vmnet


class vmnet {
    private var queue: DispatchQueue?
    private var interface: interface_ref?
    let max_packet_size = 10*1024

    enum Mode {
        case Shared
        case Host
    }
    private var mode = Mode.Host

    func setMode(mode: Mode) {
        self.mode = mode
    }

    func start(queue : DispatchQueue) -> Bool {
        self.queue = queue
        let semaphore = DispatchSemaphore(value: 0)
        let iface_desc = xpc_dictionary_create(nil, nil, 0)
        var net_mode = UInt64(operating_modes_t.VMNET_HOST_MODE.rawValue)
        if mode == Mode.Shared {
            net_mode = UInt64(operating_modes_t.VMNET_SHARED_MODE.rawValue)
        }
        xpc_dictionary_set_uint64(iface_desc, vmnet_operation_mode_key, net_mode)

        var create_ok = false
        func create_completed(ret: vmnet_return_t, params: xpc_object_t?) -> Void {
            if ret != vmnet_return_t.VMNET_SUCCESS {
                print("[vmnet] create failed \(ret)")
            } else {
                print("[vmnet] create completed")
                create_ok = true
            }
            semaphore.signal()
        }

        let interface = vmnet_start_interface(iface_desc, self.queue!, create_completed)
        print("[vmnet] creating")
        if interface == nil {
            print("[vmnet] interface start failed")
            exit(1)
        }
        semaphore.wait()
        print("[vmnet] create done")
        if !create_ok {
            return false
        }
        vmnet_interface_set_event_callback(interface!, interface_event_t.VMNET_INTERFACE_PACKETS_AVAILABLE, queue) { ev, obj in
            self.read_packet()
        }
        self.interface = interface
        return true
    }

    func stop() {
        if self.interface == nil {
            return
        }
        let semaphore = DispatchSemaphore(value: 0)
        vmnet_stop_interface(self.interface!, self.queue!, { (ret:vmnet_return_t) -> Void in
            print("[vmnet] stopped")
            semaphore.signal()
        })
        semaphore.wait()
    }

    private var data_callback: Optional<(Data) -> Void> = nil
    func on_data( callback: @escaping (Data) -> Void ) {
        self.data_callback = callback
    }

    func send(data: Data) {
        if self.interface == nil {
            return
        }
        let size = data.count
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
        data.copyBytes(to: buffer, count: size)
        let buffere = buffer.deinitialize(count: size)


        let iov = UnsafeMutablePointer<iovec>.allocate(capacity: 1)
        iov.pointee.iov_len = size
        iov.pointee.iov_base = buffere

        var pkt = vmpktdesc.init(vm_pkt_size: size, vm_pkt_iov: iov, vm_pkt_iovcnt: 1, vm_flags: 0)

        var cnt : Int32 = 1
        vmnet_write(interface!, &pkt, &cnt)
    }

    private func read_packet() {
        let size = max_packet_size
        let buffer = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: 4)


        let iov = UnsafeMutablePointer<iovec>.allocate(capacity: 1)
        iov.pointee.iov_len = size
        iov.pointee.iov_base = buffer

        var pkt = vmpktdesc.init(vm_pkt_size: size, vm_pkt_iov: iov, vm_pkt_iovcnt: 1, vm_flags: 0)

        var cnt : Int32 = 1
        let status = vmnet_read(interface!, &pkt, &cnt)
        if status != vmnet_return_t.VMNET_SUCCESS {
            print("[vmnet] read failed with \(status.rawValue)")
        }

        if data_callback != nil {
            let d = Data.init(bytes:buffer, count:pkt.vm_pkt_size)
            data_callback!(d)
        }
    }
}