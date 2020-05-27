DATA									SEGMENT

MEM_CONTROL_BLOCK_DEST_STR 		DB "Memory control block destroyed - error 4ah", 13, 10, "$"
NOT_MEM_STR								DB "Not enough memory to execute function 4ah", 13, 10, "$"
INVALID_BLOCK_ADRESS_STR					DB "Invalid block address - error 4ah", 13, 10, "$"

ROUTE_NOT_FOUND_ERR_STR 				DB "Route not found - error of function 4eh", 13, 10, "$"
FILE_NOT_FOUND_ERR_STR 				DB "File not found - error of function 4eh", 13, 10, "$"

NON_EXIST_FUNCTION_ERR_STR			DB "Error of overley: not exist function", 13, 10, "$"
FILE_NOT_FOUND_ERR_OVERLEY_STR		DB "Error of overley: file not found", 13, 10, "$"
ROUTE_NOT_FOUND_ERR_OVERLEY_STR	DB "Error of overley: route not found", 13, 10, "$"
TOO_MANY_OPEN_FILES_ERR_STR			DB "Error of overley: too many open files", 13, 10, "$"
ACCESS_DENIED_ERR_STR					DB "Error of overley: access denied", 13, 10, "$"
LITTLE_MEMORY_ERR_STR					DB "Error of overley: little memory", 13, 10, "$"

OVERLEY1								DB "overley1.bin", 0H
OVERLEY2								DB "overley2.bin", 0H
PATH_OVERLEY   							DB 50H DUP(0H)
DTA 									DB 2BH DUP(0H)
SEGOVRL									DW ?
OVERLEY_CALL							DD 0H

DATA      								ENDS 

CODE      	SEGMENT      

		ASSUME CS:CODE, DS:DATA, SS:STACK_PROGRAM
	

FREE_MEMORY PROC NEAR


		MOV	AX, STACK_PROGRAM
		SUB	AX, DATA
		ADD	AX, 100H
		MOV	BX, AX
		MOV	AH, 4AH
		MOV	AL, 00H
		INT	21H
		
		RET

FREE_MEMORY ENDP

PRINT_ERROR_MEMORY PROC NEAR

		CMP	AX, 7H
		JNE		NOT_MEM

		MOV 	DX, OFFSET MEM_CONTROL_BLOCK_DEST_STR
		PUSH	AX
       		MOV	AH, 09H
        	INT		21H
		POP 	AX 
		JMP		RETURN
		
		NOT_MEM:
		CMP	AX, 8H
		JNE		INVALID_BLOCK

		MOV 	DX, OFFSET NOT_MEM_STR 
		PUSH	AX
       		MOV	AH, 09H
        	INT		21H
		POP 	AX 
		JMP		RETURN

		INVALID_BLOCK:
		MOV 	DX, OFFSET INVALID_BLOCK_ADRESS_STR
		PUSH	AX
       		MOV	AH, 09H
        	INT		21H
		POP 	AX 
		JMP RETURN

		RETURN:
		RET
		
PRINT_ERROR_MEMORY ENDP


CREATE_PATH_OVERLEY PROC	NEAR

		PUSH	AX
		PUSH	BX
		PUSH	CX
		PUSH	SI
		PUSH	DI
		PUSH	ES
		
		MOV		ES, ES:[2CH]
		MOV		BX, 0H
		MOV		CX, 2H
		
		CYCLE:
		INC		CX
		MOV		AL, ES:[BX]
		INC		BX
		CMP		AL, 0H
		JZ		CHECK
		JMP		CYCLE
		
		CHECK:
		CMP		BYTE PTR ES:[BX], 0H
		JNZ		CYCLE
		ADD		BX, 3H
		MOV		SI, OFFSET PATH_OVERLEY
		
       	WRITE_PATH:
		MOV		AL, ES:[BX]
		MOV		[SI], AL
		INC		SI
		INC		BX
		CMP		AL, 0H
		JZ		PATH_END
		JMP		WRITE_PATH
	
       	PATH_END:	
		SUB		SI, 9H
		MOV		DI, BP
		
       	CREATE_PATH:
		MOV		AH, [DI]
		MOV		[SI], AH
		CMP		AH, 0H
		JZ		END_CRAETE_PATH_OVERLEY
		INC		DI
		INC		SI
		JMP		CREATE_PATH
	
       	END_CRAETE_PATH_OVERLEY:
       	POP		ES
       	POP		DI
       	POP		SI
       	POP		CX
       	POP		BX
       	POP		AX
       	RET

CREATE_PATH_OVERLEY	ENDP


CREATE_MEMORY_FOR_OVERLEY	PROC	NEAR
		PUSH	AX
		PUSH	BX
		PUSH	CX
		PUSH	DX
       		PUSH	SI
       		PUSH	ES 
       
		MOV 	DX, OFFSET DTA 
		MOV 	AX, 1A00H
		INT 	21H
		
		MOV 	CX, 0H
		MOV 	DX, OFFSET PATH_OVERLEY
		MOV 	AX, 4E00H
       		INT		21H
		
		JNC		SIZE_OVERLAY
		
		CMP 	AX, 2H
		JNE		ROUTE_NOT_FOUND_ERR
		
		MOV 	DX, OFFSET FILE_NOT_FOUND_ERR_STR
		PUSH	AX
       		MOV		AH, 09H
        	INT		21H
		POP 	AX 
		JMP		END_PRINT_ERR

		
		ROUTE_NOT_FOUND_ERR:
		CMP 	AX, 3H
		JNE		END_PRINT_ERR
		
		MOV 	DX, OFFSET ROUTE_NOT_FOUND_ERR_STR
		PUSH	AX
       		MOV		AH, 09H
        	INT		21H
		POP 	AX 
		
		SIZE_OVERLAY:
		
		MOV		SI, OFFSET DTA
		ADD 	SI, 1CH
		MOV 	BX, [SI - 2H] 
		MOV		CL, 4H
		SHR 	BX, CL
		MOV 	AX, [SI]
		MOV		CL, 0CH
		SAL 	AX, CL 
		ADD		BX, AX 
		ADD		BX, 2H		
		
		MOV		AX, 4800H 
		INT		21H 
		MOV		SEGOVRL, AX
		
		END_PRINT_ERR:
		
       		POP		ES
       		POP		SI
       		POP		DX
       		POP		CX
       		POP		BX
		POP 	AX

		RET
		
CREATE_MEMORY_FOR_OVERLEY ENDP


LOAD_OVERLAY		PROC	NEAR

		PUSH	AX
		PUSH	BX
		PUSH	CX
		PUSH	DX
		PUSH	BP
		PUSH	ES

		MOV		BX, DS 
		MOV		ES, BX
		MOV		BX, OFFSET SEGOVRL 
		MOV		DX, OFFSET PATH_OVERLEY
		MOV 	AX, 4B03H	
		INT 	21H
	
		JNC 	NO_ERR

		CMP 	AX, 1H
		JNE 		FILE_NOT_FOUND_ERR_OVERLEY

		MOV 	DX, OFFSET NON_EXIST_FUNCTION_ERR_STR
		PUSH	AX
       		MOV	AH, 09H
        	INT		21H
		POP 	AX 
		JMP 	END_OVERLAY


		FILE_NOT_FOUND_ERR_OVERLEY:
		CMP 	AX, 2H
		JNE 	    ROUTE_NOT_FOUND_ERR_OVERLEY

		MOV 	DX, OFFSET FILE_NOT_FOUND_ERR_OVERLEY_STR
		PUSH	AX
       		MOV	AH, 09H
       		 INT		21H
		POP 	AX 
		JMP 	END_OVERLAY
		
       		ROUTE_NOT_FOUND_ERR_OVERLEY:
		CMP 	AX, 3H
		JNE 		TOO_MANY_OPEN_FILES_ERR

		MOV 	DX, OFFSET ROUTE_NOT_FOUND_ERR_OVERLEY_STR
		PUSH	AX
       		MOV	AH, 09H
        	INT		21H
		POP 	AX 
		JMP 	END_OVERLAY
       	
		TOO_MANY_OPEN_FILES_ERR:
		CMP 	AX, 4H
		JNE 		ACCESS_DENIED_ERR

		MOV 	DX, OFFSET TOO_MANY_OPEN_FILES_ERR_STR
		PUSH	AX
       		MOV	AH, 09H
        	INT		21H
		POP 	AX 
		JMP 	END_OVERLAY
		
       	ACCESS_DENIED_ERR:
		CMP 	AX, 5H
		JNE 		LITTLE_MEMORY_ERR

		MOV 	DX, OFFSET ACCESS_DENIED_ERR_STR
		PUSH	AX
       		MOV	AH, 09H
        	INT		21H
		POP 	AX 
		JMP 	END_OVERLAY
		
       	LITTLE_MEMORY_ERR:
		CMP 	AX, 8H
		JNE		END_OVERLAY

		MOV 	DX, OFFSET LITTLE_MEMORY_ERR_STR
		PUSH	AX
       		MOV	AH, 09H
        	INT		21H
		POP 	AX 
		JMP 	END_OVERLAY	

		NO_ERR:
		MOV		AX, SEGOVRL 
		MOV		WORD PTR OVERLEY_CALL + 2H, AX
		CALL	OVERLEY_CALL 
		MOV		ES, AX
		MOV		AX, 4900H
		INT		21H

		END_OVERLAY: 
		POP		ES
		POP		BP
		POP		DX
		POP		CX
		POP		BX
		POP		AX
		RET

LOAD_OVERLAY		ENDP

MAIN:           

		MOV 	AX, DATA		  
		MOV 	DS, AX

		CALL	FREE_MEMORY
		JNC 	LOAD_OVERLEYS
		CALL	PRINT_ERROR_MEMORY
		JMP		ENDPROG
		
		LOAD_OVERLEYS:
		
		MOV		BP, OFFSET OVERLEY1
		CALL	CREATE_PATH_OVERLEY
		CALL	CREATE_MEMORY_FOR_OVERLEY
       		CALL	LOAD_OVERLAY
       

		MOV		BP, OFFSET OVERLEY2
		CALL	CREATE_PATH_OVERLEY
		CALL	CREATE_MEMORY_FOR_OVERLEY
       		CALL	LOAD_OVERLAY
		

		ENDPROG:
		MOV 	AH, 4CH
		INT 	21H
	
CODE      	ENDS 

STACK_PROGRAM	SEGMENT	STACK           

DW 		100H DUP(?)

STACK_PROGRAM    	ENDS  

       	END	MAIN
