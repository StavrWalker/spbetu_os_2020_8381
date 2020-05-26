LAB SEGMENT
	ASSUME CS:LAB, DS:LAB, ES:NOTHING, SS:NOTHING
	ORG 100H
MAIN: JMP BEGIN

;данные
UNAVAILABLE_MEMORY       db      "1.Unavailable memory segment address:     ", 13, 10, "$"
ENVIRONMENT              db      "2.Segment address of the environment:     ", 13, 10, "$"
LINE_TAIL                db      "3.Command line tail:                      ", 13, 10, "$"
NO_TAIL                  db      "3.No command line tail", 13, 10, "$"
ENVIRONMENT_CONTENT      db      "4.Program environment content:", 13, 10, "$"
PATH                     db      "5.Path:", 13, 10, "$"
CONTENT_EMPTY_LINE       db      13, 10, "$"


TETR_TO_HEX	PROC NEAR
		AND	AL, 0FH
		CMP AL, 09
		JBE	NEXT
		ADD	AL, 07
		NEXT: ADD AL, 30H
		RET
TETR_TO_HEX	ENDP

;--------------------------------------------------------------------------------

BYTE_TO_HEX	PROC NEAR
;байт в al переводится в два символа шест. числа в ax
		PUSH CX
		MOV	AH, AL
		CALL TETR_TO_HEX
		XCHG AL, AH
		MOV	CL, 4
		SHR	AL, CL
		CALL TETR_TO_HEX ;в al старшая цифра
		POP	CX 			 ;в ah младшая цифра
		RET
BYTE_TO_HEX	ENDP

;--------------------------------------------------------------------------------

WRD_TO_HEX	PROC NEAR
;перевод в 16 с/с 16 разрядного числа
;в ax - число, di - адрес последнего символа
		PUSH BX
		MOV	BH, AH
		CALL BYTE_TO_HEX
		MOV [DI], AH
		DEC	DI
		MOV [DI], AL
		DEC	DI
		MOV	AL, BH
		XOR	AH, AH
		CALL BYTE_TO_HEX
		MOV	[DI], AH
		DEC	DI
		MOV	[DI], AL
		POP	BX
		RET
WRD_TO_HEX	ENDP

;--------------------------------------------------------------------------------
BYTE_TO_DEC	PROC NEAR
;перевод в 10 с/с, si - адрес поля младшей цифры
		PUSH CX
		PUSH DX
		PUSH AX
		XOR	AH, AH
		XOR	DX, DX
		MOV	CX, 10
LOOP_BD: 
		DIV	CX
		OR DL, 30H
		MOV	[SI], DL
		DEC	SI
		XOR	DX, DX
		CMP	AX, 10
		JAE	LOOP_BD
		CMP	AX, 00H
		JBE	END_L
		OR AL, 30H
		MOV	[SI], AL
END_L:	
		POP	AX
		POP	DX
		POP	CX
		RET
BYTE_TO_DEC	ENDP
;--------------------------------------------------------------------------------

PRINT PROC NEAR
		PUSH AX
		MOV AH, 09H
		INT 21H
		POP AX
		RET
PRINT ENDP

;--------------------------------------------------------------------------------


BEGIN:

		PUSH DX
		PUSH AX	
		UNAVAILABLE_MEMORY_PRINT:
			
			MOV DI, OFFSET UNAVAILABLE_MEMORY + 41
			MOV AL, DS:[02H]
			MOV AH, DS:[03H]
			CALL WRD_TO_HEX
			MOV DX, OFFSET UNAVAILABLE_MEMORY
			CALL PRINT
			
			
		ENVIRONMENT_PRINT:
			
			MOV DI, OFFSET ENVIRONMENT +41
			MOV AL,DS:[2CH]
			MOV AH,DS:[2DH]
			CALL WRD_TO_HEX
			MOV DX, OFFSET ENVIRONMENT
			CALL PRINT
			
			
		LINE_TAIL_PRINT:
			
			MOV CL,DS:[80H]
			MOV DI, OFFSET LINE_TAIL +20
			TEST CL,CL
			JE NO_TAIL_PRINT
			MOV SI,81H
			TAIL:
				MOV AL, DS:[SI]
				MOV [DI], AL
				INC SI
				INC DI
				LOOP TAIL
			MOV DX, OFFSET LINE_TAIL
			CALL PRINT
			JMP ENVIRONMENT_CONTENT_PRINT
			
		NO_TAIL_PRINT:
			MOV DX, OFFSET NO_TAIL
			CALL PRINT
		
		ENVIRONMENT_CONTENT_PRINT:
			MOV DX, OFFSET ENVIRONMENT_CONTENT
			CALL PRINT
			XOR DI,DI
			XOR AX,AX
			MOV BX, 2CH
			MOV ES, [BX]
			MOV DX, OFFSET CONTENT_EMPTY_LINE
			
			LINE_PRINT:
				MOV AL, ES:[DI]
				CMP AL, 0
				JNE PRINT_SYMB
				MOV DX, OFFSET CONTENT_EMPTY_LINE
				CALL PRINT
				INC DI
				MOV AX, ES:[DI]
				CMP AX,0001H
				JE PATH_PRINT
				JMP LINE_PRINT
				
			PRINT_SYMB:
				MOV DL,AL
				XOR AL,AL
				MOV AH,02H
				INT 21H
				INC DI
				MOV AX, ES:[DI]
				CMP AX,0001H
				JE PATH_PRINT
				JMP LINE_PRINT
			
		PATH_PRINT:
			ADD DI,2
			MOV DX, OFFSET PATH
			CALL PRINT
		
		PATH_SYMB_PRINT:
			MOV AL, ES:[DI]
			TEST AL, AL
			JE EXIT
			MOV DL, AL
			MOV AH, 02H
			INT 21H
			INC DI
			JMP PATH_SYMB_PRINT
		
		EXIT:	
		
		mov DL, 0Ah
		mov ah,02h
		int 21h
		
		
		
		POP		AX
		POP 	DX
		XOR		AL, AL
		
		
		
		MOV 	AH, 01H; функция ввода символа с клавиатуры
		INT		21H
		
		MOV 	AH, 4CH
		INT		21H
		RET

LAB 	ENDS
		END  	MAIN
