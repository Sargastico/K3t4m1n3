FROM mikoto2000/qemu-aarch64

RUN mkdir k3t4m1n3

COPY ./xen /k3t4m1n3
COPY ./u-boot.bin /k3t4m1n3
COPY ./dom0-kernel.bin /k3t4m1n3
COPY ./dom0-rootfs.cpio.gz /k3t4m1n3
COPY ./vmlinuz-lts /k3t4m1n3
COPY ./rootfs.cpio.gz /k3t4m1n3
COPY ./virt-gicv3.dtb /k3t4m1n3

WORKDIR /k3t4m1n3
