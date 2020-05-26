DATA SEGMENT
; ДАННЫЕ

PATH                db 128 dup (0)
FILE_NAME           db "LB2.COM", 0
SUCCESSFUL_FREE     db  "Memory was freed successfuly", 13, 10, "$"
UNSUCCESSFUL_FREE   db "Memory wasn't freed", 13, 10, "$"
SUCCESS_LOAD        db "Program was loaded", 13, 10, "$"
FAIL_LOAD           db "Program wasn't loaded", 13, 10, "$"
STR_BUTTON          db  13, 10, "Button:  ", 13, 10, "$"

PROGRAM_END         db "The program ended with ", 13, 10, "$"
NORMAL_END          db  "Normal end", 13, 10, "$"
CTRLC_END           db  "ctrl-c end", 13, 10, "$"
ERR_END             db  "error end", 13, 10, "$"
RES_END             db  "int 31h end", 13, 10, "$"
; errors
WARN_LOAD_ERROR_1   db "1: Wrong function number", 13, 10, "$"
WARN_LOAD_ERROR_2   db "2: File not found", 13, 10, "$"
WARN_LOAD_ERROR_5   db "5: Disc error", 13, 10, "$"
WARN_LOAD_ERROR_8   db "8: Not enough memory", 13, 10, "$"
WARN_LOAD_ERROR_10  db "10: Wrong environment", 13, 10, "$"
WARN_LOAD_ERROR_11  db "11: Wrong format", 13, 10, "$"
FAIL_FREE_7         db "7: Memory block descriptor is destroyed", 13, 10,"$"
FAIL_FREE_8         db "8: Not enough memory for functiond", 13, 10,"$"
FAIL_FREE_9         db "9: Invalid adress", 13, 10,"$"


MEM_ERR             db 0
KEEP_PSP            dw 0
KEEP_SS             dw 0
KEEP_SP             dw 0
COM_LINE 	        db 1h, 0Dh

PARAMETR_BLOCK	dw 0	;сегментный адрес среды
                dd 0	;сегмент и смещение командной строки
                dd 0	;сегмент и смещение первого FCB
                dd 0	;сегмент и смещение второго FCB

DATA_END        db 0

DATA ENDS

SSTACK SEGMENT STACK
    dw 100 dup(0)
SSTACK ENDS


CODE SEGMENT
; ПРОЦЕДУРЫ
ASSUME 	CS:CODE, DS:DATA, SS:SSTACK
PRINT  	PROC	near

   	PUSH	AX
   	MOV	    AH, 09H
    INT	    21H
	POP 	AX
    RET

PRINT  	ENDP

FREE_MEM PROC near
    push    ax
    push    bx
    push    cx
    push    es

    lea     bx, END_OF_PROG
    lea     ax, DATA_END
    add     bx, ax
    add     bx, 30fh
    mov     cl, 4
    shr     bx, cl
    mov     ax, 4a00h
    int     21h

    jc 		MEM_UNSUCCES
    jmp 	MEM_SUCCES
MEM_UNSUCCES:
    mov 	MEM_ERR, 1
    lea     dx, UNSUCCESSFUL_FREE;
    call    PRINT
    cmp     AX, 7
    je      FREE_ERROR_7
    cmp     AX, 8
    je      FREE_ERROR_8
    cmp     AX, 9
    je      FREE_ERROR_9
FREE_ERROR_7:
    lea     dx, FAIL_FREE_7
    call    PRINT
    jmp     MEMEND
FREE_ERROR_8:
    lea     dx, FAIL_FREE_8
    call    PRINT
    jmp     MEMEND
FREE_ERROR_9:
    lea     dx, FAIL_FREE_8
    call    PRINT
    jmp     MEMEND
MEM_SUCCES:
    lea     dx, SUCCESSFUL_FREE;
    call    PRINT
MEMEND:
    pop     es
    pop     cx
    pop     bx
    pop     ax
    ret
FREE_MEM ENDP


SET_ENV PROC near
    push    AX
    push    DI
    push    BX
    push    dx
    push    ES
    push    si

    ; seg adress path
    mov     ax, KEEP_PSP
    mov     es, ax
    mov     es, es:[2ch]
    xor     bx, bx
ENV_VAR:
    cmp     BYTE PTR es:[bx], 0
    je      ENV_END
    inc     bx
    jmp     ENV_VAR
ENV_END:
    inc     bx
    cmp     BYTE PTR es:[bx+1], 0
    jne     ENV_VAR

    add     bx, 2
    xor     di,di
MARK:
    mov     dl, es:[bx]
    mov     BYTE PTR [PATH+di], dl
    inc     bx
    inc     di
    cmp     dl, 0
    je      LOOP_END
    cmp     dl, '\'
    jne     MARK
    mov     cx, di
    jmp     MARK
LOOP_END:
    mov     di, cx
    mov     si, 0
FILE_NAME_LOOP:
    mov     dl, BYTE PTR [FILE_NAME + si]
    mov     byte ptr [PATH + di], dl
    inc     si
    inc     di
    cmp     dl, 0
    jne     FILE_NAME_LOOP

    pop     si
    pop     ES
    pop     dx
    pop     BX
    pop     DI
    pop     AX
    ret
SET_ENV ENDP



LOAD proc near
    push    ax
    push    bx
    push    dx
    push    di
    push    ds
    push    es

    mov     KEEP_SP, SP
    mov     KEEP_SS, SS

    mov     ax, DATA
    mov     es, ax

    lea     bx, PARAMETR_BLOCK
    lea     dx, COM_LINE
    mov     [bx + 2], dx
    mov     [bx + 4], ds
    lea      dx, PATH
    mov     ax, 4B00h
    int     21h

    mov     SS, KEEP_SS
    mov     SP, KEEP_SP
    pop     es
    pop     ds

    jnc     LOAD_SUCCESSFUL
    lea     dx, SUCCESS_LOAD
    call    PRINT
    cmp     ax, 1
    je      LOAD_ERROR_1
    cmp     ax, 2
    je      LOAD_ERROR_2
    cmp     ax, 5
    je      LOAD_ERROR_5
    cmp     ax, 8
    je      LOAD_ERROR_8
    cmp     ax, 10
    je      LOAD_ERROR_10
    cmp     ax, 11
    je      LOAD_ERROR_11

LOAD_ERROR_1:
    lea     dx, WARN_LOAD_ERROR_1
    jmp     LOAD_END
LOAD_ERROR_2:
    lea     dx, WARN_LOAD_ERROR_2
    jmp     LOAD_END
LOAD_ERROR_5:
    lea     dx, WARN_LOAD_ERROR_5
    jmp     LOAD_END
LOAD_ERROR_8:
    lea     dx, WARN_LOAD_ERROR_8
    jmp     LOAD_END
LOAD_ERROR_10:
    lea     dx, WARN_LOAD_ERROR_10
    jmp     LOAD_END
LOAD_ERROR_11:
    lea     dx, WARN_LOAD_ERROR_11
    jmp     LOAD_END
LOAD_SUCCESSFUL:
    mov     ah, 4Dh
    mov     al, 00h
    int     21h
    lea     di, STR_BUTTON
    mov     [di+10], al
    lea     dx, STR_BUTTON
    call    PRINT
    lea     dx, PROGRAM_END
    call    PRINT

    cmp     ah, 0
    je      NORMAL
    cmp     ah, 1
    je      CTRLC
    cmp     ah, 2
    je      ERR
    cmp     ah, 3
    je      RES

NORMAL:
    lea     dx, NORMAL_END
    jmp     LOAD_END
CTRLC:
    lea     dx, CTRLC_END
    jmp     LOAD_END
ERR:
    lea     dx, ERR_END
    jmp     LOAD_END
RES:
    lea     dx, RES_END
    jmp     LOAD_END

LOAD_END:
    call    PRINT
    pop     di
    pop     dx
    pop     bx
    pop     ax
    ret
LOAD ENDP


MAIN PROC
    mov     ax, DATA
    mov     ds, ax
    mov     KEEP_PSP, ES
    call    FREE_MEM
    cmp     MEM_ERR, 1
    je      ENDGAME
    call    SET_ENV
    call    LOAD

ENDGAME:
    xor     al,al
    mov     ah, 4Ch
    int     21h
END_OF_PROG:
MAIN ENDP


CODE ENDS
END 		MAIN
