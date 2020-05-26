OVERLAY_2 SEGMENT
ASSUME CS:OVERLAY_2, DS:NOTHING, ES:NOTHING, SS:NOTHING

MAIN:JMP BEGIN

SEG_ADR db 	13,10,'Segment address of second overlay segment:     ', 13, 10, '$'


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

PRINT PROC NEAR
		PUSH AX
		MOV AH, 09H
		INT 21H
		POP AX
		RET
PRINT ENDP

;--------------------------------------------------------------------------------


BEGIN PROC FAR
		push	ax
		push 	dx
		push	di
		push	ds
		
		mov		ax, cs
		mov		ds, ax
		mov 	bx, offset SEG_ADR
		add 	bx, 47
		mov 	di, bx
		mov 	ax, cs
		call	WRD_TO_HEX
		mov 	dx, offset SEG_ADR
		call	PRINT
		
		pop		ds
		pop		di
		pop		dx
		pop		ax
		retf
BEGIN ENDP

OVERLAY_2 ENDS
END 