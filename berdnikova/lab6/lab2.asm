LAB2		SEGMENT	

ASSUME 	CS:LAB2, DS:LAB2, ES:NOTHING, SS:NOTHING

ORG		100H

START:	JMP	BEGIN

ADRESSMEMORY		    DB "Address of memory:      $"
ADRESSENVIRONMENT		DB 13, 10, "Address of environment:      $"
TAILSTR					DB 13, 10, "Tail:                                         $"
ENVIRONMENTDATA			DB 13, 10, "Data of environment: ", 13, 10, "$"
PATHSTR					DB "Load module path: ", 13, 10, "$"
NEXTSTR					DB 13, 10, "$"


TETR_TO_HEX	PROC	NEAR

        	AND	AL, 0FH
        	CMP	AL, 09H
        	JBE	NEXT
      		ADD	AL, 07H

       		NEXT:      
       		ADD	AL, 30H
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


WORLD_TO_HEX	PROC	NEAR

          	PUSH	BX
          	MOV 	BH, AH
         	CALL	BYTE_TO_HEX
          	MOV	[DI], AH
          	DEC	DI
          	MOV	[DI], AL
         	DEC	DI
          	MOV	AL, BH
          	CALL	BYTE_TO_HEX
          	MOV	[DI], AH
          	DEC	DI
          	MOV	[DI], AL
          	POP	BX
          	RET

WORLD_TO_HEX	ENDP

BYTE_TO_DEC	PROC	NEAR

          	PUSH	CX
          	PUSH	DX
          	XOR	AH, AH
          	XOR 	DX, DX
          	MOV 	CX, 0AH

      		LOOP_BD:   
		DIV	CX
          	OR 	DL, 30H
          	MOV	[SI], DL
		DEC	SI
          	XOR	DX, DX
          	CMP	AX, 0AH
          	JAE	LOOP_BD
          	CMP	AL, 00H
          	JE	END_L
          	OR 	AL, 30H
          	MOV	[SI], AL
		   
       		END_L:     
		POP	DX
          	POP	CX
          	RET

BYTE_TO_DEC	ENDP

ADRESS_MEMORY PROC NEAR

		MOV	AX, DS:[02H]
		MOV	DI, OFFSET ADRESSMEMORY
		ADD	DI, 16H
		CALL	WORLD_TO_HEX
		MOV	DX, OFFSET ADRESSMEMORY
		
		PUSH	AX
       		MOV	AH, 09H
       		INT		21H
		POP 	AX 
        

		RET

ADRESS_MEMORY ENDP

ADRESS_ENVIRONMENT PROC NEAR

		MOV	AX, DS:[2CH]
		MOV	DI, OFFSET ADRESSENVIRONMENT
		ADD	DI, 1DH 
		CALL	WORLD_TO_HEX
		MOV	DX, OFFSET ADRESSENVIRONMENT
		
		PUSH	AX
       		MOV	AH, 09H
       		INT		21H
		POP 	AX 

		RET

ADRESS_ENVIRONMENT ENDP


TAIL_COMMANDSTRING PROC NEAR

		XOR CX, CX
		MOV	CL, DS:[80H]
		CMP	CL, 0
		JZ	EMPTY
		MOV	DI, OFFSET TAILSTR		
		ADD	DI, 8H
			
		CYCLE:
		MOV	AL, DS:[80H + SI]
		MOV	[DI], AL
		INC	DI
		INC	SI
		LOOP	CYCLE
		
		EMPTY:
		MOV	DX, OFFSET TAILSTR
		
		PUSH	AX
       		MOV	AH, 09H
       		INT		21H
		POP 	AX 
		
		RET

TAIL_COMMANDSTRING ENDP

ENVIRONMENT_AREA PROC NEAR

		MOV	DX, OFFSET ENVIRONMENTDATA
		
		PUSH	AX
       		MOV	AH, 09H
       		INT		21H
		POP 	AX 

		XOR DI, DI
		MOV 	BX, 2CH
		MOV 	DS, [BX]
	
		STARTofSTR:
		CMP 	BYTE PTR [DI], 00H
		JZ 		PRINTNEXTSTR
		MOV 	DL, [DI]
		MOV 	AH, 02H
		INT 	21H
		JMP 	ENVIRONMENTEND
	
       	PRINTNEXTSTR:
		PUSH 	DS
		MOV 	CX, CS
		MOV 	DS, CX
		MOV 	DX, OFFSET NEXTSTR
		
		PUSH	AX
       		MOV	AH, 09H
       		INT		21H
		POP 	AX 
		POP 	DS
	
       	ENVIRONMENTEND:
		INC 	DI
		CMP 	WORD PTR [DI], 0001H
		JZ 		RETURN
		JMP 	STARTofSTR
		RET
		
		RETURN:
		RET

ENVIRONMENT_AREA ENDP

PATH_MODULE PROC NEAR

		PUSH 	DS
		MOV 	AX, CS
       		MOV 	DS, AX
		MOV	DX, OFFSET PATHSTR
		
		PUSH	AX
       		MOV	AH, 09H
       		INT		21H
		POP 	AX 

		POP 	DS
		ADD 	DI, 2
		
       	CIRCLE:
		CMP 	BYTE PTR [DI], 00H
		JZ 		PATHFINISH
		MOV 	DL, [DI]
		MOV 	AH, 02H
		INT 	21H
		INC 	DI
		JMP 	CIRCLE

		PATHFINISH:
		RET

PATH_MODULE ENDP

		BEGIN:          	

		CALL ADRESS_MEMORY
		CALL ADRESS_ENVIRONMENT
		CALL TAIL_COMMANDSTRING
		CALL ENVIRONMENT_AREA
		CALL PATH_MODULE 

		MOV AH, 01H
		INT 21H
		
		MOV	AH, 4CH
		INT	21H
		      	
LAB2	ENDS
END 	START
