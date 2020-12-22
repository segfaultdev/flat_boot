**Warning:** This branch is a _development_ branch, and it probably will not compile.

# flat_boot
flat_boot is a single-stage, 512-byte bootloader designed for the x86 platform, and it has been tested on QEMU, VirtualBox, Bochs, a core 2 quad, a modern i7 and two 486s. Unlike most other single-stage bootloaders out there, this one is almost as configurable and user-friendly as advanced bootloaders like GRUB, making it a great alternative if the OS you want to load is loadable in binary format.

## Credits
Thanks to Octocontrabass and bzt for helping me adding more features and making the bootloader smaller!

## Features
- Basic error detection(will just hang in an infinite loop when it fails to find a file).
- Nice-looking menu, navigated by keyboard.
- Config file, with support for custom entry names.
- Up to 10 entries(or as many as you want if you do not care about using symbols and letters).
- Customizable help menu, add all the text you want into it.
- Reboot option from inside the bootloader itself.
- Boot binaries up to exactly 480 KiB.

## Screenshots
My OS's default boot menu:<br>
![](https://github.com/segfaultdev/flat_boot/raw/main/photo.png)

## Does it boot into protected mode?
Yes, and it is loaded into address 0x8000, inside the first MiB, but the loaded GDT just has a single code entry, and you should replace it in your first instruction on the loaded binary with something like ```lgdt [cs:gdt_ptr]```.

## Ok that's cool, but how do I set it up?
It is quite easy, you just make a flat_fs(https://github.com/segfaultdev/flat_fs) image with my own tool, with this single file:
- boot/config.txt: A file containing, for each entry, its name, a newline, its path to the binary relative to /boot and another newline.

## Why flat_fs and not something like FAT32?
Because this was designed originally for my own OS, and it uses this filesystem, but you could port it to FAT32 or even better, exFAT, if you want.

## Why do you waste your time doing this? You could simply use GRUB instead!
I can resume it into just two things:
1. GRUB is pretty bloated.
2. It is fun!

## Licensing
Public domain, do whatever you want with it.
