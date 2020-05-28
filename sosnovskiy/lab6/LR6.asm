ASTACK	SEGMENT  STACK
	DW 256 DUP(?)			
ASTACK  ENDS

DATA SEGMENT

	LR2FILENAME db 'LR2.COM', 0
	PARAM_BLOCK dw 7 dup(0)
	
	KEEP_SS dw 0
	KEEP_SP dw 0
	KEEP_PSP dw 0
	NOFILE_ERROR_STR db 13,10, 'File not found',13, 10,'$'
	CtrlC_ENDING_STR db 13,10,'Completion by Ctrl+C$'
	LR2FILENAME_F db 50 dup (0),'$'
	COMPLETION db 13,10,'Program ended with code: $'
	DATA_END db 0
	
DATA  ENDS

CODE	SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:ASTACK

	
HEX_BYTE_PRINT PROC NEAR
		PUSH AX
		PUSH BX
		PUSH DX
		MOV AH, 0
		MOV BL, 10H
		DIV BL 
		MOV DX, AX
		MOV AH, 02H
		CMP DL, 0AH 
		JL PRINT_1	
		ADD DL, 7
	PRINT_1:
		ADD DL, 48
		INT 21H
		MOV DL, DH
		CMP DL, 0AH
		JL PRINT_2   
		ADD DL, 7	
	PRINT_2:
		ADD DL, 48
		INT 21H;
		POP DX
		POP BX
		POP AX
		RET
HEX_BYTE_PRINT ENDP

PRINT PROC NEAR
		PUSH AX
		MOV AH, 09H
		INT 21H
		POP AX
		RET
PRINT ENDP

FREE_MEMORY 	PROC NEAR
		push ax
		push bx
		push cx
		push dx 
		push es
		push ds
		
		mov BX, offset PROGRAM_END
		mov AX, offset DATA_END
		add BX, AX
		add BX, 40Fh
		mov CL, 4
		shr BX, CL
		mov AH, 4Ah
		int 21h
		
		pop ds
		pop es
		pop dx
		pop cx
		pop bx
		pop ax
	RET
FREE_MEMORY	 ENDP

LOAD proc near
		push ax
		push bx
		push cx
		push dx 
		push es
		push ds
		push si
		push di
		push ss
		push sp
			
		mov es, es:[2Ch]
		mov si,0
		lea di, LR2FILENAME_F
		SKIP_ENVIR:
			mov dl, es:[si]
			cmp dl, 00			
			je ENVIR_ENDING	
			inc si
			jmp SKIP_ENVIR
		ENVIR_ENDING:
			inc si
			mov dl, es:[si]
			cmp dl, 00	
			jne SKIP_ENVIR
			add si, 3	
		PATH_S:
			mov dl, es:[si]
			cmp dl, 00	
			je WRITE_NAME	
			mov [di], dl	
			inc si			
			inc di			
			jmp PATH_S
		WRITE_NAME:
			mov si,0
		FILE_NAME:
			mov dl, byte ptr [LR2FILENAME+si]
			mov byte ptr [di-7], dl
			inc di
			inc si
			test dl, dl
			jne FILE_NAME
		
		mov KEEP_SS, ss
		mov KEEP_SP, sp
		
		push ds
		pop es
		
		mov bx, offset PARAM_BLOCK	
		mov dx, offset LR2FILENAME_F
		
		mov ah, 4bh
		mov al, 0
		int 21h
		
		jnc NO_LOAD_ERRORS
		mov bx, DATA
		mov ds, bx
		mov SS, KEEP_SS
		mov SP, KEEP_SP
		
		cmp ax, 2
		je ERROR_NOFILE
		jmp NO_LOAD_ERRORS
		
		ERROR_NOFILE:
			mov dx, offset NOFILE_ERROR_STR
			call PRINT
			mov ax, 4C00h
			int 21h
			
		NO_LOAD_ERRORS:
		
		mov ax, 4D00h 
		int 21h
		
		cmp al, 3
		je CTRLC_END
		
				
		LOAD_END:
		mov dx,0
		mov dx, offset COMPLETION
		call PRINT
		call HEX_BYTE_PRINT
		jmp LOAD_ENDING
		
		
		CTRLC_END:
			mov dx, offset CtrlC_ENDING_STR
			call PRINT
			
		LOAD_ENDING:
		pop sp
		pop ss
		pop di
		pop si
		pop ds
		pop es
		pop dx
		pop cx
		pop bx
		pop ax
		RET
LOAD ENDP

MAIN proc far
    push ds
    xor ax, ax
    push ax
    mov ax, DATA
    mov ds, ax
	mov KEEP_PSP, ES
	call FREE_MEMORY
	mov AX,KEEP_PSP
	mov ES,AX
	call LOAD
	mov ax, 4C00h
	int 21h
	ret
MAIN endp
PROGRAM_END:
CODE ENDS


end MAIN