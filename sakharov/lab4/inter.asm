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
        OLD_CURSOR           dw 0

        INTERRUPTIONS_INFO   db " INTER COUNT"
        INTERRUPTIONS_COUNT  dw 0
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
        push bp

        mov ax, ss
        mov ds, ax
        mov es, ax

        mov ah, 03h ; read cursor
        mov bh, 0h
        int 10h
        mov OLD_CURSOR, dx

        mov ax, INTERRUPTIONS_COUNT
        inc ax
        mov INTERRUPTIONS_COUNT, ax

        xor dx, dx
        mov bx, 10
        xor cx, cx
    CONVERTATION_LOOP_INTER:
        div bx
        push dx
        xor dx, dx
        inc cx
        cmp ax, 0h
            jnz CONVERTATION_LOOP_INTER

        mov ah, 2
        mov bh, 0
        mov dh, 23
        mov dl, 0
        int 10h

    PRINT_NUM_INTER:
        pop ax
        or al, 30h

        push cx

        mov ah, 09h ; write character
        mov bl, 5h ; magenta color
        mov bh, 0 ; page number
        mov cx, 1 ; number of times to write
        int 10h

        mov ah, 2 ; set cursor position
        mov bh, 0 ; page number
        add dx, 1 ; dh - row, dl - column
        int 10h

        pop cx
            loop PRINT_NUM_INTER

    PRINT_INFO_INTER:
        mov cx, INTERRUPTIONS_COUNT
        mov ch, 0
        shr cl, 1
        shr cl, 1
        shr cl, 1
        shr cl, 1

        mov bp, offset INTERRUPTIONS_INFO
        mov ah, 13h ; pring string
        mov al, 1h ; string contains attributes
        ;mov bl, 5h ; light red color
        mov bl, cl ; cool rainbow color
        mov bh, 0 ; page number
        mov cx, offset INTERRUPTIONS_COUNT ; string end
        sub cx, offset INTERRUPTIONS_INFO ; string start
        int 10h

        mov dx, OLD_CURSOR
        mov ah, 02h ; set cursor
        mov bh, 0h
        int 10h

        pop bp
        pop ds
        pop es
        pop si
        pop dx
        pop cx
        pop bx
        pop ax

        mov ss, OLD_SS
        mov sp, OLD_SP

        mov al, 20h
        out 20h, al
        iret
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
        mov al, 1Ch
        int 21h
        mov SAVED_IP, bx
        mov SAVED_CS, es

        mov dx, offset INTERRUPT
        mov ax, seg INTERRUPT
        mov ds, ax
        mov ah, 25h
        mov al, 1Ch
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
        mov al, 1Ch
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
        mov al, 1Ch
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
        mov al, 1Ch
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
