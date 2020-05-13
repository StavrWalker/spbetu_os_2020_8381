TESTPSP		SEGMENT
			ASSUME	CS:TESTPSP,	DS:TESTPSP,	ES:NOTHING,	SS:NOTHING
			ORG		100H
START:		JMP		BEGIN
; §¡ÕÕò©
ADDRESS_MEM		db		'Unavailable memory address :     ', 0dh, 0ah, '$'
ADDRESS_ENV		db		'Environment address :         	  ', 0dh, 0ah, '$'
TAIL_COMLIN		db		'Command line tail :              ', 0dh, 0ah, '$'
CONTENT_ENV		db		'Environment content :            ', 0dh, 0ah, '$'
MODULE_PATH	    db		'Module load path : 		      ', 0dh, 0ah, '$'
NEXT_LINE		db		0dh, 0ah, '$'
; Ýâ×¥©§èâò
;-----------------------------------------------------------
WRITE_STRING	PROC	near
			mov		AH, 09h
			int		21h
			ret
WRITE_STRING	ENDP
;---------------------------
TETR_TO_HEX		PROC	near
			and		AL, 0fh
			cmp		AL, 09
			jbe		NEXT
			add		AL, 07
NEXT:		add		AL, 30h
			ret
TETR_TO_HEX		ENDP
;---------------------------
BYTE_TO_HEX		PROC 	near
; ¢ ½å ë AL Ø¨á¨ëÖ¦·åãÞ ë ¦ë  ã·ÒëÖÐ  õ¨ãåÔ. û·ãÐ  ë AX
			push	CX
			mov		AH, AL
			call	TETR_TO_HEX
			xchg	AL, AH
			mov		CL, 4
			shr		AL, CL
			call	TETR_TO_HEX ; ë AL ãå áõ Þ ¤·ªá 
			pop		CX 			; ë AH ÒÐ ¦õ Þ
			ret
BYTE_TO_HEX		ENDP
;--------------------------
WRD_TO_HEX		PROC	near
; Ø¨áëÖ¦ ë 16 ã/ã 16-å· á óáÞ¦ÔÖ¬Ö û·ãÐ 
; ë AX - û·ãÐÖ, DI -  ¦á¨ã ØÖãÐ¨¦Ô¨¬Ö ã·ÒëÖÐ 
			push	BX
			mov		BH, AH
			call	BYTE_TO_HEX
			mov		[DI], AH
			dec		DI
			mov		[DI], AL
			dec		DI
			mov		AL, BH
			call	BYTE_TO_HEX
			mov		[DI], AH
			dec		DI
			mov		[DI], AL
			pop		BX
			ret
WRD_TO_HEX		ENDP
;---------------------------
DEF_ADDRESS_MEM	PROC	near
; ×Øá¨¦¨Ð¨Ô·¨ ã¨¬Ò¨ÔåÔÖ¬Ö  ¦á¨ã  Ô¨¦ÖãåçØÔÖ½ Ø ÒÞå·
			push	AX
			mov 	AX, ES:[2]
			lea		DI, ADDRESS_MEM
			add		DI, 33
			call 	WRD_TO_HEX
			pop		AX
			lea		DX, ADDRESS_MEM
			call	WRITE_STRING
			ret
DEF_ADDRESS_MEM	ENDP
;---------------------------
DEF_ADDRESS_ENV	PROC	near
; ×Øá¨¦¨Ð¨Ô·¨ ã¨¬Ò¨ÔåÔÖ¬Ö  ¦á¨ã  ãá¨¦ñ
			push 	AX
			mov		AX, ES:[2Ch]
			lea		DI, ADDRESS_ENV
			add 	DI, 33
			call	WRD_TO_HEX
			pop		AX
			lea		DX, ADDRESS_ENV
			call	WRITE_STRING
			ret
DEF_ADDRESS_ENV	ENDP
;---------------------------
DEF_TAIL_COMLIN	PROC	near
; ×Øá¨¦¨Ð¨Ô·¨ µëÖãå  ÆÖÒ Ô¦ÔÖ½ ãåáÖÆ·
			lea		DX, TAIL_COMLIN
			call	WRITE_STRING
			push	AX
			push	BX
			xor		AX, AX
			mov		AL,	ES:[80h]
			add		AL, 81h
			mov		SI,	AX
			push	ES:[SI]
			mov		byte ptr ES:[SI+1], '$'
			push	DS
			mov		BX, ES
			mov 	DS,	BX
			mov		DX,	81h
			call	WRITE_STRING
			pop		DS
			pop		ES:[SI]
			pop		CX
			pop		AX
			ret
DEF_TAIL_COMLIN	ENDP
;---------------------------
DEF_CONENV_PATH	PROC	near
; ×Øá¨¦¨Ð¨Ô·¨ ãÖ¦¨áé·ÒÖ¬Ö Ö¢Ð ãå· ãá¨¦ñ
; ×Øá¨¦¨Ð¨Ô·¨ Øçå· ó ¬áçóÖûÔÖ¬Ö ª ½Ð 
			lea		DX, CONTENT_ENV
			call	WRITE_STRING
			mov 	SI, 2Ch
			mov 	DS, ES:[2Ch]
			xor 	SI, SI
LOOP_1: 	cmp 	word ptr [si], 0
			je 		LOOP_END
			lodsb
			cmp		AL, 0h
			jnz 	NEXT_LOOP
			mov 	AX, 0Dh
			int 	29h
			mov 	AX, 0Ah
NEXT_LOOP:	int 	29h
			jmp 	LOOP_1
LOOP_END:	inc 	SI
			inc 	SI
			lodsb
			inc 	SI
			push	DS
			mov 	CX, ES
			mov 	DS, CX
			lea		DX, NEXT_LINE
			call 	WRITE_STRING
			lea		DX, MODULE_PATH
			call 	WRITE_STRING
			pop 	DS
LOOP_2:		lodsb 
			cmp 	AL, 0h
			jz 		RETURN
			int 	29h
			jmp 	LOOP_2
RETURN:		ret
DEF_CONENV_PATH	ENDP
;---------------------------
; Ø¨û åí á¨óçÐíå åÖë · ëñµÖ¦ ë DOS
BEGIN:		call	DEF_ADDRESS_MEM
			call	DEF_ADDRESS_ENV
			call	DEF_TAIL_COMLIN
			call	DEF_CONENV_PATH
			mov		AH, 4Ch
			int		21h
			ret
TESTPSP			ENDS
END 	START