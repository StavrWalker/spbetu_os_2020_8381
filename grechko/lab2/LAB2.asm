TESTPC	SEGMENT
		ASSUME	CS:TESTPC,	DS:TESTPC,	ES:NOTHING,	SS:NOTHING
		ORG		100H
START:	JMP		BEGIN
; ДАННЫЕ
UnavailableMemory	db		'Unavailable memory segment address:     ',0dh,0ah,'$'
EnvironmentAdress	db 		'Segment address of environment:     ',0dh,0ah,'$'
Tail				db		'Command line tail: ', '$'
EnvironmentContents	db		'Environment area contents: ' , '$'
Path				db		'Module load path: ' , '$'
Endl				db		0dh,0ah,'$'
; ПРОЦЕДУРЫ
;-----------------------------------------------------------
Print_message	PROC	near
		push 	ax
		mov		ah,09h
		int		21h
		pop		ax
		ret
Print_message	ENDP
;-----------------------------------------------------------
TETR_TO_HEX		PROC	near
		and		al,0fh
		cmp		al,09
		jbe		NEXT
		add		al,07
NEXT:	add		al,30h
		ret
TETR_TO_HEX		ENDP
;-----------------------------------------------------------
BYTE_TO_HEX		PROC near
; байт в AL переводится в два символа шестн. числа в AX
		push	cx
		mov		ah,al
		call	TETR_TO_HEX
		xchg	al,ah
		mov		cl,4
		shr		al,cl
		call	TETR_TO_HEX ; в AL старшая цифра
		pop		cx 			; в AH младшая
		ret
BYTE_TO_HEX		ENDP
;-----------------------------------------------------------
WRD_TO_HEX		PROC	near
; первод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
		push	bx
		mov		bh,ah
		call	BYTE_TO_HEX
		mov		[di],ah
		dec		di
		mov		[di],al
		dec		di
		mov		al,bh
		call	BYTE_TO_HEX
		mov		[di],ah
		dec		di
		mov		[di],al
		pop		bx
		ret
WRD_TO_HEX		ENDP
;-----------------------------------------------------------
UnMemory		PROC	near
		push	ax
		mov 	ax,es:[2]
		lea		di,UnavailableMemory
		add 	di,39
		call	WRD_TO_HEX
		pop		ax
		ret
UnMemory		ENDP
;-----------------------------------------------------------
EnAdress		PROC	near
		push	ax
		mov 	ax,es:[2Ch]
		lea		di,EnvironmentAdress
		add 	di,35
		call	WRD_TO_HEX
		pop		ax
		ret
EnAdress		ENDP
;-----------------------------------------------------------
ClTail			PROC	near
		push 	cx
		xor 	cx, cx
		mov 	cl, es:[80h]
		cmp		cl, 0
		je		EXIT
		add		cl, 81h
		mov		si, cx
		push 	es:[si]
		mov 	byte ptr es:[si], '$'
		push	ds
		mov 	cx, es
		mov     ds, cx
		mov		dx, 81h
		call	Print_message
		pop		ds
		pop		es:[si]
EXIT:	pop		cx
		ret
ClTail			ENDP
;-----------------------------------------------------------
Area_and_path	PROC	near
		push 	es 
		push	ax 
		push	cx 
		lea 	dx,EnvironmentContents
		call	Print_message
		mov		es,es:[2ch] 
		mov		si,0 
	NEW_STR:
		lea		dx, Endl
		call	Print_message 
		mov		ax,si 
	END_STR:
		cmp 	byte ptr es:[si], 0 
		je 		PRINT_STR 
		inc		si
		jmp 	END_STR 
	PRINT_STR:
		push	es:[si] 
		mov		byte ptr es:[si], '$' 
		push	ds 
		mov		cx,es 
		mov		ds,cx 
		mov		dx,ax 
		call	Print_message 
		pop		ds 
		pop		es:[si] 
		inc		si 
		cmp 	byte ptr es:[si], 01h 
    	jne 	NEW_STR 
    	lea		dx, Endl
		call	Print_message 
    	lea		dx,Path 
    	call	Print_message 
    	add 	si,2 
		lea		dx, Endl
		call	Print_message 
		mov		ax,si 
	END_STR2:
		cmp 	byte ptr es:[si], 0 
		je 		PRINT_STR2 
		inc		si 
		jmp 	END_STR2 
	PRINT_STR2:
		push	es:[si] 
		mov		byte ptr es:[si], '$' 
		push	ds 
		mov		cx,es 
		mov		ds,cx 
		mov		dx,ax 
		call	Print_message 
		pop		ds 
		pop		es:[si] 
    	lea		dx, Endl
		call	Print_message 
		pop		cx 
		pop		ax 
		pop		es 
		ret
Area_and_path	ENDP
;-----------------------------------------------------------
BEGIN:
		call	UnMemory
		lea		dx,UnavailableMemory
		call	Print_message
		call 	EnAdress
		lea 	dx,EnvironmentAdress
		call	Print_message
		lea 	dx,Tail
		call	Print_message
		call	ClTail
		lea		dx, Endl
		call	Print_message
		call	Area_and_path 
		xor 	al,al
		mov		ah,4ch
		int		21h
TESTPC	ENDS
		END 	START	;конец модуля, START - точка входа


