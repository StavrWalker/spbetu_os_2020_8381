;;; -*- indent-tabs-mode: t; tab-width: 8; electric-quote-mode: nil -*-

TEXT SEGMENT
	ASSUME CS:TEXT, DS:TEXT
	ORG 100h

START:
	jmp	MAIN


NEWLINE_STRING		DB	13,10,"$"
ERROR_STRING		DB	"ERROR",13,10,"$"
BYTES_STRING		DB	" bytes$"
ELLIPSIS_STR		DB	"...$"
AVAIL_MEM_STRING	DB	"Available memory: $"
EXTENDED_MEM_STRING	DB	"Extended memory: $"
WRITE_MEM_FIELD_AT	DB	"(at seg: $"
WRITE_MEM_FIELD_WHO	DB	" who: $"
WRITE_MEM_FIELD_KNOWN	DB	" known: ",22h,"$"
WRITE_MEM_FIELD_SIZE	DB	" size: $"
WRITE_MEM_FIELD_NAME	DB	" name: ",22h,"$"
WRITE_MEM_END_RECORD	DB	22h,")$"
WRITE_MEM_NEXT_RECORD	DB	13,10," $"

CHANGE_BLOCK_LENGTH_STR	DB	"Changing our memory block length to $"

MEM_BLOCK_OWNER_FREE		DB	"Free$"
MEM_BLOCK_OWNER_OS_XMS		DB	"OS XMS$"
MEM_BLOCK_OWNER_DRIVER_UMB	DB	"Driver upper memory$"
MEM_BLOCK_OWNER_MS_DOS		DB	"MS-DOS$"
MEM_BLOCK_OWNER_386MAX_CB	DB	"386MAX control block$"
MEM_BLOCK_OWNER_386MAX_LOCKED	DB	"386MAX locked$"
MEM_BLOCK_OWNER_386MAX		DB	"386MAX$"

MEM_BLOCK_OWNER_NAMES	DW	OFFSET MEM_BLOCK_OWNER_FREE
			DW	OFFSET MEM_BLOCK_OWNER_OS_XMS
			DW	OFFSET MEM_BLOCK_OWNER_DRIVER_UMB
			DW	OFFSET MEM_BLOCK_OWNER_MS_DOS
			DW	OFFSET MEM_BLOCK_OWNER_386MAX_CB
			DW	OFFSET MEM_BLOCK_OWNER_386MAX_LOCKED
			DW	OFFSET MEM_BLOCK_OWNER_386MAX

MEM_BLOCK_OWNER_CODES	DW	 0000h,  0006h,  0007h,  0008h
			DW	0FFFAh, 0FFFDh, 0FFFEh
MEM_BLOCK_OWNERS_2COUNT	EQU	($ - MEM_BLOCK_OWNER_CODES)



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

;;; Two word: DX:AX (not all range valid)
;;; Dest: ES:DI (NOT saved)
TWO_WORDS_TO_DEC PROC
	push	AX
	push	BX
	push	CX
	push	DX
	push	SI

	mov	BX,	10000
	div	BX
	;; (tw) = AX * 10000 + DX

	push	DX

	xor	CX,	CX
	mov	SI,	10

two_words_to_dec_enter:
	xor	DX,	DX
	div	BX
	;; AX: quot, DX: rem

	test	AX,	AX
	jnz	two_words_to_dec_nonzero

	test	CX,	80h
	jz	two_words_to_dec_skip

two_words_to_dec_nonzero:
	or	CX,	80h
	add	AL,	'0'
	stosb

two_words_to_dec_skip:
	mov	AX,	DX
	xchg	AX,	BX

	xor	DX,	DX
	div	SI

	xchg	AX,	BX

	test	BX,	BX
	jnz	two_words_to_dec_enter

	test	CX,	40h
	jnz	two_words_to_dec_exit

	or	CX,	40h
	pop	AX
	mov	BX,	1000
	jmp	two_words_to_dec_enter

two_words_to_dec_exit:
	test	CX,	80h
	jnz	two_words_to_dec_ret

	mov	AL,	'0'
	stosb

two_words_to_dec_ret:
	pop	SI
	pop	DX
	pop	CX
	pop	BX
	pop	AX
	ret
TWO_WORDS_TO_DEC ENDP

;;; Write AX
WRITE_HEXWRD PROC
	push	AX
	push	BP
	push	DX
	push	DI

	;; allocate 5 bytes (1 word in hex + `$')
	sub	SP,	5
	mov	BP,	SP

	lea	DI,	[BP+3]
	mov	BYTE PTR [DI+1],	'$'
	call	WRD_TO_HEX

	mov	DX,	BP
	call	WRITE_STR

	add	SP,	5
	pop	DI
	pop	DX
	pop	BP
	pop	AX
	ret
WRITE_HEXWRD ENDP

;;; DS:SI: address
;;; BX: max length
;;; returns into CX
STRNLEN PROC
	push	AX
	push	SI

	xor	CX,	CX

strnlen_enter:
	cmp	CX,	BX
	je	strnlen_exit
	lodsb
	test	AL,	AL
	jz	strnlen_exit

	inc	CX
	jmp	strnlen_enter

strnlen_exit:

	pop	SI
	pop	AX
	ret
STRNLEN ENDP

;;; DS:SI: address
;;; CX: length
WRITE_BUFFER PROC
	push	AX
	push	CX
	push	DX
	push	SI

write_n_bytes_enter:
	test	CX,	CX
	jz	write_n_bytes_exit
	dec	CX

	lodsb
	mov	DL,	AL
	mov	AH,	02h
	int	21h

	jmp	write_n_bytes_enter

write_n_bytes_exit:
	pop	SI
	pop	DX
	pop	CX
	pop	AX
	ret
WRITE_BUFFER ENDP

;;; AX: paragraphs
WRITE_DEC_BYTES PROC
	push	AX
	push	DI
	push	DX
	;; TWO_WORDS_TO_DEC supports numbers up to 655359999
	sub	SP,	10

	mov	DX,	AX
	mov	CL,	12
	shr	DX,	CL

	mov	CL,	4
	shl	AX,	CL

	mov	DI,	SP

	push	ES
	push	SS
	pop	ES
	call	TWO_WORDS_TO_DEC

	mov	AL,	'$'
	stosb
	pop	ES

	mov	DX,	SP
	call	WRITE_STR

	mov	DX,	OFFSET BYTES_STRING
	call	WRITE_STR

	add	SP,	10
	pop	DX
	pop	DI
	pop	AX
	ret
WRITE_DEC_BYTES ENDP



WRITE_AVAIL_MEM PROC
	push	AX
	push	BX
	push	DX

	mov	AH,	4Ah
	mov	BX,	0FFFFh
	int	21h
	;; BX = avail mem in paragraphs

	mov	DX,	OFFSET AVAIL_MEM_STRING
	call	WRITE_STR

	mov	AX,	BX
	call	WRITE_DEC_BYTES
	call	NEWLINE

	pop	DX
	pop	BX
	pop	AX
	ret
WRITE_AVAIL_MEM ENDP

WRITE_EXTENDED_MEM PROC
	push	AX
	push	BX
	push	DX

	mov	AL,	30h
	out	70h,	AL
	in	AL,	71h
	mov	BL,	AL

	mov	AL,	31h
	out	70h,	AL
	in	AL,	71h
	mov	BH,	AL

	mov	DX,	OFFSET EXTENDED_MEM_STRING
	call	WRITE_STR

	mov	AX,	BX
	call	WRITE_DEC_BYTES

	call	NEWLINE

	pop	DX
	pop	BX
	pop	AX
	ret
WRITE_EXTENDED_MEM ENDP

;;; AX: owner PSP addr
;;; returns into DX
MEM_BLOCK_LOOKUP_OWNER PROC
	push	BX
	push	SI

	xor	SI,	SI

mem_block_lookup_owner_enter:
	cmp	SI,	OFFSET MEM_BLOCK_OWNERS_2COUNT
	je	mem_block_lookup_owner_unknown

	mov	BX,	MEM_BLOCK_OWNER_CODES[SI]
	cmp	AX,	BX
	je	mem_block_lookup_owner_found

	add	SI,	2
	jmp	mem_block_lookup_owner_enter

mem_block_lookup_owner_found:
	mov	DX,	MEM_BLOCK_OWNER_NAMES[SI]
	jmp	mem_block_lookup_owner_ret

mem_block_lookup_owner_unknown:
	xor	DX,	DX

mem_block_lookup_owner_ret:
	pop	SI
	pop	BX
	ret
MEM_BLOCK_LOOKUP_OWNER ENDP

WRITE_MEM_BLOCKS PROC
	push	AX
	push	BX
	push	DX
	push	SI
	push	DI
	push	ES

	;; Get List of Lists (undocumented)
	mov	AH,	52h
	int	21h

	;; ES:BX points into middle of structure, offset < 0 is ok.
	mov	DI,	WORD PTR ES:[BX-2]

	mov	DL,	'('
	mov	AH,	02h
	int	21h

write_mem_blocks_enter:
	;; at seg:
	mov	DX,	OFFSET WRITE_MEM_FIELD_AT
	call	WRITE_STR

	mov	AX,	DI
	call	WRITE_HEXWRD

	;; who:
	mov	DX,	OFFSET WRITE_MEM_FIELD_WHO
	call	WRITE_STR

	;; ES <- current mem segment addr
	mov	ES,	DI

	mov	AX,	WORD PTR ES:[01h]
	call	WRITE_HEXWRD

	;; (WRITE_HEXWRD saves AX)
	;; maybe we know the address in AX is a special value?
	call	MEM_BLOCK_LOOKUP_OWNER
	test	DX,	DX
	jz	write_mem_blocks_no_owner

	;; save name; known:
	push	DX
	mov	DX,	OFFSET WRITE_MEM_FIELD_KNOWN
	call	WRITE_STR

	;; restore name and write it
	pop	DX
	call	WRITE_STR

	mov	DL,	22h	; double quote
	mov	AH,	02h
	int	21h

write_mem_blocks_no_owner:

	;; size:
	mov	DX,	OFFSET WRITE_MEM_FIELD_SIZE
	call	WRITE_STR

	mov	AX,	WORD PTR ES:[03h]
	call	WRITE_DEC_BYTES

	;; (WRITE_DEC_BYTES saves AX)
	;; move forward past this header + following mem area size
	add	DI,	AX
	inc	DI

	;; name:
	mov	DX,	OFFSET WRITE_MEM_FIELD_NAME
	call	WRITE_STR

	;; save DS; DS <- ES, for LODSB in string funcs
	push	DS
	push	ES
	pop	DS

	;; STRNLEN(length(BX)=8, str(ES:SI)=ES:0008h)
	mov 	SI,	08h
	mov	BX,	08h
	call	STRNLEN
	;; STRNLEN returns into CX
	call	WRITE_BUFFER

	;; restore usual value of DS
	pop	DS

	mov	DX,	OFFSET WRITE_MEM_END_RECORD
	call	WRITE_STR

	;; done, now decide whether to continue
	mov	AL,	BYTE PTR ES:[00h]
	cmp	AL,	5Ah
	je	write_mem_blocks_exit

	cmp	AL,	4Dh
	jne	write_mem_blocks_error

	mov	DX,	OFFSET WRITE_MEM_NEXT_RECORD
	call	WRITE_STR

	jmp	write_mem_blocks_enter

write_mem_blocks_exit:
	mov	DL,	')'
	mov	AH,	02h
	int	21h

	jmp	write_mem_blocks_ret

write_mem_blocks_error:
	mov	DX,	OFFSET ERROR_STRING
	call	WRITE_STR

write_mem_blocks_ret:
	pop	ES
	pop	DI
	pop	SI
	pop	DX
	pop	BX
	pop	AX
	ret
WRITE_MEM_BLOCKS ENDP

CHANGE_BLOCK_LENGTH PROC
	push	BX
	push	DX

	mov	DX,	OFFSET CHANGE_BLOCK_LENGTH_STR
	call	WRITE_STR

	mov	AX,	BX
	call	WRITE_DEC_BYTES

	mov	DX,	OFFSET ELLIPSIS_STR
	call	WRITE_STR

	;; Stack goes from (our seg):0FFFEh
	mov	AH,	4Ah
	int	21h

	jc	change_block_length_error

	call	NEWLINE

	xor	AL,	AL
	jmp	change_block_length_ret

change_block_length_error:
	mov	DX,	OFFSET ERROR_STRING
	call	WRITE_STR
	mov	AL,	0FFh

change_block_length_ret:
	pop	DX
	pop	BX
	ret
CHANGE_BLOCK_LENGTH ENDP

MAIN PROC
	call	WRITE_AVAIL_MEM
	call	WRITE_EXTENDED_MEM

	;; We can't call this before WRITE_AVAIL_MEM because it uses the
	;; very same sys call to retrieve the total amount of available
	;; memory.
	mov	BX,	1000h
	call	CHANGE_BLOCK_LENGTH
	test	AL,	AL
	jnz	main_exit_1

	call	WRITE_MEM_BLOCKS

	mov	AX,	4C00h
	int	21h

main_exit_1:
	mov	AX,	4C01h
	int	21h
MAIN ENDP

TEXT ENDS
END START
