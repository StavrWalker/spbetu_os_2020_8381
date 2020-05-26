CODE SEGMENT
	ASSUME CS:CODE, DS:NOTHING, SS:NOTHING
	MAIN PROC FAR
		push AX
		push DX
		push DS
		
		mov AX, CS
		mov DS, AX
		mov DX, offset STR_RESULT
		call WRITE
		call WRITE_HEX_WORD
		
		pop DS
		pop DX
		pop AX
		retf
	MAIN ENDP

	STR_RESULT db 13, 10, "Mod1 loaded! Adress: $"

	WRITE PROC
		push AX
		mov AH, 9h
		int 21h
		pop AX
		ret
	WRITE ENDP

	WRITE_HEX_BYTE PROC
		push AX
		push BX
		push DX
	
		mov AH, 0
		mov BL, 16
		div BL
		mov DX, AX
		mov AH, 02h
		cmp DL, 0Ah
		jl PRINT
		add DL, 7
	PRINT:
		add DL, '0'
		int 21h;
	
		mov DL, DH
		cmp DL, 0Ah
		jl PRINT2
		add DL, 7
	PRINT2:
		add DL, '0'
		int 21h;
	
		pop DX
		pop BX
		pop AX
		ret
WRITE_HEX_BYTE ENDP

WRITE_HEX_WORD PROC
		push AX
	
		push AX
		mov AL, AH
		call WRITE_HEX_BYTE
		pop AX
		call WRITE_HEX_BYTE
	
		pop AX
		ret
WRITE_HEX_WORD ENDP

CODE ENDS
END MAIN