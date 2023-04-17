<div align="center">
  <img src="https://github.com/Sargastico/K3t4m1n3/blob/main/k3t4m1n3_avatar.png" width="30%">
  <h1> K3T4M1N3 </h1>
  <i> ARM Virtual Machine Introspection Playground </i><br>
  <i> >> Xen Type-1 Hypervisor + LibVMI << </b></i>
  <h1></h1>

<div align="left">

# Specs

- ARM Emulator: 
  - Powered by [QEMU](https://www.qemu.org/docs/master/system/target-arm.html)
  - Cortex-A57 (aarch54)
- Bootloader: [U-Boot](https://u-boot.readthedocs.io/en/latest/#)
- Type-1 Hypervisor: Xen version 4.12.2 (xen-4.12+poky) (aarch64-poky-linux-gcc (GCC) 9.3.0)
- Virtual Machine Introspection Library: [LibVMI](https://github.com/libvmi/libvmi)

# How to run

-> Linux and Docker are the only requirements (because windows sucks)

Setup everything up is usually a PITA (pain in the @$$). Let's use a docker image to make things easier.

1. Pull docker image from [docker hub](https://hub.docker.com/r/sargx/k3t4m1n3)

```
sudo docker pull sargx/k3t4m1n3:latest
```

2. Execute the docker image using the "interactive mode" (-it flag):

```
sudo docker run -it sargx/k3t4m1n3
```

- You should get a shell running.


3. Boot up the ARM64 emulator (qemu) and the bootloader (u-boot):

```
qemu-system-aarch64 -D ./qemu-log.txt -machine virt,gic_version=3 -machine virtualization=true -cpu cortex-a57 -machine type=virt -m 4096 -smp 4 -bios u-boot.bin -device loader,file=xen,force-raw=on,addr=0x49000000 -device loader,file=dom0-kernel.bin,addr=0x47000000 -device loader,file=vmlinuz-lts,addr=0x53000000 -device loader,file=virt-gicv3.dtb,addr=0x44000000 -device loader,file=dom0-rootfs.cpio.gz,addr=0x417c29ea -device loader,file=rootfs.cpio.gz,addr=0x58000000 -nographic -no-reboot -chardev socket,id=qemu-monitor,host=localhost,port=7777,server,nowait,telnet -mon qemu-monitor,mode=readline
```

- Well, if everything worked, you should be looking at the u-boot interactive shell now.
- If you see something like "Hit any key to stop autoboot" followed by a countdown. Just ignore this and wait 5 seconds (I know you can do this).

Now we can set up the memory map of the whole system. 

4. Just copy and paste the following code (directly to the uboot interactive shell) and press enter

```
fdt addr 0x44000000

fdt resize

fdt set /chosen \#address-cells <1>
fdt set /chosen \#size-cells <1>

fdt mknod /chosen module@0

fdt set /chosen/module@0 compatible "xen,linux-zimage" "xen,multiboot-module"
fdt set /chosen/module@0 reg <0x47000000 0xe9fa00>
fdt set /chosen/module@0 bootargs "rw root=/dev/ram rdinit=/sbin/init   earlyprintk=serial,ttyAMA0 console=hvc0 earlycon=xenboot"

fdt resize

fdt mknod /chosen module@1

fdt set /chosen/module@1 compatible "xen,linux-initrd" "xen,multiboot-module"
fdt set /chosen/module@1 reg <0x417c29ea 0x283d616>

fdt mknod /chosen domU1

fdt set /chosen/domU1 compatible "xen,domain"
fdt set /chosen/domU1 \#address-cells <1>
fdt set /chosen/domU1 \#size-cells <1>
fdt set /chosen/domU1 \cpus <1>
fdt set /chosen/domU1 \memory <0 548576>
fdt set /chosen/domU1 vpl011

fdt mknod /chosen/domU1 module@0

fdt set /chosen/domU1/module@0 compatible "multiboot,kernel" "multiboot,module"
fdt set /chosen/domU1/module@0 reg <0x53000000 0x80dc38>
fdt set /chosen/domU1/module@0 bootargs "rw root=/dev/ram rdinit=/sbin/init console=ttyAMA0"

fdt mknod /chosen/domU1 module@1

fdt set /chosen/domU1/module@1 compatible "multiboot,ramdisk" "multiboot,module"
fdt set /chosen/domU1/module@1 reg <0x58000000 0x11af01>

booti 0x49000000 - 0x44000000
```
- Yeah, I know that I could fit all of this inside the device tree file, but for some unknown reason (probably my fault) my previous attempts makes the system crash.

5. The End. Congrats! :D

- If everything worked you should see Xen (Hypervisor) / Dom0 (Privileged Linux VM) / DomU (Guest Linux VM) booting screen.

# Memory Map


The default lab environment come with the following memory map:

```

DOM0-ROOTFS  = 0x417C29EA ---------- 0x44000000
DEVICE-TREE  = 0x44000000 ---------- 0x44001EFA
DOM0-KERNEL  = 0x47000000 ---------- 0x47E9FA00
XEN-KERNEL   = 0x49000000 ---------- 0x490D0550
DOMU-KERNEL  = 0x53000000 ---------- 0x5380DC38
DOMU-ROOTFS  = 0x58000000 ---------- 0x5811AF01

```

Some tips:
- If you use the given command from the "How to run" tutorial section, the system will create a "qemu-log.txt" file to save all the qemu related errors (check that if you face any problems)
- If you change/edit/rebuild any of the components, you will probaly need to rebuild the memory map as well.
- If change/edit/rebuild and still want to follow the "How to run" guide, you MUST edit the qemu launch command, to fit all the addresses to your new memory map.

You can easily get the size of any binary to do some math and build your own memory map like this:

```

printf "%x\n" `stat -c "%s" vmlinuz-lts`
# 0x80dc38

printf "%x\n" `stat -c "%s" dom0-kernel.bin`
# 0xe9fa00

printf "%x\n" `stat -c "%s" xen`
# 0xd0550

printf "%x\n" `stat -c "%s" dom0-rootfs.cpio.gz`
# 0x283d616

printf "%x\n" `stat -c "%s" rootfs.cpio.gz`
# 0x11af01

printf "%x\n" `stat -c "%s" virt-gicv3.dtb`
# 0x1efa

```

For those who want to dive deeper into the project, here's [my page on Notion](https://lofty-windscreen-3e7.notion.site/Roadmap-to-K3T4M1N3-e09a5bb5c6b84e95bcaeaa47eaa234ce) that I filled out while researching and developing everything.
