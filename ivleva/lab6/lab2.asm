CODE		SEGMENT	

ASSUME 	CS:CODE, DS:CODE, ES:NOTHING, SS:NOTHING

ORG		100H

START:	JMP	BEGIN

STR1		DB "Memory Address:      ", 13,10, "$"
STR2		DB "Env. Address:      ", 13,10, "$"
STR3		DB "Tail:                                         ", 13,10, "$"
STR4		DB "Env. Data: ", 13, 10, "$"
STR5		DB 13, 10, "$"
STR6		DB "Path: ", 13, 10, "$"


PRINT  	PROC	NEAR

       	PUSH	AX
       	MOV		AH, 09H
        INT		21H
		POP 	AX 
        RET

PRINT  	ENDP


TETR_TO_HEX	PROC	NEAR

        AND		AL, 0FH
        CMP		AL, 09H
        JBE		NEXT
      	ADD		AL, 07H

    NEXT:      
       	ADD		AL, 30H
       	RET

TETR_TO_HEX	ENDP


BYTE_TO_HEX	PROC	NEAR
          	
       	PUSH	CX
      	MOV	AH, AL
       	CALL	TETR_TO_HEX
        XCHG	AL, AH
        MOV	CL, 4H
        SHR	AL, CL
       	CALL	TETR_TO_HEX
        POP	CX
        RET

BYTE_TO_HEX	ENDP


WREAD_TO_HEX	PROC	NEAR

          	PUSH	BX
          	MOV 	BH, AH
         	CALL	BYTE_TO_HEX
          	MOV		[DI], AH
          	DEC		DI
          	MOV		[DI], AL
         	DEC		DI
          	MOV		AL, BH
          	CALL	BYTE_TO_HEX
          	MOV		[DI], AH
          	DEC		DI
          	MOV		[DI], AL
          	POP		BX
          	RET

WREAD_TO_HEX	ENDP


	BEGIN:          	

		MOV		AX, DS:[02H]
		MOV		DI, OFFSET STR1
		ADD		DI, 19
		CALL	WREAD_TO_HEX
		MOV		DX, OFFSET STR1
		CALL	PRINT

       	MOV		AX, DS:[2CH]
		MOV		DI, OFFSET STR2
		ADD		DI, 17
		CALL	WREAD_TO_HEX
		MOV		DX, OFFSET STR2
		CALL	PRINT

		XOR		CX, CX
       	XOR		SI, SI
		MOV		CL, DS:[80H]
		CMP		CL, 0
		JE		NO_TAIL
		MOV		DI, OFFSET STR3		
		ADD		DI, 6H
			
	READ:
		MOV		AL, DS:[81H + SI]
		MOV		[DI], AL
		INC		DI
		INC		SI
		LOOP	READ
		
	NO_TAIL:
		MOV	DX, OFFSET STR3
		CALL	PRINT

		MOV	DX, OFFSET STR4
		CALL	PRINT
		XOR	DI, DI
		MOV 	BX, 2CH
		MOV 	DS, [BX]
	
	BEGIN_STRING:
		CMP 	BYTE PTR [DI], 00H
		JE		ENTR
		MOV 	DL, [DI]
		MOV 	AH, 02H
		INT 	21H
		JMP 	END_DATA
	
   	ENTR:
		PUSH 	DS
		MOV 	CX, CS
		MOV 	DS, CX
		MOV 	DX, OFFSET STR5
		CALL 	PRINT
		POP 	DS
	
    END_DATA:
		INC 	DI
		CMP 	WORD PTR [DI], 0001H
		JE 		PATH
		JMP 	BEGIN_STRING
       
   	PATH:
		PUSH 	DS
		MOV 	AX, CS
       	MOV 	DS, AX
		MOV	DX, OFFSET STR6
		CALL 	PRINT
		POP 	DS
		ADD 	DI, 2
		
   	CIRCLE:
		CMP 	BYTE PTR [DI], 00H
		JE 		END_PATH
		MOV 	DL, [DI]
		MOV 	AH, 02H
		INT 	21H
		INC 	DI
		JMP 	CIRCLE

	END_PATH:
		PUSH 	DS
		MOV 	CX, CS
		MOV 	DS, CX
		MOV 	DX, OFFSET STR5
		CALL 	PRINT
		POP 	DS

		XOR		AL, AL

		mov 	AH, 01h
		int 	21h

		
		MOV		AH, 4CH
		INT		21H
      	 		
CODE		ENDS
END 		START


