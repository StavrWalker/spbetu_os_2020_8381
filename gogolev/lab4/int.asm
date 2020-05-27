ASSUME CS:CODE, DS:DATA, SS:ASTACK

CODE SEGMENT

INTERRUPT PROC FAR
        jmp INT_START

    INT_DATA:
        SUB_STACK dw  128 dup(0)
        INTERRUPTIONS_INFO db  " interruptions     "
        INT_CODE dw  12345
        INTERRUPTIONS dw  0
        KEEP_IP  dw  0
        KEEP_CS  dw  0
        KEEP_PSP dw  0
        KEEP_SS dw  0
        KEEP_SP dw  0
        TEMP dw  0

    INT_START:
        mov     KEEP_SS, ss
        mov     KEEP_SP, sp
        mov     TEMP, seg INTERRUPT
        mov     ss, TEMP
        mov     sp, offset SUB_STACK
        add     sp, 256

        push	ax
        push    bx
        push    cx
        push    dx
        push    si
        push    es
        push    ds
        push    bp

    INT_SETUP:
		mov 	ax, seg INTERRUPT
		mov 	ds, ax
        mov     es, ax

    INT_SAVE_CURSOR:
        mov     ah, 03h
		mov     bh, 0h
		int     10h
        push    dx

	INT_ADD:
		mov 	si, offset INTERRUPTIONS
		mov 	ah, [si]
        mov     al, [si + 1]
		inc 	ax
		mov 	[si], ah
		mov 	[si + 1], al

	INT_PREP_TO_DEC:
        xor     dx, dx
        mov 	bx, 10
    	xor 	cx, cx

    INT_TO_DEC_CYCLE:
    	div 	bx
    	push	dx
    	xor 	dx, dx
    	inc 	cx
    	cmp 	ax, 0h
    	jnz 	INT_TO_DEC_CYCLE

        mov     ah, 2
        mov     bh, 0
        mov     dh, 23
        mov     dl, 0
        int     10h

    INT_PRINT_NUM:
    	pop 	ax
    	or 		al, 30h

        push    cx

        mov     ah, 09h
        mov 	bl, 3h
        mov     bh, 0
        mov     cx, 1
        int     10h

        mov     ah, 2
        mov     bh, 0
        add     dx, 1
        int     10h

        pop     cx

    	loop 	INT_PRINT_NUM

	INT_PRINT_STRING:
		mov     bp, offset INTERRUPTIONS_INFO
		mov     ah, 13h
		mov     al, 1h
		mov 	bl, 3h
		mov     bh, 0
		mov     cx, 19
		int     10h

    INT_LOAD_CURSOR:
        pop     dx
        mov     ah, 02h
		mov     bh, 0h
		int     10h

    INT_END:
        pop     bp
		pop     ds
		pop     es
		pop		si
		pop     dx
		pop     cx
		pop     bx
		pop		ax

        mov     ss, KEEP_SS
        mov     sp, KEEP_SP

		mov     al, 20h
		out     20h, al
        iret
INTERRUPT    ENDP
    LAST_BYTE:



LOAD        PROC
        push    ax
		push    bx
		push    cx
		push    dx
		push    es
		push    ds

        mov     ah, 35h
		mov     al, 1Ch
		int     21h
        mov     KEEP_IP, bx
		mov     KEEP_CS, es

        mov     dx, offset INTERRUPT
        mov     ax, seg INTERRUPT
		mov     ds, ax
		mov     ah, 25h
		mov     al, 1Ch
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
		mov     al, 1Ch
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
		mov     al, 1Ch
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
		mov     al, 1Ch
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
