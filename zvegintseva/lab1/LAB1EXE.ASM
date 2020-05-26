;;; -*- indent-tabs-mode: t; tab-width: 8; electric-quote-mode: nil -*-

STACK SEGMENT STACK
	DW	100h DUP(?)
STACK ENDS

	ASSUME CS:TEXT, DS:DATA, SS:STACK

DATA SEGMENT

MODEL_FF	DB	'PC$'
MODEL_FE_FB	DB	'PC/XT$'
MODEL_FC	DB	'AT or PS/2 model 50 or 60$'
MODEL_FA	DB	'PS/2 model 30$'
MODEL_F8	DB	'PS/2 model 80$'
MODEL_FD	DB	'PCjr$'
MODEL_F9	DB	'PC Convertible$'
MODEL_UNKNOWN	DB	'Unknown model$'

MODEL_TAB	DW	OFFSET MODEL_FF
		DW	OFFSET MODEL_FE_FB
		DW	OFFSET MODEL_FE_FB
		DW	OFFSET MODEL_FC
		DW	OFFSET MODEL_FA
		DW	OFFSET MODEL_F8
		DW	OFFSET MODEL_FD
		DW	OFFSET MODEL_F9
		DW	OFFSET MODEL_UNKNOWN

MODEL_CHARS	DB	0FFh, 0FEh, 0FBh, 0FCh
		DB	0FAh, 0F8h, 0FDh, 0F9h, 0

NEWLINE_STRING	DB	13, 10, '$'

DOS_VERSION_STRING	DB	'DOS version: $'
OEM_NUMBER_STRING	DB	'OEM number: $'
USER_SERIAL_STRING	DB	'User serial number: $'

DATA ENDS

TEXT SEGMENT

LOOKUP_MODEL PROC
	push	BX
	xor	BX,	BX

	;; we don't save DX as we return into it anyway
_lookup_model_loop:
	mov	DL,	MODEL_CHARS[BX]

	;; zero => unknown model
	test	DL,	DL
	jz	_lookup_model_break

	;; model code matches => exit
	cmp	DL,	AL
	jz	_lookup_model_break

	inc	BX
	jmp	_lookup_model_loop

_lookup_model_break:
	;; we're addressing 2-byte words
	shl	BX,	1
	mov	DX,	MODEL_TAB[BX]

	pop	BX
	ret
LOOKUP_MODEL ENDP

NEWLINE PROC
	push	DX
	mov	DX,	OFFSET NEWLINE_STRING
	mov	AH,	09h
	int	21h
	pop	DX
	ret
NEWLINE ENDP

PRINT_MODEL PROC
	push	DX

	;; assume the model name is in DX
	mov	AH,	09h
	int	21h

	call	NEWLINE

	pop	DX
	ret
PRINT_MODEL ENDP

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

PRINT_VERSION_INFO PROC
	push	DX
	push	AX
	push	BP
	push	SI
	push	DI

	push	AX

	mov	DX,	OFFSET DOS_VERSION_STRING
	mov	AH,	09h
	int	21h

	pop	AX

	;; reserver max buffer we're going to need
	sub	SP,	7
	mov	BP,	SP

	;; print first line
	push	AX

	lea	SI,	[BP+2]
	mov	BYTE PTR [SI+1],	'$'
	call	BYTE_TO_DEC

	lea	DX,	[SI+1]
	mov	AH,	09h
	int	21h

	mov	AH,	02h
	mov	DL,	'.'
	int	21h

	pop	AX

	mov	AL,	AH
	lea	SI,	[BP+2]
	call	BYTE_TO_DEC

	lea	DX,	[SI+1]
	mov	AH,	09h
	int	21h

	call	NEWLINE

	;; print second line
	mov	DX,	OFFSET OEM_NUMBER_STRING
	mov	AH,	09h
	int	21h

	mov	AL,	BH
	call	BYTE_TO_HEX

	push	AX
	mov	DL,	AL
	mov	AH,	02h
	int	21h

	pop	AX
	mov	DL,	AH
	mov	AH,	02h
	int	21h

	call	NEWLINE

	;; print third line
	mov	DX,	OFFSET USER_SERIAL_STRING
	mov	AH,	09h
	int	21h

	lea	SI,	[BP+5]
	mov	BYTE PTR [SI+1],	'$'
	mov	DI,	SI
	mov	AX,	CX
	call	WRD_TO_HEX

	mov	AL,	BL
	call	BYTE_TO_HEX
	mov	[SI-5],	AL
	mov	[SI-4],	AH

	mov	DX,	BP
	mov	AH,	09h
	int	21h

	call	NEWLINE

	add	SP,	7

	pop	DI
	pop	SI
	pop	BP
	pop	AX
	pop	DX
	ret
PRINT_VERSION_INFO ENDP

MAIN PROC FAR
	push	DS
	xor	AX,	AX
	push	AX

	mov	AX,	DATA
	mov	DS,	AX

	;; AX <- 0F000:0FFFEh
	push	DS
	mov	AX,	0F000h
	mov	DS,	AX
	mov	BX,	0FFFEh
	mov	AL,	BYTE PTR [BX]
	pop	DS

	;; DX <- model name string offset (rel. to DS)
	call	LOOKUP_MODEL

	call	PRINT_MODEL

	;; AL == 00h => return OEM number
	;; AL <- DOS version major
	;; AH <- DOS version minor
	;; BL:CX <- `user serial number'
	;; BH <- MS-DOS OEM number
	mov	AX,	3000h
	int	21h

	call	PRINT_VERSION_INFO

	ret
MAIN ENDP

TEXT ENDS

	END MAIN
