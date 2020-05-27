ASTACK  SEGMENT STACK
    DW  128 dup(0)
ASTACK  ENds

DATA    SEGMENT
	loaded_str     DB  "Interruption has been already loaded.", 10, 13,"$"
	not_loaded_str		DB  "Interruption is not loaded.", 10, 13,"$"
    bool_isLoaded          DB  0
    UN_CL               DB  0
DATA    ENds

CODE    SEGMENT
	ASSUME  CS:CODE, ds:DATA, SS:ASTACK
	
ROUT    PROC    FAR
    jmp ROUT_BEGIN
    
	ROUT_DATA:
	signature DW  1234h
	
	KEEP_IP 	DW  0
	KEEP_CS 	DW  0
	KEEP_SS		DW  0
	KEEP_SP 	DW  0
	KEEP_AX     DW  0
	KEEP_PSP 	DW	0
	ROUT_STACK 	DW 	100 dup (?)
	temporary db 0

	
    ROUT_BEGIN:
		mov 	KEEP_SS, SS 
        mov 	KEEP_SP, SP 
        mov 	KEEP_AX, AX 
		mov 	AX, seg ROUT_STACK 
		mov 	SS, AX 
		mov 	SP, 0 
		mov 	AX, KEEP_AX
		
		push	AX
		push    BX
		push    CX
		push    DX
		push    SI
		push 	DI
        push    ES
        push    DS
		
		mov 	AX, SEG temporary
		mov 	DS, AX
		in 		AL, 60h
		cmp 	AL, 02h
		je 		PRINT_L
		cmp 	AL, 03h
		je 		PRINT_A
		cmp 	AL, 04h
		je 		PRINT_B
		cmp 	AL, 05h
		je 		PRINT_5
		cmp 	AL, 06h
		je 		PRINT_POINT
		cmp 	AL, 07h
		je 		PRINT_E
		cmp 	AL, 08h
		je 		PRINT_X
		cmp 	AL, 09h
		je 		PRINT_E
		pushf
		call 	DWORD PTR CS:KEEP_IP
		jmp 	ROUT_ENDING
	PRINT_L:
		mov		temporary, 'L'
		jmp		ROUT_PROCCESS
	PRINT_A:
		mov		temporary, 'A'
		jmp		ROUT_PROCCESS
	PRINT_B:
		mov		temporary, 'B'
		jmp		ROUT_PROCCESS
	PRINT_5:
		mov		temporary, '5'
		jmp		ROUT_PROCCESS
	PRINT_POINT:
		mov		temporary, '.'
		jmp		ROUT_PROCCESS
	PRINT_E:
		mov		temporary, 'E'
		jmp		ROUT_PROCCESS
	PRINT_X:
		mov		temporary, 'X'
		
	ROUT_PROCCESS:
		in AL, 61h
		mov AH, AL
		or AL, 80h
		out 61h, AL
		xchg AL, AL
		out 61h, AL
		mov AL, 20h
		out 20h, AL
	
	PRINTING_SYMBOL:
		mov AH, 05h
		mov CL, temporary
		mov CH, 00h
		int 16h
		or AL, AL
		jz ROUT_ENDING
		mov AX, 0000h
		mov ES, AX
		mov AX, ES:[41Ah]
		mov ES:[41Ch], AL
		jmp PRINTING_SYMBOL
	ROUT_ENDING:
		pop     DS
		pop     ES
		pop		DI
		pop		SI
		pop     DX
		pop     CX
		pop     BX
		pop		AX
		mov 	AX, KEEP_SS
		mov 	SS, AX
		mov		AX, KEEP_AX
		mov 	SP, KEEP_SP
		mov 	AL, 20h
		out 	20h, AL
		IRET
	ret
ROUT    ENDP
	LAST_BYTE:

ROUT_CHECK       PROC
	push    ax
	push    bx
	push    si
	mov     AH, 35h
	mov     AL, 09h
	int     21h
	mov     si, offset signature
	sub     si, offset ROUT
	mov     ax, es:[bx + si]
	cmp	    ax, signature
	jne     ROUT_CHECK_END
	mov     bool_isLoaded, 1
	ROUT_CHECK_END:
	pop     si
	pop     bx
	pop     ax
	ret
ROUT_CHECK       ENDP

ROUT_LOAD        PROC
        push    AX
		push    BX
		push    CX
		push    DX
		push    ES
		push    DS

        mov     AH, 35h
		mov     AL, 09h
		int     21h
		mov     KEEP_CS, ES
        mov     KEEP_IP, BX
        mov     AX, seg ROUT
		mov     DX, offset ROUT	
		mov     DS, AX
		mov     AH, 25h
		mov     AL, 09h
		int     21h
		pop		DS

        mov     DX, offset LAST_BYTE
		mov     CL, 4h
		shr     DX, CL
		add		DX, 10Fh
		inc     DX
		xor     AX, AX
		mov     AH, 31h
		int     21h

        pop     ES
		pop     DX
		pop     CX
		pop     BX
		pop     AX
	ret
ROUT_LOAD endp

ROUT_UNLOAD      PROC
        CLI
		push    AX
		push    BX
		push    DX
		push    DS
		push    ES
		push    SI
		
		mov     AH, 35h
		mov     AL, 09h
		int     21h
		mov 	SI, offset KEEP_IP
		sub 	SI, offset ROUT
		mov 	DX, ES:[BX + SI]
		mov 	AX, ES:[BX + SI + 2]
		
		push 	DS
		mov     DS, AX
		mov     AH, 25h
		mov     AL, 09h
		int     21h
		pop 	DS
		
		mov 	AX, ES:[BX + SI + 10]
		mov 	ES, AX
		push 	ES
		mov 	AX, ES:[2Ch]
		mov 	ES, AX
		mov 	AH, 49h
		int 	21h
		pop 	ES
		mov 	AH, 49h
		int 	21h
		
		STI
		pop     SI
		pop     ES
		pop     DS
		pop     DX
		pop     BX
		pop     AX
		
	ret
ROUT_UNLOAD      ENDP

COMMAND_LINE_PARAM_CHECK        PROC
        push    ax
		push    es
		mov     ax, KEEP_PSP
		mov     es, ax
		cmp     byte ptr es:[82h], '/'
		jne     COMMAND_LINE_PARAM_CHECK_END
		cmp     byte ptr es:[83h], 'u'
		jne     COMMAND_LINE_PARAM_CHECK_END
		cmp     byte ptr es:[84h], 'n'
		jne     COMMAND_LINE_PARAM_CHECK_END
		mov     UN_CL, 1
	COMMAND_LINE_PARAM_CHECK_END:
		pop     es
		pop     ax
		ret
COMMAND_LINE_PARAM_CHECK        ENDP

	
print proc near
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
print endp

MAIN PROC
		push    ds
		xor     ax, ax
		push    ax
		mov     ax, DATA
		mov     ds, ax
		mov     KEEP_PSP, es
		call    ROUT_CHECK
		call    COMMAND_LINE_PARAM_CHECK
		cmp     UN_CL, 1
		je      UNLOAD
		mov     AL, bool_isLoaded
		cmp     AL, 1
		jne     LOAD
		mov     dx, offset loaded_str
		call    print
		jmp     MAIN_END
	LOAD:
		call    ROUT_LOAD
		jmp     MAIN_END
	UNLOAD:
		cmp     bool_isLoaded, 1
		jne     CANT_UNLOAD
		call    ROUT_UNLOAD
		jmp     MAIN_END
	CANT_UNLOAD:
		mov     dx, offset not_loaded_str
		call    print
	MAIN_END:
		xor 	AL, AL
		mov 	AH, 4Ch
		int 	21h
	MAIN ENDP

CODE    ENds


END 	MAIN