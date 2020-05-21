;;; -*- indent-tabs-mode: t; tab-width: 8; electric-quote-mode: nil -*-

.186

RESIDENT SEGMENT
	ASSUME	CS:RESIDENT, SS:NOTHING, ES:NOTHING, DS:NOTHING

SIGNATURE		DB	229,174,129,233,157,153
SIGNATURE_LENGTH	EQU	$ - SIGNATURE

;;; Variables
SAVED_CS	DW	?
SAVED_IP	DW	?
COUNTER		DW	0

;;; Write decimal repr of word in AX at ES:DI (not saved)
;;; The number is aligned to the right. The max length of a 16-bit
;;; number in decimal is 5 digits (65535), so this procedure always
;;; writes exactly 5 bytes.
;;; Clears DF.
WRD2DEC_RJUST PROC
	push	AX
	push	BX
	push	CX
	push	DX
	push	SI

	cld

	xor	CX,	CX
	mov	SI,	10
	mov	BX,	10000

wrd2dec_rjust_enter:
	xor	DX,	DX
	div	BX
	;; AX: quot, DX: rem

	;; Looking at nonzero digit?
	test	AX,	AX
	jnz	wrd2dec_rjust_nonzero

	;; Looking at zero, but it's the last digit?
	cmp	BX,	1
	je	wrd2dec_rjust_nonzero

	;; Looking at zero, it's not the last digit, and seen no
	;; non-zero digits before?
	test	CX,	80h
	jz	wrd2dec_rjust_skip

wrd2dec_rjust_nonzero:
	or	CX,	80h
	add	AL,	'0'
	jmp	wrd2dec_rjust_write

wrd2dec_rjust_skip:
	mov	AL,	' '

wrd2dec_rjust_write:
	stosb

	;; Remember what's left of the number.
	mov	AX,	DX

	;; Now divide the current power of 10 by 10.
	xchg	AX,	BX
	xor	DX,	DX
	div	SI
	xchg	AX,	BX

	;; Any digits left?
	test	BX,	BX
	jnz	wrd2dec_rjust_enter

wrd2dec_rjust_ret:
	pop	SI
	pop	DX
	pop	CX
	pop	BX
	pop	AX
	ret
WRD2DEC_RJUST ENDP

;;; ES:BP: STRING
;;; CX: LENGTH
;;; DH,DL: ROW,COL
;;; BX: ATTRIBUTE (COLOR)
DISPLAY_STRING PROC
	push	AX

	mov	AX,	1300h
	int	10h

	pop	AX
	ret
DISPLAY_STRING ENDP

ISR1C PROC
	pusha
	push	DS
	push	ES
	pushf

	ASSUME	CS:RESIDENT, DS:RESIDENT, ES:NOTHING
	push	CS
	pop	DS
	;; Note: it's not the same stack we use outside of the interrupt
	;; handler.
	push	SS
	pop	ES

	sub	SP,	5

	mov	AX,	COUNTER
	inc	COUNTER

	mov	DI,	SP
	call	WRD2DEC_RJUST

	mov	CX,	5
	mov	BP,	SP

	mov	DX,	004Bh
	mov	BX,	0Eh
	call	DISPLAY_STRING

	add	SP,	5

	;; allow lower priority interrupts
	mov	AL,	20h
	out	20h,	AL

	popf
	pop	ES
	pop	DS
	popa
	iret
ISR1C ENDP

RESIDENT ENDS

STACK_SIZE	EQU	40h

STACK SEGMENT STACK
	DW	STACK_SIZE DUP(?)
STACK ENDS

STRINGS SEGMENT

NEWLINE_STRING		DB	13,10,"$"

UNINSTALL		DB	" /un"
UNINSTALL_LENGTH	EQU	$ - UNINSTALL

MSG_NOT_INSTALLED	DB	"Error: not installed",13,10,"$"
MSG_ALREADY_INSTALLED	DB	"Error: already installed",13,10,"$"
MSG_BAD_CMDLINE		DB	"Error: unrecognized command",13,10,"$"
MSG_RESIDENT_FAILED	DB	"Error: program not terminated",13,10,"$"
MSG_DETECTED		DB	"Detected the ISR",13,10,"$"
MSG_49H_ERROR		DB	"49h ERROR: $"
MSG_49H_ERROR_ADDR	DB	" ADDR: $"

STRINGS ENDS

TEXT SEGMENT
	ASSUME CS:TEXT, SS:STACK, DS:NOTHING, ES:NOTHING

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

;;; Write AX
WRITE_HEXWRD PROC
	push	AX
	push	BP
	push	DX
	push	DI

	push	DS
	push	SS
	pop	DS

	;; allocate 5 bytes (1 word in hex + `$')
	sub	SP,	5
	mov	BP,	SP

	lea	DI,	[BP+3]
	mov	BYTE PTR [DI+1],	'$'
	call	WRD_TO_HEX

	mov	DX,	BP
	call	WRITE_STR

	add	SP,	5
	pop	DS

	pop	DI
	pop	DX
	pop	BP
	pop	AX
	ret
WRITE_HEXWRD ENDP

;;; Compare DS:SI with ES:DI (max CX bytes).
;;; Return into AL:
;;; 1 if equal, else 0
STREQ PROC
	push	SI
	push	DI
	push	CX

	mov	AL,	1
	;; Main action: `repeat compare string bytes while equal'
	repe cmpsb

	;; CX == 0 => strings equal, return 0
	jcxz	streq_ret

	;; strings differ, return 0
	xor	AL,	AL

streq_ret:
	pop	CX
	pop	DI
	pop	SI
	ret
STREQ ENDP

;;; ES: supposed resident (whom we're checking)
;;; => AL: 1 if matches, else 0
CHECK_SIGNATURE PROC
	push	DS
	push	SI
	push	DI

	ASSUME	DS:RESIDENT
	mov	AX,	RESIDENT
	mov	DS,	AX
	mov	SI,	OFFSET SIGNATURE

	mov	DI,	SI
	mov	CX,	SIGNATURE_LENGTH
	call	STREQ

	ASSUME	DS:NOTHING
	pop	DI
	pop	SI
	pop	DS
	ret
CHECK_SIGNATURE ENDP

;;; ES: PSP segment addr
;;; Checks whether cmdline says ` /un'
;;; => AL: 1 if /un, else 0
CHECK_CMDLINE PROC
	push	DS
	push	SI
	push	DI

	;; 81h: start of command line tail in PSP
	mov	DI,	81h

	mov	AL,	ES:[DI-1]
	;; If cmdline tail empty, return 0
	test	AL,	AL
	jz	check_cmdline_ret

	cmp	AL,	UNINSTALL_LENGTH
	jne	check_cmdline_false

	mov	CX,	UNINSTALL_LENGTH

	ASSUME	DS:STRINGS
	mov	AX,	STRINGS
	mov	DS,	AX
	mov	SI,	OFFSET UNINSTALL
	;; ES:DI is still PSP:81h
	call	STREQ
	test	AL,	AL
	jnz	check_cmdline_ret

	;; -1 instead of 0: cmdline not recognized
check_cmdline_false:
	mov	AL,	-1

check_cmdline_ret:
	ASSUME	DS:NOTHING
	pop	DI
	pop	SI
	pop	DS
	ret
CHECK_CMDLINE ENDP

;;; AX:DX: interrupt vector
SET_ISR1C PROC
	push	AX
	push	DS

	mov	DS,	AX
	mov	AX,	251Ch
	int	21h

	pop	DS
	pop	AX
	ret
SET_ISR1C ENDP

;;; AX: seg address to pass to int 21h, AH=49h
FREE PROC
	push	AX
	push	ES

	mov	ES,	AX
	mov	AH,	49h
	int	21h
	jnc	free_ok

	;; Report an error. Most likely it's 0009h -- invalid seg addr.
	;; Note: pushf/popf allows the caller to use the same jc/jnc.
	pushf
	push	DX

	;; Don't assume DS is set correctly.
	push	DS
	mov	DX,	STRINGS
	mov	DS,	DX

	mov	DX,	OFFSET MSG_49H_ERROR
	call	WRITE_STR
	call	WRITE_HEXWRD
	mov	DX,	OFFSET MSG_49H_ERROR_ADDR
	call	WRITE_STR
	mov	AX,	ES
	call	WRITE_HEXWRD
	call	NEWLINE

	pop	DS
	pop	DX
	popf
free_ok:

	pop	ES
	pop	AX
	ret
FREE ENDP



;;; Actions. On enter:
;;; - ES:BX: current ISR handler
;;; - DS: STRINGS

;;; BP: PSP seg address' address
;;; Doesn't return error codes
INSTALL_ISR PROC
	push	AX
	push	BX
	push	DX
	push	DS

	;; Free the env memory block
	mov	AX,	[BP]
	mov	DS,	AX

	mov	AX,	WORD PTR DS:[2Ch]
	call	FREE
	;; Exit immediately on failure
	jc	install_isr_exit

	ASSUME	DS:RESIDENT
	mov	AX,	RESIDENT
	mov	DS,	AX

	;; Remember old handler (ES:BX)
	mov	SAVED_CS,	ES
	mov	SAVED_IP,	BX

	;; Note: uses AX from above, which should contain RESIDENT
	;; segment address.
	mov	AX,	RESIDENT
	mov	DX,	OFFSET DS: ISR1C
	call	SET_ISR1C

	;; After RESIDENT goes the stack, so we use its seg address
	;; instead of calculating the end of RESIDENT.
	mov	DX,	STACK
	;; The PSP is also kept, so we count from the PSP segment.
	sub	DX,	[BP]

	;; Remain resident
	mov	AX,	3100h
	int	21h

	;; We should've been terminated by now. If we're still running,
	;; it's an error. This syscall *shouldn't* fail, but who knows?
	push	DS
	ASSUME	DS:STRINGS
	mov	AX,	STRINGS
	mov	DS,	AX

	mov	DX,	OFFSET MSG_RESIDENT_FAILED
	call	WRITE_STR

	pop	DS

install_isr_exit:
	ASSUME	DS:NOTHING
	pop	DS
	pop	DX
	pop	BX
	pop	AX
	ret
INSTALL_ISR ENDP

UNINSTALL_ISR PROC
	push	AX
	push	DX

	;; Restore old handler
	mov	AX,	ES: SAVED_CS
	mov	DX,	ES: SAVED_IP
	call	SET_ISR1C

	;; Free the process' only remaining memory block.
	mov	AX,	ES
	;; Subtract PSP size in paragraphs.
	sub	AX,	10h
	call	FREE

	pop	DX
	pop	AX
	ret
UNINSTALL_ISR ENDP

ERROR_ALREADY_INSTALLED PROC
	push	DX
	mov	DX,	OFFSET MSG_ALREADY_INSTALLED
	call	WRITE_STR
	pop	DX
	ret
ERROR_ALREADY_INSTALLED ENDP

ERROR_NOT_INSTALLED PROC
	push	DX
	mov	DX,	OFFSET MSG_NOT_INSTALLED
	call	WRITE_STR
	pop	DX
	ret
ERROR_NOT_INSTALLED ENDP

ERROR_BAD_CMDLINE PROC
	push	DX
	mov	DX,	OFFSET MSG_BAD_CMDLINE
	call	WRITE_STR
	pop	DX
	ret
ERROR_BAD_CMDLINE ENDP



ACTIONS_TAB	DW	OFFSET INSTALL_ISR
		DW	OFFSET ERROR_ALREADY_INSTALLED
		DW	OFFSET ERROR_NOT_INSTALLED
		DW	OFFSET UNINSTALL_ISR
		DW	OFFSET ERROR_BAD_CMDLINE

MAIN PROC
	;; Prepare for RETF, and also remember in BP where to get PSP
	;; segment address.
	push	DS
	mov	BP,	SP
	xor	AX,	AX
	push	AX

	;; Query current isr => ES:BX
	mov	AX,	351Ch
	int	21h
	push	BX
	push	ES

	;; Does ES:BX look like our handler
	call	CHECK_SIGNATURE
	push	AX

	;; Go to our PSP segment
	mov	BX,	[BP]
	mov	ES,	BX
	call	CHECK_CMDLINE

	test	AL,	AL
	jns	main_cmdline_ok

	;; Unrecognized cmdline
	pop	AX
	mov	BX,	4
	jmp	main_run_action

main_cmdline_ok:
	;; BL <- BL*2 + old AL
	mov	BL,	AL
	add	BL,	BL
	pop	AX
	add	BL,	AL
	;; We've got a number 0..3 in AL now. It means:
	;; BL = ((SIG MATCHES) << 0)
	;;    + ((UNINSTALL)   << 1)
	;; BL = 0: install
	;;      1: err: already installed
	;;      2: err: not installed
	;;      3: uninstall
	;; See ACTIONS_TAB above
	xor	BH,	BH

main_run_action:
	shl	BX,	1
	mov	SI,	BX

	pop	ES
	pop	BX

	mov	AX,	STRINGS
	mov	DS,	AX

	;; Main action happens here
	call	ACTIONS_TAB[SI]

	retf
MAIN ENDP

TEXT ENDS

	END MAIN
