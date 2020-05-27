ASSUME CS:CODE, DS:DATA, SS:ASTACK

CODE SEGMENT

INTERRUPT PROC FAR
        jmp BEGIN_INTER

    ; DATA INTER
        SUB_STACK            dw 128 dup(0)
        INT_CODE             dw 1109
        SAVED_IP             dw 0
        SAVED_CS             dw 0
        SAVED_PSP            dw 0
        TEMP_SS              dw 0
        OLD_SS               dw 0
        OLD_SP               dw 0
        SYMBOL_ENTERED       db 0
    ; DATA INTER

    BEGIN_INTER:
        mov OLD_SS, ss
        mov OLD_SP, sp
        mov TEMP_SS, seg INTERRUPT
        mov ss, TEMP_SS
        mov sp, offset SUB_STACK
        add sp, 256

        push ax
        push bx
        push cx
        push dx
        push si
        push es
        push ds

        mov ax, SEG INTERRUPT
        mov ds, ax

        in al, 60h
        cmp al, 1Eh ; replace 'A'
        je PASS_1_INTER
        cmp al, 1Fh ; replace 'S'
        je PASS_2_INTER
        cmp al, 20h ; replace 'D'
        je PASS_3_INTER
        cmp al, 21h ; replace 'F'
        je PASS_4_INTER

        pushf
        call DWORD PTR SAVED_IP
        jmp INT_END

    PASS_1_INTER:
        mov SYMBOL_ENTERED, '1'
        jmp ACCEPT_INTER
    PASS_2_INTER:
        mov SYMBOL_ENTERED, '2'
        jmp ACCEPT_INTER
    PASS_3_INTER:
        mov SYMBOL_ENTERED, '3'
        jmp ACCEPT_INTER
    PASS_4_INTER:
        mov SYMBOL_ENTERED, '4'
        jmp ACCEPT_INTER

    ACCEPT_INTER:
        in al, 61h
        mov ah, al
        or al, 80h
        out 61h, al
        xchg al, al
        out 61h, al
        mov al, 20h
        out 20h, al

    PRINT_INTER_BUFFER:
        mov ah, 05h
        mov cl, SYMBOL_ENTERED
        mov ch, 00h
        int 16h
        or al, al
        jz INT_END

        mov ax, 0040h
        mov es, ax
        mov ax, es:[1Ah]
        mov es:[1Ch], ax
        jmp PRINT_INTER_BUFFER

    INT_END:
        pop ds
        pop es
        pop	si
        pop dx
        pop cx
        pop bx
        pop ax

        mov ss, OLD_SS
        mov sp, OLD_SP

        mov al, 20h
        out 20h, al
        IRET
INTERRUPT ENDP
    LAST_BYTE_INTER:

LOAD_INTERRUPTION PROC
        push ax
        push bx
        push cx
        push dx
        push es
        push ds

        mov ah, 35h
        mov al, 09h
        int 21h
        mov SAVED_IP, bx
        mov SAVED_CS, es

        mov dx, offset INTERRUPT
        mov ax, seg INTERRUPT
        mov ds, ax
        mov ah, 25h
        mov al, 09h
        int 21h
        pop ds

        mov dx, offset LAST_BYTE_INTER
        add dx, 100h
        mov cl, 4h
        shr dx, cl
        inc dx
        mov ah, 31h
        int 21h

        pop es
        pop dx
        pop cx
        pop bx
        pop ax

        ret
LOAD_INTERRUPTION ENDP



UNLOAD_INTERRUPTION PROC
        push ax
        push bx
        push dx
        push ds
        push es
        push si

        mov ah, 35h
        mov al, 09h
        int 21h

        mov si, offset SAVED_IP
        sub si, offset INTERRUPT
        mov dx, es:[bx + si]
        mov si, offset SAVED_CS
        sub si, offset INTERRUPT
        mov ax, es:[bx + si]

        push ds
        mov ds, ax
        mov ah, 25h
        mov al, 09h
        int 21h
        pop ds

        mov si, offset SAVED_PSP
        sub si, offset INTERRUPT
        mov ax, es:[bx + si]
        mov es, ax
        push es
        mov ax, es:[2Ch]
        mov es, ax
        mov ah, 49h
        int 21h

        pop es
        mov ah, 49h
        int 21h

        pop si
        pop es
        pop ds
        pop dx
        pop bx
        pop ax

        sti
        ret
UNLOAD_INTERRUPTION ENDP



INTER_CHECK PROC ; ax = 1 if interuppt loaded
        push bx
        push si

        mov ah, 35h
        mov al, 09h
        int 21h

        mov si, offset INT_CODE
        sub si, offset INTERRUPT
        mov ax, es:[bx + si]
        mov cx, 0
        cmp ax, INT_CODE
            jne INTER_CHECK_END
        mov cx, 1

    INTER_CHECK_END:
        mov ax, cx
        pop si
        pop bx
        ret
INTER_CHECK ENDP



UN_CHECK PROC ; ax = 1 if /un
        mov ax, 0;
        cmp byte ptr es:[82h], '/'
            jne CL_CHECK_END
        cmp byte ptr es:[83h], 'u'
            jne CL_CHECK_END
        cmp byte ptr es:[84h], 'n'
            jne CL_CHECK_END
        mov ax, 1

    CL_CHECK_END:
        ret
UN_CHECK ENDP



PRINT_STRING PROC NEAR
        push ax
        mov ah, 09h
        int 21h
        pop ax

        ret
PRINT_STRING ENDP



MAIN PROC
        push ds
        xor ax, ax
        push ax
        mov ax, DATA
        mov ds, ax
        mov SAVED_PSP, es

        call UN_CHECK
        cmp ax, 1
            je IF_UNLOAD_INTERRUPTION
        
    IF_LOAD_INTERRUPTION:
        call INTER_CHECK
        cmp ax, 1
            je MAIN_LOAD_AGAIN_INTERRUPTION
        
    MAIN_LOAD_INTERRUPTION:
        mov dx, offset LOADED_INFO
        call PRINT_STRING
        call LOAD_INTERRUPTION
        jmp MAIN_END

    MAIN_LOAD_AGAIN_INTERRUPTION:
        mov dx, offset ALREADY_LOADED_INFO
        call PRINT_STRING
        jmp MAIN_END


    IF_UNLOAD_INTERRUPTION:
        call INTER_CHECK
        cmp ax, 1
            je MAIN_UNLOAD_INTERRUPTION
        
    MAIN_NOT_LOADED_INTERRUPTION:
        mov dx, offset WAS_NOT_LOADED_INFO
        call PRINT_STRING
        jmp MAIN_END

    MAIN_UNLOAD_INTERRUPTION:
        call UNLOAD_INTERRUPTION
        mov dx, offset UNLOADED_INFO
        call PRINT_STRING
        jmp MAIN_END

    MAIN_END:
        xor al, al
        mov ah, 4Ch

        int 21h
    MAIN ENDP

CODE    ENDS

ASTACK  SEGMENT STACK
    dw  128 dup(0)
ASTACK  ENDS

DATA SEGMENT
    LOADED_INFO          db  "Interruption was loaded", 10, 13, "$"
    ALREADY_LOADED_INFO  db  "Interruption was already loaded", 10, 13, "$"
    UNLOADED_INFO        db  "Interruption was unloaded$"
    WAS_NOT_LOADED_INFO  db  "Interruption wasn't loaded$"
DATA ENDS

END MAIN
