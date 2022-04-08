# qemnet
better networking for qemu on mac os x

Use mac api (vmnet) to connect qemu vm to network.

Use qemu from homebrew with "socket" networking. For examle:
```
qemu-system-x86_64  -m 1024 -hda alpine.qcow  -accel hvf -device e1000,netdev=net0 -netdev socket,id=net0,udp=:9999,localaddr=:9998
```
Then use tool with local_port=9999, remote_port=9998
