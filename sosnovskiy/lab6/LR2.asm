TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG 100H

START: JMP SEGMENT_ADDRESS_OF_UNAVAILABLE_MEMORY

unavailable_memory db 'Segment address of unavailable memory:     ', 13, 10, '$'
environment db 'Segment address of environment:     ', 13, 10, '$'
command_line_tail db 'Tail of command line:            ', 13, 10, '$'
no_command_line_tail_string db 'Tail of command line: no tail', 13, 10, '$'
environment_content_str db 'Environment content: ', 13, 10, '$'
new_line db 13, 10, '$'
path db 'Path: '

;è•‡•¢Æ§ ¨•¶§„ ·.·Á.
tetr_to_hex	proc near
	and	al, 0fh
	cmp al, 09
	jbe	next
	add	al, 07
	next: add al, 30h
	ret
tetr_to_hex	endp

byte_to_hex	proc near
	push cx
	mov	al, ah
	call tetr_to_hex
	xchg al, ah
	mov	cl, 4
	shr	al, cl
	call tetr_to_hex 
	pop	cx 			
	ret
byte_to_hex	endp

word_to_hex	proc near
	push bx
	mov	bh, ah
	call byte_to_hex
	mov [di], ah
	dec	di
	mov [di], al
	dec	di
	mov	al, bh
	xor	ah, ah
	call byte_to_hex
	mov	[di], ah
	dec	di
	mov	[di], al
	pop	bx
	ret
word_to_hex	endp

byte_to_dec	proc near
	push cx
	push dx
	push ax
	xor	ah, ah
	xor	dx, dx
	mov	cx, 10
loop_bd: 
	div	cx
	or dl, 30h
	mov	[si], dl
	dec	si
	xor	dx, dx
	cmp	ax, 10
	jae	loop_bd
	cmp	ax, 00h
	jbe	end_l
	or al, 30h
	mov	[si], al
end_l:	
	pop	ax
	pop	dx
	pop	cx
	ret
byte_to_dec	endp

print proc near
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
print endp


SEGMENT_ADDRESS_OF_UNAVAILABLE_MEMORY:
	mov ax, ds:[02h] ;segment address of unavailable memory at PSP
	
	mov di, offset unavailable_memory + 42 
	call word_to_hex
	mov dx, offset unavailable_memory
	call print

SEGMENT_ADDRESS_OF_ENVIRONMENT:
	mov ax, ds:[2Ch]; segment address of environment
	
	mov di, offset environment + 35
	call word_to_hex
	mov dx, offset environment
	call print
	
TAIL_OF_COMMAND_LINE:
	mov cl, ds:[80h]
	
	mov di, offset command_line_tail + 21
	
	cmp cl, 0
	je ZERO_TAIL_OF_COMMNAND_LINE
	
NON_ZERO_TAIL_OF_COMMAND_LINE:	
	mov si, 0
	copying_cycle:
		mov al, ds:[81h + si]
		mov [di], al
		inc si
		inc di
		loop copying_cycle
	
	mov dx, offset command_line_tail
	call print
	jmp ENVIRONMENT_CONTENT
	
ZERO_TAIL_OF_COMMNAND_LINE:
	mov dx, offset no_command_line_tail_string
	call print
	
ENVIRONMENT_CONTENT:
	mov dx, offset environment_content_str
	call print
	
	mov bx, 2Ch
	mov es, [bx]
	mov si, 0
	mov dx, offset new_line

	CONTENT_LINE:	
		mov al, es:[si]
		cmp al, 00h
		jne CONTENT_LINE_ELEMENT
		mov dx, offset new_line
		call print
	CONTENT_LINE_ELEMENT:
		mov dl, al
		mov ax, 0
		mov ah, 02h
		int 21h
		inc si
		mov ax, es:[si]
		cmp ax, 0001h
		je PATH_OF_MODULE 
		jmp CONTENT_LINE
		
PATH_OF_MODULE:
	mov dx, offset path
	call print
	add si, 2
	
	PATH_ELEMENT:
		mov al, es:[si]
		cmp al, 0
		je ENDING
		mov dl, al
		mov ah, 02h
		int 21h
		inc si
		jmp PATH_ELEMENT

ENDING:
	pop di
	pop si
	pop dx
	pop	ax
	xor al, al
	
	mov dx, offset new_line
	call print
	
	;åéÑÖêçàáÄñàü		
	MOV 	AH, 01H
	INT		21H
	MOV 	AH, 4CH
	INT		21H
		
	ret 

TESTPC ends
end START