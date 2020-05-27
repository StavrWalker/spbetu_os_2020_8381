DATA SEGMENT
; ДАННЫЕ
OVL1_NAME           db "ovl1.ovl", 0
OVL2_NAME           db "ovl2.ovl", 0

SUCCESSFUL_FREE     db  "Memory was freed successfuly", 13, 10, "$"
UNSUCCESSFUL_FREE   db "Memory wasn't freed", 13, 10, "$"
FAIL_FREE_7         db "7: Memory block descriptor is destroyed", 13, 10,"$"
FAIL_FREE_8         db "8: Not enough memory for functiond", 13, 10,"$"
FAIL_FREE_9         db "9: Invalid adress", 13, 10,"$"

;ALLOC_SUCCESS db "Successful allocation", 13, 10, "$"
SIZE_ERROR          db "Size of ovl wasn't got", 13, 10, "$"
SIZE_ERROR2         db "File not found", 13, 10, "$"
SIZE_ERROR3         db "Path not found", 13, 10, "$"

; errors
LOAD_SUCCESS db "Successful load",13,10,"$"
LOAD_UNSUCCESS db "Unsuccessful load",13,10,"$"
WARN_LOAD_ERROR_1   db "1: Wrong function number", 13, 10, "$"
WARN_LOAD_ERROR_2   db "2: File not found", 13, 10, "$"
WARN_LOAD_ERROR_5   db "5: Disc error", 13, 10, "$"
WARN_LOAD_ERROR_8   db "8: Not enough memory", 13, 10, "$"
WARN_LOAD_ERROR_10  db "10: Wrong environment", 13, 10, "$"
WARN_LOAD_ERROR_11  db "11: Wrong format", 13, 10, "$"


KEEP_PSP            dw 0
MEM_ERR             db 0
OFFSET_OVL_NAME     dw 0
PATH                db 128 dup (0)
NAME_POS            dw 0
DTA_BUFF            db 43 dup(0)
OVL_PARAM_SEG     dw 0
OVL_ADRESS          dd 0

DATA_END            db 0
DATA ENDS

SSTACK SEGMENT STACK
    dw 12h dup(0)
SSTACK ENDS


CODE SEGMENT
; ПРОЦЕДУРЫ
ASSUME 	CS:CODE, DS:DATA, SS:SSTACK
PRINT  	PROC

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
    push    dx

    mov     bx, offset END_OF_PROG
    mov     ax, offset DATA_END
    add     bx, ax

    add     bx, 40fh
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
    pop    dx
    pop     cx
    pop     bx
    pop     ax
    ret
FREE_MEM ENDP


SET_ENV PROC
    push    ax
    push    di
    push    si
    push    es

    mov     OFFSET_OVL_NAME, ax
    mov     ax, KEEP_PSP
    mov     es, ax
    mov     es, es:[2ch]
    xor     si, si
FIND0:
    mov ax, es:[si]
    inc si
    cmp ax, 0
    jne FIND0
    add si, 3
    xor di, di
WRITE:
    mov al, es:[si]
    cmp al, 0
    je WRITE_NAME
    cmp al, '\'
    jne ADD_SYMB
    mov NAME_POS, di
ADD_SYMB:
    mov byte ptr [PATH + di], al
    inc si
    inc di
    jmp WRITE
WRITE_NAME:
    cld
    mov di, NAME_POS
    inc di
    add di, offset PATH
    mov si, OFFSET_OVL_NAME
    mov ax, ds
    mov es, ax
UPDATE:
    lodsb
    stosb
    cmp al, 0
    jne UPDATE

    pop es
    pop si
    pop di
    pop ax
    ret
SET_ENV endp

ALLOC_FOR_OVL proc
    push ax
    push bx
    push cx
    push dx
    push si


    mov ax, 1A00h
    mov dx, offset DTA_BUFF
    int 21h


    mov ah, 4eh
    xor cx, cx
    mov dx, offset PATH
    int 21h

    jnc SIZE_SUCCESS

    lea dx, SIZE_ERROR
    call PRINT
    cmp ax, 2
    je SIZE_ERR2
    cmp ax, 3
    je SIZE_ERR3
    jmp SIZE_END
SIZE_ERR2:
    lea dx, SIZE_ERROR2
    call PRINT
    jmp SIZE_END
SIZE_ERR3:
    lea dx, SIZE_ERROR3
    call PRINT
    jmp SIZE_END
SIZE_SUCCESS:
    mov     si, offset DTA_BUFF
    add     si, 1ah
    mov     bx,[si]
    mov     ax,[si+2]
    mov     cl, 4
    shr     bx, cl
    mov     cl, 12
    shl     ax, cl
    add     bx, ax
    add     bx, 2;
    mov     ax, 4800h
    int 21h

    jnc SIZE_SET
    lea dx, SIZE_ERROR
    call PRINT
    jmp SIZE_END
SIZE_SET:
    mov OVL_PARAM_SEG, ax

SIZE_END:
    pop     si
    pop     dx
    pop     cx
    pop     bx
    pop     ax
    ret

ALLOC_FOR_OVL ENDP

LOAD proc
    push    ax
    push    bx
    push    dx
    push    es

    mov  dx, offset PATH
    push ds
    pop es
    lea bx, OVL_PARAM_SEG
    mov     ax, 4B03h
    int 21h


    jnc     LOAD_SUCCESSFUL
    lea     dx, LOAD_UNSUCCESS
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
    call    PRINT
    jmp     LOAD_END
LOAD_ERROR_2:
    lea     dx, WARN_LOAD_ERROR_2
    call    PRINT
    jmp     LOAD_END
LOAD_ERROR_5:
    lea     dx, WARN_LOAD_ERROR_5
    call    PRINT
    jmp     LOAD_END
LOAD_ERROR_8:
    lea     dx, WARN_LOAD_ERROR_8
    call    PRINT
    jmp     LOAD_END
LOAD_ERROR_10:
    lea     dx, WARN_LOAD_ERROR_10
    call    PRINT
    jmp     LOAD_END
LOAD_ERROR_11:
    lea     dx, WARN_LOAD_ERROR_11
    call    PRINT
    jmp     LOAD_END
LOAD_SUCCESSFUL:
    mov ax, OVL_PARAM_SEG
    mov es, ax
    mov word ptr OVL_ADRESS+2, ax
    call OVL_ADRESS

    mov es, ax
    mov ah, 49h
    int 21h
LOAD_END:
    pop     es
    pop     dx
    pop     bx
    pop     ax
    ret
LOAD ENDP

RUN_OVL proc
    call SET_ENV
    call ALLOC_FOR_OVL
    call LOAD
    ret
RUN_OVL ENDP

MAIN proc
    mov     ax, DATA
    mov     ds, ax
    mov     KEEP_PSP, ES
    call    FREE_MEM
    cmp     MEM_ERR, 1
    je      ENDGAME
    mov     ax, offset OVL1_NAME
    call    RUN_OVL
    lea     ax, OVL2_NAME
    call    RUN_OVL

ENDGAME:
    xor     al,al
    mov     ah, 4Ch
    int     21h
END_OF_PROG:
MAIN ENDP 
 CODE ENDS
END  MAIN
