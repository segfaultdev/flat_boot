[org 0x7C00]
[bits 16]

%define FLAT_FILE_BUFFER 0x8000
%define FLAT_DIR_BUFFER  0x1000
%define FLAT_LIST_BUFFER 0x2000
%define FLAT_HELP_BUFFER 0x3000

%define FLAT_STACK       0x7000
%define FLAT_DEVICE      0x7000
%define FLAT_DAP         0x7800

flat_boot:
  xor ax, ax
  mov ds, ax
  mov es, ax
  mov ss, ax
  mov sp, FLAT_STACK
  mov [FLAT_DEVICE], dl
  mov di, FLAT_DAP
  mov cx, 0x0008
  call mem_set

  mov bx, FLAT_DIR_BUFFER

  pusha
  ; xor ax, ax ; Could be skipped
  ; mov cx, 0x0008 ; Could be skipped
  mov dx, cx ; mov dx, 0x0008 ; Could be replaced with "mov dx, cx"
  call load_sectors
  popa

  mov si, flat_boot_dir_str
  mov di, FLAT_DIR_BUFFER
  ; xor ax, ax ; Could be skipped
  ; mov bx, FLAT_DIR_BUFFER
  call load_blocks ; Could be skipped

  mov si, flat_config_file_str
  ; mov di, FLAT_DIR_BUFFER
  ; xor ax, ax ; Could be skipped
  mov bx, FLAT_FILE_BUFFER
  call load_blocks

flat_menu:
  push es
  mov ah, 0xB8
  mov es, ax
  xor di, di
  mov cx, 0x0FA0
  mov ah, 0x0F
  call mem_set
  mov cx, 0x0050
  mov ah, 0x70
  call mem_set
  mov di, 0x0F00
  call mem_set
  ; xor ax, ax
  ; mov es, ax
  pop es
  mov si, flat_menu_reboot_str
  mov bx, 0x0DC2
  call puts
  mov si, flat_menu_title_str
  mov bx, 0x0002
  call puts
  mov bx, 0x014A
  mov si, FLAT_FILE_BUFFER
flat_menu_list:
  call puts
  call str_next
  call str_next
  pusha
  sub bl, 0x08
  mov al, [entry_cnt]
  add al, '0'
  mov [flat_menu_sel_str + 1], al
  mov si, flat_menu_sel_str
  call puts
  popa
  add bx, 0x00A0
  inc byte [entry_cnt]
  cmp byte [si], 0x00
  jne flat_menu_list
flat_menu_handler:
  xor ax, ax
  int 0x16
  
  cmp ah, 0x3B
  je help
  cmp ah, 0x3C
  je reboot
  cmp al, '0'
  jl flat_menu_handler
  sub al, '0'
  cmp al, [entry_cnt]
  jge flat_menu_handler
  mov cl, al
  add cl, cl
  inc cl
  mov si, FLAT_FILE_BUFFER
  call str_nth
  
  mov di, FLAT_DIR_BUFFER
  xor ax, ax
  mov bx, FLAT_FILE_BUFFER
  call load_blocks

  ; mov ax, 0x1112
  ; xor bl, bl
  ; int 0x10
  mov ax, 0x2401
  int 0x15
  cli
  lgdt [gdt_ptr]

  mov eax, cr0 
  or al, 0x01 ; or eax, 0x00000001
  mov cr0, eax
  jmp 0x08:FLAT_FILE_BUFFER

help:
  mov si, flat_help_file_str
  xor ax, ax
  mov bx, FLAT_HELP_BUFFER
  call load_blocks
  mov si, bx
  mov dh, 0x70
  mov bx, 0x0150
  mov cl, 0x10 ; Line count
.line_loop:
  test cl, cl
  jz .line_end
  mov ch, 0x40 ; Char count
.char_loop:
  test ch, ch
  jz .char_end
  mov dl, [si]
  inc si
  push es
  mov ah, 0xB8
  mov es, ax
  mov [es:bx], dx
  add bx, 0x0002
  pop es
  dec ch
  jmp .char_loop
.char_end:
  add bx, 0x0020
  dec cl
  jmp .line_loop
.line_end:
  xor ax, ax
  int 0x16
  ; jmp reboot

reboot:
  int 0x19

load_blocks:
  ; Args:
  ; - si: Entry to look for
  ; - di: List address
  ; - ax: Load segment
  ; - bx: Load offset
  pusha
  mov cx, 0x0040
.load_loop:
  test cx, cx
  jz $
  call str_cmp
  jz .end_load_loop
  add di, 0x0040
  dec cx
  jmp .load_loop
.end_load_loop:
  pusha
  xor ax, ax
  mov bx, FLAT_LIST_BUFFER
  mov cx, 0x0008
  mov dx, [di + 0x0030]
  call load_sectors ; Now we loaded the block list
  popa
  mov cx, 0x0100
  mov si, FLAT_LIST_BUFFER
  ; Do not set ax or bx, they were set by the user
.block_loop:
  test cx, cx
  jz .end_block_loop
  mov dx, [si]
  or dx, [si + 2]
  or dx, [si + 4]
  or dx, [si + 6]
  test dx, dx
  jz .end_block_loop
  push cx
  mov cx, [si + 8]
  mov dx, [si]
  call load_sectors
  pop cx
  add si, 0x0010
  jmp .block_loop
.end_block_loop:
  popa
  ret

mem_set: ; Thanks to Octocontrabass for making it smaller
  ; Args:
  ; - di: Buffer
  ; - cx: Word count
  ; - ax: What to set all words to
  pusha
  cld
  rep stosw
  popa
  ret

load_sectors:
  ; Args:
  ; - ax: Load segment
  ; - bx: Load offset
  ; - cx: Sector count
  ; - dx: LBA address to load from(limited to first 32 MiB)
  ; Returns:
  ; - ax: Next load segment
  ; - bx: Next load offset
  ; - cx: Zero if success
  ; - dx: Next LBA address to load from(also limited to first 32 MiB)
load_sectors_loop:
  test cx, cx
  jz load_sectors_end
  pusha
  mov si, FLAT_DAP
  mov byte [si], 0x10
  mov byte [si + 2], 0x01
  mov word [si + 4], bx
  mov word [si + 6], ax
  mov word [si + 8], dx
  mov ah, 0x42
  mov dl, [FLAT_DEVICE]
  int 0x13
  popa
  add ax, 0x20
  inc dx
  dec cx
  jmp load_sectors_loop
load_sectors_end:
  ret

str_cmp:
  pusha
str_cmp_loop:
  cmp byte [si], 0x20
  jl str_cmp_end
  mov al, [di]
  cmp [si], al
  jne str_cmp_end
  inc si
  inc di
  jmp str_cmp_loop
str_cmp_end:
  mov al, [si]
  cmp al, 0x0A
  je str_cmp_skip
  cmp [di], al
str_cmp_skip:
  popa
  ret

puts:
  push es
  pusha
  mov ax, 0xB800
  mov es, ax
puts_loop:
  mov dl, [ds:si]
  cmp dl, 0x20
  jl puts_end
  mov [es:bx], dl
  inc si
  add bx, 0x02
  jmp puts_loop
puts_end:
  popa
  pop es
  ret

str_next:
  cmp byte [si], 0x00
  je str_next_end
  inc si
  cmp byte [si - 1], 0x0A
  je str_next_end
  jmp str_next
str_next_end:
  ret

str_nth:
  test cl, cl
  jz str_nth_end
  dec cl
  call str_next
  jmp str_nth
str_nth_end:
  ret

flat_menu_title_str:  db "flat_boot:", 0x00 ; Menu title
flat_menu_sel_str:    db "[0]", 0x00 ; Menu selector
flat_menu_help_str:   db "[F1] Help", 0x00 ; Help string
flat_menu_reboot_str: db "[F2] Reboot" ; , 0x00 ; Reboot string

gdt_start:
gdt_null: ; 0x00
  dd 0x00000000
  dd 0x00000000
gdt_code: ; 0x08
  dw 0xFFFF ; limit_lo
  dw 0x0000 ; base_lo
  db 0x00   ; base_md
  db 0x9A   ; attributes
  db 0xCF   ; limit_hi + granularity
  db 0x00   ; base_hi
gdt_end:

gdt_ptr:
  dw gdt_end - gdt_start
  dd gdt_start

flat_config_file_str: db "config.txt", 0x00
flat_help_file_str:   db "help.txt", 0x00
flat_boot_dir_str:    db "boot" ; , 0x00

entry_cnt: db 0x00

times 0x1FE - ($ - $$) db 0x00
dw 0xAA55