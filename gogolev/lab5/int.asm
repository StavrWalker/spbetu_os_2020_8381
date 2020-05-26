ASSUME CS:CODE, DS:DATA, SS:ASTACK

CODE SEGMENT

INTERRUPT PROC FAR
        jmp INT_START

    INT_DATA:
        SUB_STACK dw  128 dup(0)
        INT_CODE dw  12345
        KEEP_IP  dw  0
        KEEP_CS  dw  0
        KEEP_PSP dw  0
        KEEP_SS dw  0
        KEEP_SP dw  0
        SYMB db  0
        TEMP dw  0

    INT_START:
        mov KEEP_SS, ss
        mov KEEP_SP, sp
        mov TEMP, seg INTERRUPT
        mov ss, TEMP
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
        cmp al, 1Eh ; A
        je INT_REPLACE_X
        cmp al, 30h ; B
        je INT_REPLACE_Y
        cmp al, 2Eh ; C
        je INT_REPLACE_Z

        pushf
        call DWORD PTR KEEP_IP
        jmp INT_END

    INT_REPLACE_X:
        mov SYMB, 'X'
        jmp INT_PASS
    INT_REPLACE_Y:
        mov SYMB, 'Y'
        jmp INT_PASS
    INT_REPLACE_Z:
        mov SYMB, 'Z'
        jmp INT_PASS

    INT_PASS:
        in al, 61h
        mov ah, al
        or al, 80h
        out 61h, al
        xchg al, al
        out 61h, al
        mov al, 20h
        out 20h, al

    INT_PRINT:
        mov ah, 05h
        mov cl, SYMB
        mov ch, 00h
        int 16h
        or al, al
        jz INT_END

        mov ax, 0040h
        mov es, ax
        mov ax, es:[1Ah]
        mov es:[1Ch], ax
        jmp INT_PRINT

    INT_END:
        pop ds
        pop es
        pop si
        pop dx
        pop cx
        pop bx
        pop ax

        mov ss, KEEP_SS
        mov sp, KEEP_SP

        mov al, 20h
        out 20h, al
        IRET
INTERRUPT ENDP
    LAST_BYTE:



LOAD        PROC
        push    ax
		push    bx
		push    cx
		push    dx
		push    es
		push    ds

        mov     ah, 35h
		mov     al, 09h
		int     21h
        mov     KEEP_IP, bx
		mov     KEEP_CS, es

        mov     dx, offset INTERRUPT
        mov     ax, seg INTERRUPT
		mov     ds, ax
		mov     ah, 25h
		mov     al, 09h
		int     21h
		pop		ds

        mov     dx, offset LAST_BYTE
        add     dx, 100h
		mov     cl, 4h
		shr     dx, cl
		inc     dx
		mov     ah, 31h
		int     21h

        pop     es
		pop     dx
		pop     cx
		pop     bx
		pop     ax

	    ret
LOAD        ENDP



UNLOAD      PROC
		push    ax
		push    bx
		push    dx
		push    ds
		push    es
		push    si

		mov     ah, 35h
		mov     al, 09h
		int     21h

		mov 	si, offset KEEP_IP
        sub     si, offset INTERRUPT
		mov 	dx, es:[bx + si]
        mov 	si, offset KEEP_CS
        sub     si, offset INTERRUPT
		mov 	ax, es:[bx + si]

		push 	ds
		mov     ds, ax
		mov     ah, 25h
		mov     al, 09h
		int     21h
		pop 	ds

        mov 	si, offset KEEP_PSP
        sub     si, offset INTERRUPT
        mov 	ax, es:[bx + si]
        mov     es, ax
        push    es
        mov 	ax, es:[2Ch]
		mov 	es, ax
		mov 	ah, 49h
		int 	21h

        pop     es
        mov 	ah, 49h
		int 	21h

        pop     si
		pop     es
		pop     ds
		pop     dx
		pop     bx
		pop     ax

		sti
	    ret
UNLOAD      ENDP



INT_CHECK       PROC
		push    ax
		push    bx
		push    si

		mov     ah, 35h
		mov     al, 09h
		int     21h

		mov     si, offset INT_CODE
        sub     si, offset INTERRUPT
		mov     ax, es:[bx + si]
		cmp	    ax, INT_CODE
		jne     INT_CHECK_END

        mov     cl, CHECK_FLAG
		add     cl, 1
		mov     CHECK_FLAG, cl

	INT_CHECK_END:
		pop     si
		pop     bx
		pop     ax

	    ret
INT_CHECK       ENDP



TAIL_CHECK        PROC

		push    ax
		cmp     byte ptr es:[82h], '/'
		jne     CL_CHECK_END
		cmp     byte ptr es:[83h], 'u'
		jne     CL_CHECK_END
		cmp     byte ptr es:[84h], 'n'
		jne     CL_CHECK_END
		mov     al, CHECK_FLAG
		add     al, 2
		mov     CHECK_FLAG, al

	CL_CHECK_END:
		pop     ax
		ret
TAIL_CHECK        ENDP


FLAGS_CHECK    PROC    NEAR
	    mov    CHECK_FLAG, 0
        call   TAIL_CHECK
	    call   INT_CHECK
        ret
FLAGS_CHECK    ENDP

PRINT_STRING    PROC    NEAR
        push    ax
        mov     ah, 09h
        int     21h

        mov     dx, offset ENDL
        mov     ah, 09h
        int     21h

        pop     ax

        ret
PRINT_STRING    ENDP



MAIN PROC
		push    ds
		xor     ax, ax
		push    ax
		mov     ax, DATA
		mov     ds, ax
        mov     KEEP_PSP, es

        call    FLAGS_CHECK

		cmp CHECK_FLAG, 0 ; 00
		je INT_LOAD
		cmp CHECK_FLAG, 1 ; 01
		je INT_LOAD_AGAIN
		cmp CHECK_FLAG, 2 ; 10
		je INT_UNLOAD_AGAIN
		jmp INT_UNLOAD ; 11

	INT_LOAD:
        mov     dx, offset SUCCESS_LOAD_STRING
        call    PRINT_STRING
		call    LOAD
		jmp     MAIN_END

	INT_LOAD_AGAIN:
		mov     dx, offset ERROR_LOAD_STRING
        call    PRINT_STRING
		jmp     MAIN_END

	INT_UNLOAD_AGAIN:
		mov     dx, offset ERROR_UNLOAD_STRING
		call    PRINT_STRING
		jmp     MAIN_END

	INT_UNLOAD:
		call    UNLOAD
        mov     dx, offset SUCCESS_UNLOAD_STRING
		call    PRINT_STRING
		jmp     MAIN_END

	MAIN_END:
		xor 	al, al
		mov 	ah, 4Ch
		int 	21h
	MAIN ENDP

CODE    ENDS

ASTACK  SEGMENT STACK
    dw  128 dup(0)
ASTACK  ENDS

DATA SEGMENT
    SUCCESS_LOAD_STRING db "SUCCESS. Interruption loaded", '$'
    ERROR_LOAD_STRING db "ERROR. Already loaded", '$'
    SUCCESS_UNLOAD_STRING db "SUCCESS. Interruption unloaded", '$'
    ERROR_UNLOAD_STRING db "ERROR. Interruption isn't loaded", '$'
    ENDL db 10, 13, '$'
    CHECK_FLAG db  0; bit 1 - /un,  bit 0 - is loaded
DATA ENDS

END 	MAIN
