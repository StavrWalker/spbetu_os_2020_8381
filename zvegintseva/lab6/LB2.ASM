LB2		SEGMENT

ASSUME 	CS:LB2, DS:LB2, ES:NOTHING, SS:NOTHING;

ORG		100H

START:	JMP	BEGIN
; ДАННЫЕ
INACCESSIBLE_MEMORY         db      "Inaccessible memory adress:       ", 13, 10, "$"
ENVIRONMENT                 db      "Program environment adress:       ", 13, 10, "$"
TAIL_LINE                   db      "Command line tail: ", "$"
ENVIRONMENT_CONTENT         db      "Program environment content:", 13, 10, "$"
ENVIRONMENT_CONTENT_END     db      "Program environment content ended", 13, 10, "$"
PATH                        db      "Path:", 13, 10, "$"
NO_TAIL_STR                 db      "No command line tail", 13, 10, "$"
NEW_LINE                    db      13, 10, "$"
EMPTY_TAIL                  db      "NONE", "$"

; ПРОЦЕДУРЫ
PRINT  	PROC	near

   	PUSH	AX
   	MOV	    AH, 09H
    INT	    21H
	POP 	AX
    RET

PRINT  	ENDP
;-------------------------------------------------------------------------------
TETR_TO_HEX	PROC	near
;перевода половины байта в шестнадцатеричную систему счисления.
    and     AL, 0FH
    cmp 	AL, 09H
    jbe	    NEXT
  	add  	AL, 07H
NEXT:
   	add 	AL, 30H
    ret

TETR_TO_HEX	ENDP
;-------------------------------------------------------------------------------
BYTE_TO_HEX	PROC	near
; байт в AL переводится в два символа шестн. числа в AX
	push	CX
    mov		AH, AL
    call	TETR_TO_HEX
    xchg	AL, AH
    mov		CL, 4H
    shr		AL, CL
    call	TETR_TO_HEX	; AL старшая цифра
    pop		CX			; в AH младшая
    ret

BYTE_TO_HEX	ENDP
;-------------------------------------------------------------------------------
WRD_TO_HEX	PROC	near
; перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
;результат в di

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

WRD_TO_HEX	ENDP
;-------------------------------------------------------------------------------
BYTE_TO_DEC	PROC	near
; перевод в 10 с/с, SI - адрес поля младшей цифры
; al ->  si
  	push     CX
  	push     DX
  	xor      AH, AH
  	xor      DX, DX
  	mov      CX, 0AH
LOOP_BD:
	div      CX
  	or       DL, 30H
  	mov      [SI], DL
	dec      SI
  	xor      DX, DX
  	cmp      AX, 0AH
  	jae      LOOP_BD
  	cmp      AL, 00H
  	je       END_L
  	or       AL, 30H
  	mov      [SI], AL
END_L:
	pop	     DX
  	pop	     CX
	ret

BYTE_TO_DEC	ENDP

NONE PROC near
    mov dx, offset EMPTY_TAIL
    call PRINT
    jmp NO_TAIL
NONE ENDP

; КОД
BEGIN:
;сегментный адрес недоступной памяти
    mov di, offset INACCESSIBLE_MEMORY
    add di, 32

    mov bx,2h
    mov ax, [bx]

    call  WRD_TO_HEX
    mov dx, offset INACCESSIBLE_MEMORY
    call PRINT
;сегментный адрес среды
    mov di, offset ENVIRONMENT
    add di, 32

    mov bx,2Ch
    mov ax, [bx]

    call  WRD_TO_HEX
    mov dx, offset ENVIRONMENT
    call PRINT
;хвост командной строки
    mov dx, offset TAIL_LINE
    call PRINT

    mov bx, 80h
    mov ch, 0
    mov cl, [bx]

    cmp cl, 0

    je NONE

    mov bx, 81h
    mov ah, 02h
TAIL_LOOP:
    mov dl, [bx]
    int 21h
    inc bx
    loop TAIL_LOOP
NO_TAIL:
    mov dx, offset NEW_LINE
    call PRINT
;содержимое обрасти среды
    mov dx, offset ENVIRONMENT_CONTENT
    call PRINT

    mov bx, 2Ch
    mov es, [bx]

    xor si,si
    xor ax,ax
    mov dx, offset NEW_LINE
LINE_PRINT:
    mov al, es:[si]
    cmp al, 0
    jne LINE_SYMB_PRINT
    mov dx, offset NEW_LINE
    call PRINT
LINE_SYMB_PRINT:
    mov dl, al
    xor ax, ax
    mov ah, 02h
    int 21h
    inc si
    mov ax, es:[si]
    cmp ax, 0001h
    je LINE_END
    jmp LINE_PRINT
LINE_END:
    mov dx, offset ENVIRONMENT_CONTENT_END
    call PRINT
;путь загружаемого модуля
PATH_PRINT:
    mov dx, offset PATH
    call PRINT
    add si, 2

PATH_SYMB_PRINT:
    mov al, es:[si]
    cmp al, 0
    je ENDGAME
    mov dl, al
    mov ah, 02h
    int 21h
    inc si
    jmp PATH_SYMB_PRINT

ENDGAME:
    mov dx, offset NEW_LINE
    call PRINT
    xor al,al
    mov ah, 01h
    int 21h

    mov ah, 4Ch
    int 21h

LB2		ENDS
END 		START
