BITS 16              ; 16-bit real mode
ORG 0x7C00           ; Bootloader load address

start:
    cli
    xor ax, ax 
    mov ss, ax
    mov sp, 0x37ff
    mov es, ax
    mov ds, ax
    mov bp, 0x8200
    sti

    ; Print a message
    mov si, message
    call print_string

    ; Load stage 2 (assumes stage 2 is in sector 2)
    xor ax, ax
    mov ds, ax
    mov cl, 0x02
    mov ch, 0x00
    mov dl, 0x80           ; Drive 0 (floppy/hard disk)
    mov ah, 0x02           ; BIOS read function
    mov al, 0x10           ; Number of sectors to read
    mov bx, 0x8000         ; Load to address 0x8000
    int 0x13               ; Call BIOS

    jc fail

    ; Jump to stage 2
    jmp 0x8000

print_string:
    lodsb                  ; Load byte at [SI] into AL
    or al, al              ; Check for null terminator
    jz done
    mov ah, 0x0E           ; BIOS teletype function
    int 0x10               ; Call BIOS
    jmp print_string
done:
    ret

fail:
    mov al, ah
    add al, 0x30
    mov ah, 0x0E           
    int 0x10
    hlt


message db "Loading Stage 2...", 0
failmsg db "fail", 0

times 510-($-$$) db 0   ; Pad to 510 bytes
dw 0xAA55               ; Boot signature