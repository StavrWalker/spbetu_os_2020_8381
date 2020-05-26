.model small
.data

PSP 			dw 	?
SPSAVE 			dw 	?
SSSAVE			dw 	?

SUCCESS_INFO	db	13, 10, "Ending code: $"
NOFILE_INFO		db  "No file", 13, 10, "$"
CTRLC_INFO		db	"CRTL+C", 13, 10, "$"

PARAMETERS 		dw 	7 dup(?)
ERROR 			db 	0
FILE			db 	50 dup(0)
EOF				db 	"$"

.stack 128h

.code

HEX_BYTE_PRINT	PROC
		push 	AX
		push 	BX
		push 	DX
	
		mov 	AH, 0
		mov 	BL, 10h
		div 	BL
		mov 	DX, AX
		mov 	AH, 02h
		cmp 	DL, 0Ah
		jl 		PRINT
		add 	DL, 07h
	PRINT:
		add 	DL, '0'
		int 	21h;
		
		mov 	DL, DH
		cmp 	DL, 0Ah
		jl 		PRINT_EXT
		add 	DL, 07h
	PRINT_EXT:
		add 	DL, '0'
		int 	21h;
	
		pop 	DX
		pop 	BX
		pop 	AX
	ret
HEX_BYTE_PRINT	ENDP

WRITE 	PROC	near
		push 	AX
		mov 	AH, 09h
		int		21h
		pop 	AX
		ret
WRITE 	ENDP

FREEMEM 	PROC
		lea 	BX, MARK
		mov 	AX, ES
		sub 	BX, AX
		mov 	CL, 4
		shr 	BX, CL
		mov 	AH, 4Ah
		int 	21h
		jc 		CATCH
		jmp 	DEFAULT1
	CATCH:
		mov 	ERROR, 1
	DEFAULT1:
		ret
FREEMEM 	ENDP

PEXIT 	PROC
		mov 	AH, 4Dh
		int 	21h
		cmp 	AH, 1
		je 		CTRLC
		lea 	DX, SUCCESS_INFO
		call 	WRITE
		call	HEX_BYTE_PRINT
		mov 	DL, AH
		mov 	AH, 2h
		int 	21h
		jmp 	DEFAULT2
	CTRLC:
		lea 	DX, CTRLC_INFO
		call 	WRITE
	DEFAULT2:
	ret
PEXIT 	ENDP

Main proc
		mov 	AX, @data
		mov 	DS, AX
		push 	SI
		push 	DI
		push 	ES
		push 	DX
		mov 	ES, ES:[2Ch]
		xor 	SI, SI
		lea 	DI, FILE
	CHAR: 
		cmp 	byte ptr ES:[SI], 00h
		je 		CHAREND
		inc 	SI
		jmp 	NEXT1
	CHAREND:   
		inc 	SI
	NEXT1:       
		cmp 	word ptr ES:[SI], 0000h
		jne 	CHAR
		add 	SI, 4
	NCHAR:
		cmp 	byte ptr ES:[SI], 00h
		je 		START
		mov 	DL, ES:[SI]
		mov 	[DI], DL
		inc 	SI
		inc 	DI
		jmp 	NCHAR
	START:
		sub 	DI, 5
		mov 	DL, '2'
		mov 	[DI], DL
		add 	DI, 2
		mov 	DL, 'c'
		mov 	[DI], DL
		inc 	DI
		mov 	DL, 'o'
		mov 	[DI], DL
		inc 	DI
		mov 	DL, 'm'
		mov 	[DI], DL
		inc 	DI
		mov 	DL, 0h
		mov 	[DI], DL
		inc 	DI
		mov 	DL, EOF
		mov 	[DI], DL
		pop 	DX
		pop 	ES
		pop 	DI
		pop 	SI
		call 	FREEMEM
		cmp 	ERROR, 0
		jne 	PDEFAULT
		push 	DS
		pop 	ES
		lea 	DX, FILE
		lea 	BX, PARAMETERS
		mov 	SSSAVE, SS
		mov 	SPSAVE, SP
		mov 	AX, 4B00h
		int 	21h
		mov 	SS, SSSAVE
		mov 	SP, SPSAVE
		jc 		NOFILE
		jmp 	MENDING
	NOFILE:
		lea 	DX, NOFILE_INFO
		call 	WRITE
		lea 	DX, FILE
		call 	WRITE
		jmp 	PDEFAULT
	MENDING:
		call 	PEXIT
	PDEFAULT:
		mov 	AH, 4Ch
		int 	21h
main ENDP

MARK:

end main