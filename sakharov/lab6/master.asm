ASSUME CS:CODE, DS:DATA, ss:ASTACK

ASTACK SEGMENT STACK
    dw  128 dup(0)
    ASTACK ENDS

DATA SEGMENT
    SUCCESS_INFO      db "Program finished normally with code: $"
    CTRL_C_INFO       db "Program stopped by CRTL+C command$"
    ERR_FILENAME_INFO db "File not found in: $"
    START_STR_NAME    db "File name: $"
    FILENAME          db "bins.com", 0, "$"
    START_STR_PATH    db "File directory: $"
    MODULE_STR        db 150 dup(0)
    SLAVE_START_INFO  db "---Slave started---$"
    SLAVE_END_INFO    db "---Slave finished---$"

    CMD               db 17, "==TAIL EXAMPLE==", 0
    SAVED_PSP         dw ?
    SAVED_SS          dw ?
    SAVED_SP          dw ?

    PARAMS            dw 7 dup(?)
    MEMORY_ERROR      db 0
    ENDL              db 13, 10, "$"

    DATA ENDS

CODE SEGMENT

HEX_BYTE_PRINT PROC
        push ax
        push bx
        push dx

        mov ah, 0
        mov bl, 10h
        div bl
        mov dx, ax
        mov ah, 02h
        cmp dl, 0Ah
            jl PRINT_BYTE
        add dl, 07h
    PRINT_BYTE:
        add dl, '0'
        int 21h;

        mov dl, dh
        cmp dl, 0Ah
            jl PRINT_EXT
        add dl, 07h
    PRINT_EXT:
        add dl, '0'
        int 21h;

        pop dx
        pop bx
        pop ax
        ret
    HEX_BYTE_PRINT ENDP

PRINT_STRING PROC near
        push ax
        mov ah, 09h
        int 21h
        pop ax
        ret
    PRINT_STRING ENDP

PRINT_LINE PROC near
        push ax
        call PRINT_STRING
        mov dx, offset ENDL
        call PRINT_STRING
        pop ax
        ret
    PRINT_LINE ENDP


FREE_MEMORY PROC
        mov bx, offset PROGEND
        mov ax, es
        sub bx, ax
        mov cl, 4
        shr bx, cl
        mov ah, 4Ah
        int 21h
            jc MCATCH
        jmp MDEFAULT
    MCATCH:
        mov MEMORY_ERROR, 1
    MDEFAULT:
        ret
    FREE_MEMORY ENDP



FINISH PROC
        mov ah, 4Dh
        int 21h
        cmp ah, 1
            je ECTRLC
        mov dx, offset SUCCESS_INFO
        call PRINT_STRING
        call HEX_BYTE_PRINT
        mov dl, ah
        mov ah, 2h
        int 21h
        jmp EDEFAULT
    ECTRLC:
        mov dx, offset CTRL_C_INFO
        call PRINT_LINE
    EDEFAULT:
        ret
    FINISH ENDP


MAKE_PATH PROC
        push ax
        push es
        push si
        push di
        push dx

        push ax
        mov es, es:[2Ch]
        mov si, 0

    SKIP:
        mov ax, es:[si]
        inc si
        cmp ax, 0
        jne SKIP
        add si, 3
        mov di, offset MODULE_STR

    EMPATH:
        mov al, es:[si]
        mov BYTE PTR [di], al
        cmp al, 0
        je DEPATH
        inc di
        inc si
        jmp EMPATH

    DEPATH:
        mov al, [di]
        cmp al, '\'
        je RECALL
        mov BYTE PTR [di], 0
        dec di
        jmp DEPATH

    RECALL:
        pop si

    APPEND:
        inc di
        mov al, [si]
        cmp al, 0
        je PROCEED
        mov BYTE PTR [di], al
        inc si
        jmp APPEND

    PROCEED:
        mov BYTE PTR [di], 0
        mov BYTE PTR [di + 1], '$'

        mov dx, offset MODULE_STR
        call PRINT_LINE

        pop dx
        pop di
        pop si
        pop es
        pop ax

        ret
MAKE_PATH ENDP



MAIN PROC
        mov ax, DATA
        mov ds, ax

        mov ax, offset FILENAME
        call MAKE_PATH

        mov dx, offset START_STR_NAME
        call PRINT_STRING
        mov dx, offset FILENAME
        call PRINT_LINE
        mov dx, offset START_STR_PATH
        call PRINT_STRING
        mov dx, offset MODULE_STR
        call PRINT_LINE

        call FREE_MEMORY
        cmp MEMORY_ERROR, 0
            jne PDEFAULT

        mov PARAMS[0], 0 ;environment
        mov PARAMS[2], offset CMD
        mov PARAMS[4], ds
        mov dx, offset SLAVE_START_INFO
        call PRINT_LINE

        mov ax, ds
        mov es, ax
        mov dx, offset MODULE_STR
        mov bx, offset PARAMS
        mov SAVED_SS, ss
        mov SAVED_SP, sp

        mov ax, 4B00h
        int 21h

        mov cx, DATA
        mov ds, cx
        mov ss, SAVED_SS
        mov sp, SAVED_SP

        mov     dx, offset SLAVE_END_INFO
        call    PRINT_LINE
            jc NOFILE
        jmp SUCCESS

    NOFILE:
        mov dx, offset ERR_FILENAME_INFO
        call PRINT_STRING
        mov dx, offset MODULE_STR
        call PRINT_STRING
        jmp PDEFAULT

    SUCCESS:
        call FINISH

    PDEFAULT:
        mov ah, 4Ch
        int 21h
    MAIN ENDP
    PROGEND:

    CODE ENDS

end MAIN
