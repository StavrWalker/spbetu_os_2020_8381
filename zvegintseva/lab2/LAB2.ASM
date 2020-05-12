;;; -*- indent-tabs-mode: t; tab-width: 8; electric-quote-mode: nil -*-

TEXT SEGMENT
	ASSUME CS:TEXT, DS:TEXT
	ORG 100h

START:
	jmp	MAIN


NEWLINE_STRING	DB	13, 10, '$'
EOM_STRING	DB	'Inaccessible memory start segment address: $'
ENV_ADDR_STRING	DB	'Environment segment address: $'
CMDLINE_TAIL_STRING	DB	'Command-line tail: "$'
CMDLINE_TAIL_STRING_END	DB	'"',13,10,'$'
ENV_STRING	DB	'Environment:',13,10,'$'
EXE_NAME_STRING	DB	'Executable file name: $'


WRITE_STR PROC
	push	AX
	mov	AH,	09h
	int	21h
	pop	AX
	ret
WRITE_STR ENDP

NEWLINE PROC
	push	DX
	mov	DX,	OFFSET NEWLINE_STRING
	call	WRITE_STR
	pop	DX
	ret
NEWLINE ENDP

TETR_TO_HEX PROC near
	and      AL,0Fh
	cmp      AL,09
	jbe      NEXT
	add      AL,07
NEXT:
	add      AL,30h
	ret
TETR_TO_HEX   ENDP

BYTE_TO_HEX   PROC  near
	push     CX
	mov      AH,AL
	call     TETR_TO_HEX
	xchg     AL,AH
	mov      CL,4
	shr      AL,CL
	call     TETR_TO_HEX
	pop      CX
	ret
BYTE_TO_HEX  ENDP

WRD_TO_HEX   PROC  near
	push     BX
	mov      BH,AH
	call     BYTE_TO_HEX
	mov      [DI],AH
	dec      DI
	mov      [DI],AL
	dec      DI
	mov      AL,BH
	call     BYTE_TO_HEX
	mov      [DI],AH
	dec      DI
	mov      [DI],AL
	pop      BX
	ret
WRD_TO_HEX ENDP

BYTE_TO_DEC   PROC  near
	push     CX
	push     DX
	xor      AH,AH
	xor      DX,DX
	mov      CX,10
loop_bd:
	div      CX
	or       DL,30h
	mov      [SI],DL
	dec      SI
	xor      DX,DX
	cmp      AX,10
	jae      loop_bd
	cmp      AL,00h
	je       end_l
	or       AL,30h
	mov      [SI],AL
end_l:
	pop      DX
	pop      CX
	ret
BYTE_TO_DEC    ENDP

;;; AX: address
WRITE_ADDR PROC
	push	AX
	push	BP
	push	DX

	;; allocate 5 bytes (1 word in hex + `$')
	sub	SP,	5
	mov	BP,	SP

	lea	DI,	[BP+3]
	mov	BYTE PTR [DI+1],	'$'
	call	WRD_TO_HEX

	mov	DX,	BP
	call	WRITE_STR

	add	SP,	5
	pop	DX
	pop	BP
	pop	AX
	ret
WRITE_ADDR ENDP

WRITE_EOM PROC
	push	AX
	push	DX
	push	SI

	mov	DX,	OFFSET EOM_STRING
	call	WRITE_STR

	mov	SI,	02h
	mov	AX,	WORD PTR [SI]

	push	DS
	push	DI
	mov	DS,	AX
	mov	DI,	0
	mov	WORD PTR [DI],	42
	pop	DI
	pop	DS

	call	WRITE_ADDR

	call	NEWLINE

	pop	SI
	pop	DX
	pop	AX
	ret
WRITE_EOM ENDP

WRITE_ENV_ADDR PROC
	push	AX
	push	DX
	push	SI

	mov	DX,	OFFSET ENV_ADDR_STRING
	call	WRITE_STR

	mov	SI,	2Ch
	mov	AX,	WORD PTR [SI]
	call	WRITE_ADDR

	call	NEWLINE

	pop	SI
	pop	DX
	pop	AX
	ret
WRITE_ENV_ADDR ENDP

;;; SI: address
WRITE_C_STRING PROC
	push	AX
	push	DX

_write_c_string_enter:
	lodsb
	test	AL,	AL
	jz	_write_c_string_exit

	mov	DL,	AL
	mov	AH,	02h
	int	21h

	jmp	_write_c_string_enter

_write_c_string_exit:
	pop	DX
	pop	AX
	ret
WRITE_C_STRING ENDP

;;; SI: address
WRITE_PASCAL_STRING PROC
	push	AX
	push	DX

	lodsb
	mov	DH,	AL

_write_pascal_string_enter:
	test	DH,	DH
	jz	_write_pascal_string_exit
	dec	DH

	lodsb
	mov	DL,	AL
	mov	AH,	02h
	int	21h

	jmp	_write_pascal_string_enter

_write_pascal_string_exit:
	pop	DX
	pop	AX
	ret
WRITE_PASCAL_STRING ENDP

WRITE_CMDLINE_TAIL PROC
	push	DX
	push	SI

	mov	DX,	OFFSET CMDLINE_TAIL_STRING
	call	WRITE_STR

	mov	SI,	80h
	call	WRITE_PASCAL_STRING

	mov	DX,	OFFSET CMDLINE_TAIL_STRING_END
	call	WRITE_STR

	pop	SI
	pop	DX
	ret
WRITE_CMDLINE_TAIL ENDP

WRITE_ENV PROC
	push	AX
	push	DX
	push	SI

	mov	DX,	OFFSET ENV_STRING
	call	WRITE_STR

	mov	SI,	2Ch
	mov	DX,	WORD PTR [SI]
	push	DS
	mov	DS,	DX
	xor	SI,	SI

_write_env_enter:
	mov	DL,	BYTE PTR [SI]
	test	DL,	DL
	jz	_write_env_exit

	call	WRITE_C_STRING

	push	DS
	mov	AX,	CS
	mov	DS,	AX
	call	NEWLINE
	pop	DS

	jmp	_write_env_enter

_write_env_exit:
	lodsb
	cmp	AL,	00h
	jne	_write_env_error

	lodsb
	cmp	AL,	01h
	jne	_write_env_error

	lodsb
	cmp	AL,	00h
	jne	_write_env_error

	push	DS
	mov	AX,	CS
	mov	DS,	AX
	mov	DX,	OFFSET EXE_NAME_STRING
	call	WRITE_STR
	pop	DS

	call	WRITE_C_STRING

	pop	DS

	call	NEWLINE

	pop	SI
	pop	DX
	pop	AX
	ret

ERROR_STRING	DB	'ERROR!',13,10,'$'

_write_env_error:
	pop	DS
	pop	SI

	mov	DX,	OFFSET ERROR_STRING
	call	WRITE_STR

	pop	DX
	pop	AX

	ret
WRITE_ENV ENDP

MAIN PROC
	call	WRITE_EOM
	call	WRITE_ENV_ADDR
	call	WRITE_CMDLINE_TAIL
	call	WRITE_ENV
	
	mov	AX,	4C00h
	int	21h
MAIN ENDP

TEXT ENDS
END START
