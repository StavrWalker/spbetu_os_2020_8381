CODE      	SEGMENT      

		ASSUME CS:CODE, DS:NOTHING, SS:NOTHING

MAIN		PROC	FAR           

		PUSH	AX
		PUSH	BX
		PUSH	DX
		PUSH	DI
		PUSH	DS

		MOV		DS, AX
		MOV		DI, OFFSET MESSAGE
		ADD		DI, 26H
		MOV		AX, CS
		CALL	WRD_TO_HEX
		MOV		DX, OFFSET MESSAGE
		PUSH	AX
       		MOV		AH, 09H
        	INT		21H
		POP 	AX 

		POP		DS
		POP		DI
		POP		DX
		POP		BX
		POP		AX
		RETF

MAIN		ENDP	


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
      	MOV		AH, AL
       	CALL	TETR_TO_HEX
        XCHG	AL, AH
        MOV		CL, 4H
        SHR		AL, CL
       	CALL	TETR_TO_HEX
        POP	CX
        RET

BYTE_TO_HEX	ENDP


WRD_TO_HEX	PROC	NEAR

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

MESSAGE		DB "OVERLEY #1 WAS CALLED, HIS ADDRESS:        ", 13, 10, "$"

CODE      	ENDS 

			END	MAIN
