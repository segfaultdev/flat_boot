# flat_boot
flat_boot is a single-stage, 512-byte bootloader designed for the x86 platform, and it has been tested on QEMU, VirtualBox, Bochs, a core 2 quad, a modern i7 and two 486s. Unlike most other single-stage bootloaders out there, this one is almost as configurable and user-friendly as advanced bootloaders like GRUB, making it a great alternative if the OS you want to load is loadable in binary format.

## Screenshots

![](bob)

## Does it boot into protected mode?
Yes, and it is loaded into address 0x8000, inside the first MiB, but the loaded GDT just has a single code entry, and you should replace it in your first instruction on the loaded binary with something like ```lgdt [cs:gdt_ptr]```.

## Ok that's cool, but how do I set it up?
It is quite easy, you just make a flat_fs(https://github.com/segfaultdev/flat_fs) image with my own tool, with this single file:
- boot/config.txt: A file containing, for each entry, its name, a newline, its path to the binary relative to /boot and another newline.

## Why flat_fs and not something like FAT32?
Because this was designed originally for my own OS, and it uses this filesystem, but you could port it to FAT32 or even better, exFAT, if you want.

## Why do you waste your time doing this? / Why would I want to use it? / You could use GRUB instead!
1. I do not like GRUB as it is incredibly bloated.
2. For me it is easier to use a raw binary.
3. I do not have to reserve some space for the bootloader as it fits into a single sector.
4. It uses my own filesystem, and I love it.
5. Because it is entretaining to be replacing every ```mov ax, 0x0000``` you find with ```xor ax, ax``` just to get it under the 512-byte barrier.

## Licensing
Public domain, do whatever you want with it.
