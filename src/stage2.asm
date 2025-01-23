BITS 16
ORG 0x8000              ; Loaded at 0x8000

start:
    mov si, message
    call print_string
switch_modes:
    cli
    lgdt [gdt_desc]
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp CODE_SEG:protected_mode

BITS 32
protected_mode:
    mov eax, cr0
    and eax, 01111111111111111111111111111111b
    mov cr0, eax

    mov edi, 0x1000
    mov cr3, edi
    xor eax, eax
    mov ecx, 4096
    rep stosd
    mov edi, cr3

    mov DWORD [edi], 0x2003
    add edi, 0x1000
    mov DWORD [edi], 0x3003
    add edi, 0x1000
    mov DWORD [edi], 0x4003
    add edi, 0x1000  

    mov ebx, 0x00000003
    mov ecx, 512
.SetEntry:
    mov DWORD [edi], ebx
    add ebx, 0x1000
    add edi, 8
    loop .SetEntry  

    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr  

    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax
    lgdt [GDT.Pointer]
    jmp GDT.Code:Realm64 

[BITS 64]

Realm64:                       
    mov ax, GDT.Data            
    mov ds, ax                    
    mov es, ax                    
    mov fs, ax                    
    mov gs, ax                    
    mov ss, ax                    
    mov edi, 0xB8000              
    mov rax, 0x1F201F201F201F20
    mov ecx, 500
    rep stosq
    hlt


; Access bits
PRESENT        equ 1 << 7
NOT_SYS        equ 1 << 4
EXEC           equ 1 << 3
DC             equ 1 << 2
RW             equ 1 << 1
ACCESSED       equ 1 << 0

; Flags bits
GRAN_4K       equ 1 << 7
SZ_32         equ 1 << 6
LONG_MODE     equ 1 << 5

GDT:
    .Null: equ $ - GDT
        dq 0
    .Code: equ $ - GDT
        dd 0xFFFF                                  
        db 0                                       
        db PRESENT | NOT_SYS | EXEC | RW           
        db GRAN_4K | LONG_MODE | 0xF               
        db 0                                       
    .Data: equ $ - GDT
        dd 0xFFFF                                  
        db 0                                       
        db PRESENT | NOT_SYS | RW                  
        db GRAN_4K | SZ_32 | 0xF                   
        db 0                                       
    .TSS: equ $ - GDT
        dd 0x00000068
        dd 0x00CF8900
    .Pointer:
        dw $ - GDT - 1
        dq GDT


gdt_start:
    null_desc:
        dd 0
        dd 0
    code_desc:
        dw 0xffff
        dw 0
        db 0
        db 0b10011010
        db 0b11001111
        db 0
    data_desc:
        dw 0xffff
        dw 0
        db 0
        db 0b10010010
        db 0b11001111
        db 0
gdt_end:

gdt_desc:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG equ code_desc - gdt_start
DATA_SEG equ data_desc - gdt_start

print_string:
    lodsb
    or al, al
    jz done
    mov ah, 0x0E
    int 0x10
    jmp print_string
done:
    ret

message db "Stage 2 loaded successfully!", 0

times 512*16-($-$$) db 0