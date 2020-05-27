CODE      	SEGMENT      

		ASSUME CS:CODE, DS:DATA, SS:STACK_PROGRAM
		
SS_SAVE								DW ?
SP_SAVE								DW ?



FREE_MEMORY PROC NEAR

		MOV	AX, STACK_PROGRAM
		SUB	AX, CODE
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


CREATE_COMMAND_PATH PROC NEAR

		MOV 	ES, ES:[2CH]
		MOV 	SI, 0H

       	CYCLE:
		MOV 	AX, ES:[SI]
		INC 	SI
		CMP 	AX, 0H
		JNE 	CYCLE
		ADD 	SI, 3H
		MOV 	DI, 0H
	
       	GETT_PATH:
		MOV 	CL, ES:[SI]
		CMP 	CL, 0H
		JE		NAME_PROG	
		CMP 	CL, '\'
		JNE 	SET_IN_STR
		MOV 	BIAS, DI

       	SET_IN_STR:
		MOV 	BYTE PTR [STR_PATH + DI], CL
		INC 	SI
		INC 	DI
		JMP 	GETT_PATH
	
       	NAME_PROG:
		MOV 	BX, BIAS
		INC 	BX
		MOV 	BYTE PTR [STR_PATH + BX], 'l'
		INC 	BX
		MOV 	BYTE PTR [STR_PATH + BX], 'a'
		INC 	BX
		MOV 	BYTE PTR [STR_PATH + BX], 'b'
		INC 	BX
		MOV 	BYTE PTR [STR_PATH + BX], '2'
		INC 	BX
		MOV 	BYTE PTR [STR_PATH + BX], '.'
		INC 	BX
		MOV 	BYTE PTR [STR_PATH + BX], 'c'
		INC 	BX
		MOV 	BYTE PTR [STR_PATH + BX], 'o'
		INC 	BX
		MOV 	BYTE PTR [STR_PATH + BX], 'm'
		INC 	BX
		MOV 	BYTE PTR [STR_PATH + BX], '$'
		RET

CREATE_COMMAND_PATH ENDP

PRINT_ERROR_LOAD PROC FAR

		CMP 	AX, 1H
		JNE 		FILE_NOT_FOUND
		
		MOV 	DX, OFFSET INCORRECT_NUM_FUNC_STR
		PUSH	AX
       		MOV	AH, 09H
        	INT		21H
		POP 	AX 
		JMP 	RETURN_
		
		
       	FILE_NOT_FOUND:
		CMP 	AX, 2H
		JNE		DISK_ERROR
		
		MOV 	DX, OFFSET FILE_NOT_FOUND_STR
		PUSH	AX
       		MOV	AH, 09H
        	INT		21H
		POP 	AX 
		JMP 	RETURN_	
		
       	DISK_ERROR:
		CMP 	AX, 5H
		JNE		OUT_OF_MEM

		MOV 	DX, OFFSET DISK_ERR_STR
		PUSH	AX
       		MOV	AH, 09H
        	INT		21H
		POP 	AX 
		JMP 	RETURN_
		
       	OUT_OF_MEM:
		CMP	AX, 8H
		JNE		INCORRECT_ENVIRONMENT_STRING
			
		MOV 	DX, OFFSET OUT_OF_MEMORY_STR
		PUSH	AX
       		MOV	AH, 09H
        	INT		21H
		POP 	AX 
		JMP 	RETURN_
		
       	INCORRECT_ENVIRONMENT_STRING:
		CMP	AX, 0AH
		JNE		INCORRECT_FORMAT

		MOV 	DX, OFFSET INCORRECT_ENVIRONMENT_STRING_STR
		PUSH	AX
       		MOV	AH, 09H
        	INT		21H
		POP 	AX 
		JMP		RETURN_
		
		INCORRECT_FORMAT:
		CMP	AX, 0BH
		JNE		RETURN_
		
		MOV 	DX, OFFSET INCORRECT_FORMAT_STR
		PUSH	AX
       		MOV	AH, 09H
        	INT		21H
		POP 	AX 
		
		RETURN_:
		RET

PRINT_ERROR_LOAD ENDP

PRINT_CODE_FINAL PROC NEAR

		MOV		DI, OFFSET PROGRAM_END_CODE_STR
		MOV		[DI + 13H], AL
		MOV 	DX, OFFSET PROGRAM_END_CODE_STR
		PUSH	AX
       		MOV	AH, 09H
        	INT		21H
		POP 	AX
	
		CMP 	AH, 0H
		JE 		EXIT_CODE_0
		CMP 	AH, 1H
		JE 		EXIT_CODE_CTRL_BREAK
		CMP 	AH, 2H
		JE 		EXIT_CODE_DEVICE_ERR
		CMP 	AH, 3H
		JE 		EXIT_CODE_FUNCTION
		JMP 	RETURN__
		
       	EXIT_CODE_0:
		MOV 	DX, OFFSET EXIT_CODE_0_STR
		PUSH	AX
       		MOV	AH, 09H
        	INT		21H
		POP 	AX
		JMP 	RETURN__
		
       	EXIT_CODE_CTRL_BREAK:
		MOV 	DX, OFFSET EXIT_CODE_CTRL_BREAK_STR
		PUSH	AX
       		MOV	AH, 09H
        	INT		21H
		POP 	AX
		JMP 	RETURN__
		
       	EXIT_CODE_DEVICE_ERR:
		MOV 	DX, OFFSET EXIT_CODE_DEVICE_ERR_STR
		PUSH	AX
       		MOV	AH, 09H
        	INT		21H
		POP 	AX
		JMP 	RETURN__
		
		EXIT_CODE_FUNCTION:
		MOV	DX, OFFSET EXIT_CODE_FUNC_STR
		PUSH	AX
       		MOV	AH, 09H
        	INT		21H
		POP 	AX
		
		RETURN__:
		RET

PRINT_CODE_FINAL ENDP


Main:          
		MOV 	AX, DATA		  
		MOV 	DS, AX
		
		CALL FREE_MEMORY
		JNC	CREATE_BLOCK_PARAM_LABEL

		CALL PRINT_ERROR_MEMORY
		JMP	PROGRAM_END

		CREATE_BLOCK_PARAM_LABEL:
		;MOV 	WORD PTR [PARAM_BLOCK], 0H
		CALL 	CREATE_COMMAND_PATH
		
       	MOV 	CS:SP_SAVE, SP
		MOV 	CS:SS_SAVE, SS

		MOV		AX, DATA
		MOV		ES, AX
		MOV 	BX, OFFSET PARAM_BLOCK
		MOV		DX, offset CMD_STR
		MOV		[BX + 2], DX
		MOV		[BX + 4], DS
		MOV 	DX, OFFSET STR_PATH 
		MOV 	AX, 4B00H	
		INT 	21H
		
		MOV 	SS, CS:SS_SAVE	 
		MOV 	SP, CS:SP_SAVE 

		PUSH	AX
		MOV		AX, DATA
		MOV		DS, AX
		POP		AX
		
		JNC 	FINAL
		
		CALL    PRINT_ERROR_LOAD
		JMP		PROGRAM_END

		FINAL:
		MOV 	AH, 4DH	
		MOV		AL, 00H
		INT 	21H
		
		CALL 	PRINT_CODE_FINAL
		
		PROGRAM_END:
		MOV 	AH, 4CH
		INT 	21H
		


CODE      	ENDS 

DATA		SEGMENT

MEM_CONTROL_BLOCK_DEST_STR 		DB "Memory control block destroyed - error 4ah", 13, 10, "$"
NOT_MEM_STR						DB "Not enough memory for function 4ah", 13, 10, "$"
INVALID_BLOCK_ADRESS_STR		DB "Invalid block address - error 4ah", 13, 10, "$"

OUT_OF_MEMORY_STR					DB "Out of memory", 13, 10, "$"
INCORRECT_NUM_FUNC_STR 		DB "Number of function is incorrect", 13, 10, "$"
FILE_NOT_FOUND_STR 					DB "File not found", 13, 10, "$"
DISK_ERR_STR 						DB " Disk error has occured", 13, 10, "$"
INCORRECT_ENVIRONMENT_STRING_STR 	DB " Incorrect environment string!", 13, 10, "$"
INCORRECT_FORMAT_STR 				DB " Incorrect format", 13, 10, "$"

PROGRAM_END_CODE_STR 				DB 13, 10, "Program end code:      ", 13, 10, "$"
EXIT_CODE_FUNC_STR 				DB "Program terminated by function 31h!", 13, 10, "$"
EXIT_CODE_0_STR 					DB "Program terminated with exit code 0", 13, 10, "$"
EXIT_CODE_CTRL_BREAK_STR 			DB "Program terminated by ctrl-break", 13, 10, "$"
EXIT_CODE_DEVICE_ERR_STR 			DB "Program terminated by device error!", 13, 10, "$"

CMD_STR								DB 1H, 0DH

PARAM_BLOCK 						DB 0EH dup(0)
STR_PATH  							DB 46H dup(0) 	  
BIAS								DW 0H 				

DATA      	ENDS 

STACK_PROGRAM	SEGMENT	STACK           

DW 		100H DUP(?)

STACK_PROGRAM   	ENDS  


       	END	Main
