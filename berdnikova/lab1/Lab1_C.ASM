CODE		SEGMENT	

ASSUME 	CS:CODE, DS:CODE, ES:NOTHING, SS:NOTHING

ORG		100H

START:	JMP	BEGIN
			
STR		DB "Type PC: $"
STRTYPE1	DB "PC", 13,10, "$"
STRTYPE2	DB "PC/XT", 13,10, "$"
STRTYPE3	DB "AT", 13,10, "$"
STRTYPE4	DB "PS2 model 30", 13,10, "$"
STRTYPE5	DB "PS2 model 80", 13,10, "$"
STRTYPE6	DB "PCjr", 13,10, "$"
STRTYPE7	DB "PC Convertible", 13,10, "$"
ERR			DB "Error! Type not found! Your type:    ", 13,10, "$" 
VERS 		DB "OS version: 0 .0   ", 13,10, "$"
OEM 		DB "OEM:    ", 13,10, "$"
NUM 		DB "Serial number:       $"


PRINT  	PROC	NEAR

       	PUSH	AX
       	MOV	AH, 09H
        INT	21H
		POP 	AX 
        RET

PRINT  	ENDP


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
	; байт в AL переводится в два символа шестн. числа в AX
          	
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


WRD_TO_HEX	PROC	NEAR
		; перевод в 16 с/с 16-ти разрядного числа 
		; в AX - число, DI - адрес последнего символа

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

WRD_TO_HEX	ENDP


BYTE_TO_DEC	PROC	NEAR
		; перевод в 10 с/с, SI - адрес поля младшей цифры
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

	BEGIN:          	

        MOV	AX, 0F000H
		MOV	ES, AX
		MOV	AL, ES:[0FFFEH]
		
		MOV	DX, OFFSET STR
		CALL	PRINT

		
		CMP 	AL, 0FFH
		JE 	TYPE1
		CMP 	AL, 0FEH
		JE 	TYPE2
		CMP 	AL, 0FBH
		JE 	TYPE2
		CMP	AL, 0FCH
		JE 	TYPE3
		CMP 	AL, 0FAH
		JE 	TYPE4
		CMP 	AL, 0F8H
		JE 	TYPE5
		CMP 	AL, 0FDH
		JE 	TYPE6
		CMP 	AL, 0F9H
		JE 	TYPE7


		JMP	ELS

	
		
    TYPE1:
		MOV 	DX, OFFSET STRTYPE1
		JMP 	RES
	
    TYPE2:
		MOV 	DX, OFFSET STRTYPE2
		JMP 	RES
	
	TYPE3:
		MOV 	DX, OFFSET STRTYPE3
		JMP 	RES
	
    TYPE4:
		MOV 	DX, OFFSET STRTYPE4
		JMP 	RES
	
    TYPE5:
		MOV 	DX, OFFSET STRTYPE5
		JMP 	RES
	
    TYPE6:
		MOV 	DX, OFFSET STRTYPE6
		JMP 	RES
	
    TYPE7:
		MOV 	DX, OFFSET STRTYPE7
		JMP 	RES

	ELS:
		MOV	DI, OFFSET ERR
		ADD	DI, 22H
		CALL	BYTE_TO_HEX
		MOV	[DI], AX
		MOV	DX, OFFSET ERR
		JMP 	RES 


	RES:
		CALL PRINT

		MOV	AH, 30H
		INT	21H
		PUSH	AX
	
       	MOV	SI, OFFSET VERS
		ADD	SI, 0DH
		CALL	BYTE_TO_DEC

		ADD	SI, 4H 
		POP	AX
		MOV	AL, AH
		CALL	BYTE_TO_DEC
		MOV	DX, OFFSET VERS
		CALL	PRINT
	
		MOV 	SI, OFFSET OEM
		ADD 	SI, 6H
		MOV	AL, BH
		CALL 	BYTE_TO_DEC
		MOV	DX, OFFSET OEM
		CALL	PRINT
	
		MOV	DI, OFFSET NUM
		ADD	DI, 14H
		MOV	AX, CX
		CALL	WRD_TO_HEX
		MOV	AL, BL
		CALL	BYTE_TO_HEX
		SUB	DI, 2H
		MOV	[DI], AX
		MOV	DX, OFFSET NUM
		CALL 	PRINT

		XOR	AL, AL
		MOV	AH, 4CH
		INT	21H
       	
CODE		ENDS
END 		START
