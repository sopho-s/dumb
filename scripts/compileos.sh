#!/bin/bash

unset GTK_PATH

nasm -f bin src/stage1.asm -o bin/stage1.bin
nasm -f bin src/stage2.asm -o bin/stage2.bin

dd if=/dev/zero of=bin/boot.img bs=512 count=2880

dd if=bin/stage1.bin of=bin/boot.img conv=notrunc

dd if=bin/stage2.bin of=bin/boot.img bs=512 seek=1 conv=notrunc

qemu-system-x86_64 -drive format=raw,file=bin/boot.img