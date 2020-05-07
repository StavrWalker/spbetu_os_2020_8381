ASTACK  SEGMENT STACK
    DW  128 dup(0)
ASTACK  ENds

DATA    SEGMENT
	loaded_str     DB  "Interruption has been already loaded.", 10, 13,"$"
	not_loaded_str		DB  "Interruption is not loaded.", 10, 13,"$"
    bool_isLoaded          DB  0
    UN_CL               DB  0
DATA    ENds

CODE    SEGMENT
	ASSUME  CS:CODE, ds:DATA, SS:ASTACK
	
print proc near
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
print endp
	
;вывод строки по адресу es:bp
outputBP proc
	push ax
	push bx 
	push dx
	push cx
	mov ah, 13h
	mov al, 0
	mov bl, 0Fh
	mov bh, 0
	mov dh, 22
	mov dl, 40
	mov cx, 15
	int 10h
	pop cx
	pop dx
	pop bx
	pop ax
	ret
outputBP endp
	
word_to_str proc near
	;на входе ax число 16 бит
	;si указатель на строку
	;bx разрядность результата
    push ax
	push bx
	push cx
	push dx
	push di
	push si
    cmp bx, 16
    ja end_wts
    cmp ax, 7FFFh
    jna plus
    mov byte ptr [si], '-'
    inc si
    not ax
    inc ax
    plus:
    	xor cx, cx
    	jmp process
    process:
    	xor dx, dx
      	div bx
      	mov di, ax
      	mov al, dl
      	cmp al, 10
      	sbb al, 69h
      	das
	  	push di
	  	lea di, temporary
	  	add di, cx
      	mov byte ptr [di], al
	  	pop di
      	mov ax, di
    inc cx
    test ax, ax
    jz endrep
    jmp process
    endrep:
    	lea di, temporary
      	add di, cx
    copyrep:
      	dec di
      	mov dl, byte ptr [di]
      	mov byte ptr [si], dl
      	inc si
      	loop copyrep
    end_wts:
    pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
    ret
word_to_str endp
	
ROUT    PROC    FAR
    jmp ROUT_BEGIN
    
	; rout data
	interrupts_str    DB  "Interrupts:    $"
	signature DW  1234h
	counter dw 0
	temporary db 16 dup(0)
	KEEP_IP 	DW  0
	KEEP_CS 	DW  0
	KEEP_PSP 	DW	0
    
    ROUT_BEGIN:
		push	ax
		push    bx
		push    cx
		push    dx
		push    si
        push    es
        push    ds
    STACK_SETUP:
		mov ax, seg interrupts_str
		mov ds, ax
		mov es, ax

	INCREASE:
		mov ax, counter
		inc ax
		mov counter, ax
		lea si, interrupts_str + 12
		mov bx, 10
		call word_to_str
		lea bp, interrupts_str
		call outputBP

	
		pop     ds
		pop     es
		pop		si
		pop     dx
		pop     cx
		pop     bx
		pop		ax

		mov     AL, 20h
		out     20h, AL
	iret
ROUT    ENDP
	LAST_BYTE:

ROUT_CHECK       PROC
	push    ax
	push    bx
	push    si
	
	mov     AH, 35h
	mov     AL, 1Ch
	int     21h
	mov     si, offset signature
	sub     si, offset ROUT
	mov     ax, es:[bx + si]
	cmp	    ax, signature
	jne     ROUT_CHECK_END
	mov     bool_isLoaded, 1
	
	ROUT_CHECK_END:
		pop     si
		pop     bx
		pop     ax
	ret
ROUT_CHECK       ENDP

ROUT_LOAD        PROC
        push    ax
		push    bx
		push    cx
		push    dx
		push    es
		push    ds

        mov     AH, 35h
		mov     AL, 1Ch
		int     21h
		mov     KEEP_CS, es
        mov     KEEP_IP, bx
        mov     ax, seg ROUT
		mov     dx, offset ROUT	
		mov     ds, ax
		mov     AH, 25h
		mov     AL, 1Ch
		int     21h
		pop		ds

        mov     dx, offset LAST_BYTE
		mov     CL, 4h
		shr     dx, CL
		add		dx, 10Fh
		inc     dx
		xor     ax, ax
		mov     AH, 31h
		int     21h

        pop     es
		pop     dx
		pop     cx
		pop     bx
		pop     ax
	ret
ROUT_LOAD        ENDP

ROUT_UNLOAD      PROC
        CLI
		push    ax
		push    bx
		push    dx
		push    ds
		push    es
		push    si
		
		mov     AH, 35h
		mov     AL, 1Ch
		int     21h
		mov 	si, offset KEEP_IP
		sub 	si, offset ROUT
		mov 	dx, es:[bx + si]
		mov 	ax, es:[bx + si + 2]
		
		push 	ds
		mov     ds, ax
		mov     AH, 25h
		mov     AL, 1Ch
		int     21h
		pop 	ds
		
		mov 	ax, es:[bx + si + 4]
		mov 	es, ax
		push 	es
		mov 	ax, es:[2Ch]
		mov 	es, ax
		mov 	AH, 49h
		int 	21h
		pop 	es
		mov 	AH, 49h
		int 	21h
		
		STI
		
		pop     si
		pop     es
		pop     ds
		pop     dx
		pop     bx
		pop     ax
		
	ret
ROUT_UNLOAD      ENDP

COMMAND_LINE_PARAM_CHECK        PROC
        push    ax
		push    es

		mov     ax, KEEP_PSP
		mov     es, ax
		cmp     byte ptr es:[82h], '/'
		jne     COMMAND_LINE_PARAM_CHECK_END
		cmp     byte ptr es:[83h], 'u'
		jne     COMMAND_LINE_PARAM_CHECK_END
		cmp     byte ptr es:[84h], 'n'
		jne     COMMAND_LINE_PARAM_CHECK_END
		mov     UN_CL, 1
		
	COMMAND_LINE_PARAM_CHECK_END:
		pop     es
		pop     ax
		ret
COMMAND_LINE_PARAM_CHECK        ENDP

MAIN PROC
		push    ds
		xor     ax, ax
		push    ax
		mov     ax, DATA
		mov     ds, ax
		mov     KEEP_PSP, es
		
		call    ROUT_CHECK
		call    COMMAND_LINE_PARAM_CHECK
		cmp     UN_CL, 1
		je      UNLOAD
		mov     AL, bool_isLoaded
		cmp     AL, 1
		jne     LOAD
		mov     dx, offset loaded_str
		call    print
		jmp     MAIN_END
	LOAD:
		call    ROUT_LOAD
		jmp     MAIN_END
	UNLOAD:
		cmp     bool_isLoaded, 1
		jne     CANT_UNLOAD
		call    ROUT_UNLOAD
		jmp     MAIN_END
	CANT_UNLOAD:
		mov     dx, offset not_loaded_str
		call    print
	MAIN_END:
		xor 	AL, AL
		mov 	AH, 4Ch
		int 	21h
	MAIN ENDP

CODE    ENds


END 	MAIN