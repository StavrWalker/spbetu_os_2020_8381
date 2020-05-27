;;; -*- indent-tabs-mode: t; tab-width: 8; electric-quote-mode: nil -*-

.186

RESIDENT SEGMENT
	ASSUME	CS:RESIDENT, SS:NOTHING, ES:NOTHING, DS:NOTHING

SIGNATURE		DB	229,174,129,233,157,153
SIGNATURE_LENGTH	EQU	$ - SIGNATURE

;;; Data and constant definitions

;;; +0: OFFSET (WORD)
;;; +2: SEGMENT (WORD)
SAVED_INTR	DD	?

;;; 0 => expecting init char code
;;; 1..3 => expecting octal digit
COUNTER			DB	0
COUNTER_AT_UP_MASK	EQU	80h

CHAR_CODE	DB	?

;; "`"
INIT_SCANCODE   EQU     29h
;;; Ctrl
MODIFIERS_ON	EQU	0004h
;; Ignore locks, locked insert and L/R Ctrl flag
MODIFIERS_IGN	EQU	0170h

ALT_STACK_SIZE	EQU	18h
ALT_STACK	DW	ALT_STACK_SIZE DUP (?)

;;; SS:SP of interrupted program
OLD_SS		DW	?
OLD_SP		DW	?

ONE_SCANCODE	EQU	02h
SEVEN_SCANCODE	EQU	ONE_SCANCODE + 6
ZERO_SCANCODE	EQU	ONE_SCANCODE + 9

;;; Code

;;; AL: scancode
;;; After return, ZF=1 means AL is the init key, else it isn't one
IS_INIT_KEY PROC
	cmp	AL,	INIT_SCANCODE
	jne	isnt_init_key

	push	BX
	push	DS

	;; BIOS keyboard driver state
	push	0040h
	pop	DS

	mov	BX,	DS:[0017h]
	and	BX,	NOT MODIFIERS_IGN
	cmp	BX,	MODIFIERS_ON

	pop	DS
	pop	BX

isnt_init_key:
	ret
IS_INIT_KEY ENDP

;;; AL: scancode
;;; Upon return, CF=1 => skip char, CL=0
HANDLE_KEY PROC
	push	AX
	push	CX

	cmp	COUNTER,	0
	jne	handle_key_digit
	;; COUNTER=0 => init (if init key) or skip

	call	IS_INIT_KEY
	jnz	handle_key_ret_skip

	mov	CHAR_CODE,	0
	inc	COUNTER

	clc
	jmp	handle_key_ret

	mov	CL,	0

handle_key_digit:
	;; should be an octal digit
	cmp	AL,	ZERO_SCANCODE
	je	handle_key_zero
	cmp	AL,	ONE_SCANCODE
	jb	handle_key_abort
	cmp	AL,	SEVEN_SCANCODE
	ja	handle_key_abort

	mov	CL,	AL
	sub	CL,	ONE_SCANCODE - 1

handle_key_zero:
	mov	CH,	8

	mov	AL,	CHAR_CODE
	mul	CH
	test	AH,	AH
	jnz	handle_key_ovf

	add	AL,	CL
	mov	CHAR_CODE,	AL

	inc	COUNTER

	cmp	COUNTER,	4
	jne	handle_key_ok

	mov	AH,	05h
	mov	CL,	CHAR_CODE
	mov	CH,	0
	int	16h
	;; Not checking overflow, we don't care. If we can't write the
	;; char right now, we won't be able to do this at all.

	mov	COUNTER,	0

handle_key_ok:
	clc
	jmp	handle_key_ret

handle_key_abort:
	mov	COUNTER,	0

handle_key_ret_skip:
	stc

handle_key_ret:
	pop	CX
	pop	AX

	ret

handle_key_ovf:
	;; Overflow => ignore the sequence. Don't set CF: we don't want
	;; to forward the last digit.
	mov	COUNTER,	0
	jmp	handle_key_ret
HANDLE_KEY ENDP

ISR09 PROC FAR
	mov	OLD_SS,	SS
	mov	OLD_SP,	SP

	mov	SP,	CS
	mov	SS,	SP
	mov	SP,	OFFSET ALT_STACK + 2*(ALT_STACK_SIZE-1)

	push	AX
	pushf

	test	COUNTER,	COUNTER_AT_UP_MASK
	jnz	isr09_skip_up_at

	;; read keycode into AL and print it into AX
	in	AL,	60h

	;; skip key-up events
	test	AL,	80h
	jnz	isr09_skip_up

	;; try to handle key
	call	HANDLE_KEY
	jc	isr09_skip

	;; finish handling the interrupt ourselves

	;; ack to keyboard
	in	AL,	61h
	mov	AH,	AL
	or	AL,	80h
	out	61h,	AL
	xchg	AL,	AH
	out	61h,	AL

	;; end of interrupt
	mov	AL,	20h
	out	20h,	AL

	;; prepare to leave, restore old stack
	popf
	pop	AX
	mov	SS,	OLD_SS
	mov	SP,	OLD_SP

	iret

isr09_skip_up_at:
	and	COUNTER,	NOT COUNTER_AT_UP_MASK

	jmp	isr09_skip

isr09_skip_up:
	;; Seems like there are no key codes beyond 58h, so we can't get
	;; this one as `0x70 released'.
	cmp	AL,	0F0h
	jne	isr09_skip

	;; On AT, release is sent as F0h, <scancode> instead of the
	;; usual (80h | <scancode). Can't test this, though.
	or	COUNTER,	COUNTER_AT_UP_MASK

isr09_skip:
	;; same as above
	popf
	pop	AX
	mov	SS,	OLD_SS
	mov	SP,	OLD_SP

	;; far indirect jump: read far pointer from CS:[...]
	jmp	CS:[SAVED_INTR]
ISR09 ENDP

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
	mov      AH,AL
	call     TETR_TO_HEX
	xchg     AL,AH
	;; shr AL,imm8 is OK since 80186
	shr      AL,4
	call     TETR_TO_HEX
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
SET_ISR09 PROC
	push	AX
	push	DS

	mov	DS,	AX
	mov	AX,	2509h
	int	21h

	pop	DS
	pop	AX
	ret
SET_ISR09 ENDP

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
	mov	WORD PTR SAVED_INTR+2,	ES
	mov	WORD PTR SAVED_INTR,	BX

	;; Note: uses AX from above, which should contain RESIDENT
	;; segment address.
	mov	AX,	RESIDENT
	mov	DX,	OFFSET DS: ISR09
	call	SET_ISR09

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
	mov	AX,	WORD PTR ES: SAVED_INTR+2
	mov	DX,	WORD PTR ES: SAVED_INTR
	call	SET_ISR09

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
	mov	AX,	3509h
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
