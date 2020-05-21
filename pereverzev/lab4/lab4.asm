SSTACK SEGMENT STACK
		   DW 128
SSTACK  ENDS

DATA SEGMENT
	LOADED db 'Intrruption already loaded', 0DH, 0AH, '$' 
	NOTLOAD db 'Interruption was not loadd', 0DH, 0AH, '$'
	LOAD  db 0
	UN db 0
	
DATA ENDS

CODE SEGMENT

ASSUME CS:CODE, DS:DATA, SS:SSTACK


ROUT PROC FAR 
		jmp INTERRUPT
		COUNTER db  '000 - Quantity of CALL    '
		SIGN dw  1000h
		KEEP_IP dw  0
		KEEP_CS dw  0
		KEEP_PSP dw  0
		KEEP_SS dw  0
		KEEP_SP dw  0
		KEEP_AX dw  0
		INT_STACK dw 128 dup(0)
	
INTERRUPT:
    	mov KEEP_AX, AX
		mov KEEP_SP, SP
		mov KEEP_SS, SS
		mov AX, SEG INT_STACK
		mov SS, AX
		mov AX, offset INT_STACK
		add AX, 256
		mov SP, AX
		push AX
		push BX
		push CX
		push DX
		push SI
    	push ES
    	push DS
		mov AX, seg COUNTER
		mov DS, AX
		mov AH, 03h
		mov bh, 0h
		int 10h
		push DX
		mov AH, 02h
		mov DX, 1730h 
		mov bh, 0h 
		int 10h
		mov AX, seg COUNTER
		push DS
		mov DS, AX
		mov SI, offset COUNTER
		add SI, 2
		mov CX, 3

loopa:
		mov AH, [SI]
		inc AH
		mov [SI], AH
		cmp AH, ':'
		jnz END_loopa
		mov AH, '0'
		mov [SI], AH
		dec SI
		loop loopa
END_loopa:
		pop DS
		push ES
		push BP
		mov AX, seg COUNTER
		mov ES, AX
		mov BP, offset COUNTER
		mov AH, 13h
		mov AL, 01h
		mov bh, 00h
		mov BL, 02h 
		mov CX, 25
		int 10h 
		pop BP
		pop ES
		pop DX
		mov AH, 02h
		mov bh, 00h
		int 10h
		pop DS
		pop ES
		pop SI
		pop DX
		pop CX
		pop BX
		mov AX, KEEP_SS
		mov SS, AX 
		mov AX, KEEP_AX
		mov SP, KEEP_SP
		mov AL, 20h 
		out 20h, AL
		IRET
ROUT ENDP 
END_ROUT:

CHECK PROC
		push AX
		push BX
		push SI
		mov AH, 35h
		mov AL, 1ch
		int 21h
		mov SI, offset SIGN
		sub SI, offset ROUT
		mov AX, ES:[BX+SI]
		cmp AX, SIGN
		jnz check_end
		mov LOAD, 1
	
check_end:
		pop SI
		pop BX
		pop AX
		ret
CHECK ENDP

CHECK_UN PROC
		push AX
		push ES
		mov AX, KEEP_PSP
		mov ES, AX
		cmp byte ptr ES:[82H], '/'
		jnz CHECK_UN_END
		cmp byte ptr ES:[83H], 'u'
		jnz CHECK_UN_END
		cmp byte ptr ES:[84H], 'n'
		jnz CHECK_UN_END
		mov UN, 1

CHECK_UN_END:
		pop ES
		pop AX
		ret
CHECK_UN ENDP



LOAD_I PROC
		push AX
		push BX
		push CX
		push DX
		push ES
		push DS 
		mov AH, 35h 
		mov AL, 1ch
		int 21h 
		mov KEEP_IP, BX 
		mov KEEP_CS, ES 
		mov AX, seg ROUT
		mov DX, offset ROUT
		mov DS, AX
		mov AH, 25h 
		mov AL, 1ch 
		int 21h
		pop DS
		mov DX, offset END_ROUT
		mov cl, 4h 
		shr DX, cl
		add DX, 10fh
		inc DX
		xor AX, AX
		mov AH, 31h 
		int 21h 
		pop ES
		pop DX
		pop CX
		pop BX
		pop AX
		ret
LOAD_I ENDP


LOAD_UN PROC
		CLI
		push AX
		push BX
		push CX
		push DX
		push DS
		push ES
		push SI 
		mov AH, 35h 
		mov AL, 1ch 
		int 21h 
		mov SI, offset KEEP_IP 
		sub SI, offset ROUT
		mov DX, ES:[BX+SI]
		mov AX, ES:[BX+SI+2]
		push DS 
		mov DS, AX
		mov AH, 25h
		mov AL, 1ch 
		int 21h
		pop DS
		mov AX, ES:[BX+SI+4]
		mov ES, AX 
		push ES
		mov AX, ES:[2ch]
		mov ES, AX
		mov AH, 49h
		int 21h
		pop ES
		mov AH, 49h 
		int 21h
		STI
		pop SI
		pop ES
		pop DS
		pop DX
		pop CX
		pop BX
		pop AX
		ret
LOAD_UN ENDP

MAIN PROC FAR
		push DS
		xor AX,AX
		push AX
		mov AX, DATA
		mov DS, AX
		mov KEEP_PSP, ES
		cALl CHECK
		cALl CHECK_UN
		cmp UN, 1
		je UNLOAD
		cmp LOAD, 1
		jnz LOAD_
		mov DX, offset LOADED
		push AX
		mov AH, 09h
		int 21h 
		pop AX
		jmp MEND

LOAD_:	
		cALl LOAD_I
		jmp MEND

UNLOAD:
		cmp LOAD, 1
		jnz NOT_LOAD
		cALl LOAD_UN
		jmp MEND
	
NOT_LOAD:
		mov DX, offset NOTLOAD
		push AX
		mov AH, 09h
		int 21h 
		pop AX
	
MEND:
		xor AL, AL
		mov AH, 4ch
		int 21h
	
	
MAIN      ENDP
CODE ENDS
END MAIN