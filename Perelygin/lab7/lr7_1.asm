DATA SEGMENT
	PSP_SEGMENT dw 0

	overlay_parametr_segment 			dw 0
	ADRESS_OVL 				dd 0

	STR_NO_PATH 				db 13, 10, "Path wasn't found$"
	STR_ERROR_LOAD 			db 13, 10, "overlay wasn't load$"
	str_overlay1_inf			db 13, 10, "overlay1:$"
	str_overlay2_inf			db 13, 10, "overlay2:$"
	STR_MEMORY_FREE		db 13, 10, "Memory free$"
	STR_GETSIZE_ERROR 		db 13, 10, "overlay size wasn't get$"
	STR_NO_FILE 				db 13, 10, "File wasn't found$"
	STR_OVL1 				db "ovl1.ovl", 0
	STR_OVL2 				db "ovl2.ovl", 0
	STR_PATH 				db 100h dup(0)
	OFFSET_OVL_NAME 		dw 0
	NAME_POS 				dw 0
	memory_error 			dw 0
	
	DTA 					db 43 dup(0)
DATA ENDS

STACKK SEGMENT STACK
	dw 100h dup (0)
STACKK ENDS

CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:STACKK

print_str 	PROC	near
		push 	AX
		mov 	AH, 09h
		int		21h
		pop 	AX
	ret
print_str 	ENDP

memory_free 	PROC
		lea 	BX, PROGEND
		mov 	AX, ES
		sub 	BX, AX
		mov 	CL, 8
		shr 	BX, CL
		sub 	AX, AX
		mov 	AH, 4Ah
		int 	21h
		jc 		MCATCH
		mov 	DX, offset STR_memory_free
		call	print_str
		jmp 	MDEFAULT
	MCATCH:
		mov 	memory_error, 1
	MDEFAULT:
	ret
memory_free 	ENDP


overlay_exec PROC
		push	AX
		push	BX
		push	CX
		push	DX
		push	SI

		mov 	OFFSET_OVL_NAME, AX
		mov 	AX, PSP_SEGMENT
		mov 	ES, AX
		mov 	ES, ES:[2Ch]
		mov 	SI, 0
	zero_find:
		mov 	AX, ES:[SI]
		inc 	SI
		cmp 	AX, 0
		jne 	zero_find
		add 	SI, 3
		mov 	DI, 0
	write_path:
		mov 	AL, ES:[SI]
		cmp 	AL, 0
		je 		write_name_of_path
		cmp 	AL, '\'
		jne 	new_symbol
		mov 	NAME_POS, DI
	new_symbol:
		mov 	BYTE PTR [STR_PATH + DI], AL
		inc 	DI
		inc 	SI
		jmp 	write_path
	write_name_of_path:
		cld
		mov 	DI, NAME_POS
		inc 	DI
		add 	DI, offset STR_PATH
		mov 	SI, OFFSET_OVL_NAME
		mov 	AX, DS
		mov 	ES, AX
	UPDATE:
		lodsb
		stosb
		cmp 	AL, 0
		jne 	UPDATE

		mov 	AX, 1A00h
		mov 	DX, offset DTA
		int 	21h
		
		mov 	AH, 4Eh
		mov 	CX, 0
		mov 	DX, offset STR_PATH
		int 	21h
		
		jnc 	no_error
		mov 	DX, offset STR_GETSIZE_ERROR
		call 	print_str
		cmp 	AX, 2
		je 		no_file
		cmp 	AX, 3
		je 		no_path
		jmp 	path_end
	no_file:
		mov 	DX, offset STR_no_file
		call 	print_str
		jmp 	path_end
	no_path:
		mov 	DX, offset STR_no_path
		call 	print_str
		jmp 	path_end
	no_error:
		mov 	SI, offset DTA
		add 	SI, 1Ah
		mov 	BX, [SI]
		mov 	AX, [SI + 2]
		mov		CL, 4
		shr 	BX, CL
		mov		CL, 12
		shl 	AX, CL
		add 	BX, AX
		add 	BX, 2
		mov 	AX, 4800h
		int 	21h
		
		jnc 	set_segment
		jmp 	path_end
	set_segment:
		mov 	overlay_parametr_segment, AX
		mov 	DX, offset STR_PATH
		push 	DS
		pop 	ES
		mov 	BX, offset overlay_parametr_segment
		mov 	AX, 4B03h
		int 	21h
		
		jnc 	load_success		
		mov 	DX, offset STR_ERROR_LOAD
		call 	print_str
		jmp		path_end

	load_success:
		mov		AX, overlay_parametr_segment
		mov 	ES, AX
		mov 	WORD PTR ADRESS_OVL + 2, AX
		call 	ADRESS_OVL
		mov 	ES, AX
		mov 	AH, 49h
		int 	21h

	path_end:
		pop 	SI
		pop 	DX
		pop 	CX
		pop 	BX
		pop 	AX
		ret
	overlay_exec ENDP
	
	BEGIN:
		mov 	AX, DATA
		mov 	DS, AX
		mov 	PSP_SEGMENT, ES
		call 	memory_free
		cmp 	memory_error, 1
		je 		MAIN_END
		mov 	DX, offset str_overlay1_inf
		call	print_str
		mov 	AX, offset STR_OVL1
		call 	overlay_exec
		mov 	DX, offset str_overlay2_inf
		call	print_str
		mov 	AX, offset STR_OVL2
		call 	overlay_exec
		
	MAIN_END:
		mov AX, 4C00h
		int 21h
	PROGEND:
CODE ENDS
END BEGIN