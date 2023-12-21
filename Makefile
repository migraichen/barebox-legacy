
PATH := /opt/OSELAS.Toolchain/i586-unknown-linux-gnu/bin:${PATH}
#PATH := /opt/OSELAS.Toolchain/x86_64-generic-linux-gnu/bin:${PATH}

.PHONY: build/barebox coreboot coreboot-toolchain

all: image.img

coreboot-toolchain:
	@echo "-- Build Coreboot toolchain ---"
	make -C coreboot crossgcc-i386 CPUS=$(nproc)

coreboot:
	@echo "-- Build Coreboot ---"
	make -C coreboot distclean
	make -C coreboot defconfig KBUILD_DEFCONFIG=configs/config.emulation_qemu_x86_i440fx
#	make -C coreboot defconfig KBUILD_DEFCONFIG=configs/config.emulation_qemu_x86_i440fx_x86_64
	make -C coreboot

build/barebox:
	@echo "-- Build Barebox ---"
	${RM} -rf build
	make -C barebox ARCH=x86 O=../build generic_debug_defconfig
	make -C barebox ARCH=x86 CC=i586-unknown-linux-gnu-gcc O=../build -j1
#	make -C barebox ARCH=x86 CC=x86_64-generic-linux-gnu-gcc O=../build -j1

image.img: barebox build/barebox
	@echo "--- Build Image ---"
	dd if=/dev/zero of=image.img bs=1G count=2
	echo start=1024K type=0B bootable | sfdisk image.img
	./build/scripts/setupmbr/setupmbr -s 32 -m build/barebox.bin -d image.img

config:
	make -C barebox ARCH=x86 O=../build menuconfig

copy:
	cp build/.config barebox/arch/x86/configs/generic_debug_defconfig

qemu: image.img
	qemu-system-i386 -M pc-i440fx-4.2 -bios coreboot/build/coreboot.rom -device VGA -serial stdio image.img	# Standard PC (i440FX + PIIX, 1996)
#	qemu-system-i386 -M pc-q35-4.2 -bios coreboot/build/coreboot.rom -device VGA -serial stdio image.img		# Standard PC (Q35 + ICH9, 2009)

qemudbg:
	qemu-system-i386 -s -S -M pc-i440fx-4.2 -bios coreboot/build/coreboot.rom -device VGA -serial stdio image.img

#	qemu-system-i386 -s -S -M pc-i440fx-4.2 -bios coreboot/build/coreboot.rom -device VGA -serial stdio image.img -usb -device usb-ehci,id=ehci -device usb-tablet,bus=usb-bus.0 -device usb-storage,bus=ehci.0,drive=usbstick

clean:
	${RM} -rf image.img build
