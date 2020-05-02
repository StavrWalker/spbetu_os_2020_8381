ASTACK	SEGMENT  STACK
DW 128 DUP(0)			
ASTACK  ENDS

DATA		SEGMENT
INT_LOADED_NOW      db 'Resident program has been loaded', 0dh, 0ah, '$'
INT_UNLOAD	        db 'Resident program has been unloaded', 0dh, 0ah, '$'
INT_ALREADY_LOAD	db 'Resident program is already loaded', 0dh, 0ah, '$'
NOT_LOADED			db 'Resident program is not loaded', 0dh, 0ah, '$'
IS_LOADED   		DB 0
CHECK 				DB 0

DATA 		ENDS

CODE	SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:ASTACK

INTERRUPT proc far
	jmp  INTERRUPT_START
		COUNTER_INT db 'Number of interrupts: 000'
		INT_ID    	dw 6666h
		SAVE_IP     dw 0
		SAVE_CS     dw 0
		SAVE_PSP  	dw 0
	INTERRUPT_START:
		push ax
		push bx
		push cx
		push dx
		push si
		push es
		push ds
		
		mov ax, seg COUNTER_INT
		mov ds, ax
		
		call GET_CURS ;dh, dl - текущая строка, колонка курсора
					 ;ch,cl - текущая начальная, конечная строка курсора
		push dx
		call SET_CURS
		
		
		mov ax, seg COUNTER_INT
		push ds
		mov ds,ax
		mov si, offset COUNTER_INT
		add si, 24
		mov cx,3
			
		CYCLE:
			mov ah, [si]
			inc ah
			mov [si],ah
			cmp ah, ':'
			jne END_CYCLE
			mov ah, '0'
			mov [si],ah
			dec si
			loop CYCLE
		END_CYCLE:
			pop ds
		
		PRINTING:
			push es
			push bp
			mov ax, seg COUNTER_INT
			mov es,ax
			mov bp, offset COUNTER_INT
			call OUTPUT_BP
			pop bp
			pop es

			pop dx
			mov ah, 02h
			mov bh,0h
			int 10h
			
			pop ds
			pop es
			pop si
			pop dx
			pop cx
			pop bx
			pop ax
			
			mov al, 20h
			out 20h, al
		iret
INTERRUPT ENDP
	LAST_BYTE:
			

OUTPUT_BP proc near ;вывод строки по адресу es:bp на экран
	push ax
	push bx
	push dx
	push cx
		mov ah, 13h ;функция вывода строки в bp
		mov al, 1h ;использовать атрибут в bl и не трогать курсор
		mov bl, 0Bh ;цвет
		mov bh, 0 ;номер видео страницы
		mov cx, 25 ;длина строки
		int 10h  
	pop cx
	pop dx
	pop bx
	pop ax
	ret
OUTPUT_BP ENDP

GET_CURS proc
	push ax
	push bx

	mov ah, 03h
	mov bh, 0h
	int 10h

	pop bx
	pop ax
	ret
GET_CURS ENDP

SET_CURS proc
	push ax
	push bx

	mov ah, 02h
	mov bh, 0h
	mov dh, 22 ;строка начала вывода
	mov dl, 42 ;колонка начала вывода
	int 10h

	pop bx
	pop ax
	ret
SET_CURS ENDP



PRINT proc near
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT endp

LOAD_INTERRUPT PROC near
	push AX
	push BX
	push CX
	push DX
	push DS
	push ES

	mov AH, 35H ; функция получения вектора
	mov AL, 1CH ; номер вектора
	int 21H
	mov SAVE_IP, BX ; запоминание смещения
	mov SAVE_CS, ES ; и сегмента
	
	CLI
	push DS
	mov DX, offset INTERRUPT
	mov AX, seg INTERRUPT
	mov DS, AX
	mov AH, 25H
	mov AL, 1CH
	int 21H ; восстанавливаем вектор
	pop DS
	STI
	
	mov DX, offset LAST_BYTE
	mov cl, 4h
	shr dx, cl
	add dx, 10fh
	inc DX ; размер в параграфах
	xor AX, AX
	mov AH, 31h
	int 21h

	pop ES
	pop DS
	pop DX
	pop CX
	pop BX
	pop AX
	ret
LOAD_INTERRUPT ENDP

UNLOAD_INTERRUPT PROC near
	CLI
	push AX
	push BX
	push DX
	push DS
	push ES
	push SI
		
	mov AH, 35h
	mov AL, 1Ch
	int 21h
	mov SI, offset SAVE_IP
	sub SI, offset INTERRUPT
	mov DX, ES:[BX+SI]
	mov AX, ES:[BX+SI+2]
	
	push DS
	mov DS, AX
	mov AH, 25h
	mov AL, 1Ch
	int 21h
	pop DS
	
	mov AX, ES:[BX+SI+4]
	mov ES, AX
	push ES
	mov AX, ES:[2Ch]
	mov ES, AX
	mov AH, 49h
	int 21h
	pop ES
	
	mov AH, 49h
	int 21h
	
	STI
		
	pop SI
	pop ES
	pop DS
	pop DX
	pop BX
	pop AX
	ret
UNLOAD_INTERRUPT ENDP

CHECK_UN PROC near
	push AX
	push ES
		
	mov AX, SAVE_PSP
	mov ES, AX
	cmp byte ptr ES:[82h], '/'
	jne END_OF_CHECK
	cmp byte ptr ES:[83h], 'u'
	jne END_OF_CHECK
	cmp byte ptr ES:[84h], 'n'
	jne END_OF_CHECK
	mov CHECK , 1
		
	END_OF_CHECK:
		pop ES
		pop AX
		ret
CHECK_UN ENDP

CHECK_1CH PROC near
	push AX
	push BX
	push SI

	mov AH, 35h
	mov AL, 1Ch
	int 21h
	mov SI, offset INT_ID
	sub SI, offset INTERRUPT
	mov AX, ES:[BX+SI]
	cmp AX, 6666h
	jne END_OF_CHECK_1CH
	mov IS_LOADED, 1

	END_OF_CHECK_1CH:
		pop SI
		pop BX
		pop AX
		ret
CHECK_1CH ENDP

MAIN PROC FAR
	push DS
	xor ax, ax
    push ax
	mov AX, DATA
	mov DS, AX
	mov SAVE_PSP, ES	
	
	call CHECK_1CH
	call CHECK_UN
	
	
	cmp CHECK, 1
	je UNLOAD
	
	mov al, IS_LOADED
	cmp al, 1
	jne LOAD
	

	mov DX, offset INT_ALREADY_LOAD 
	call PRINT
	jmp ENDD
	
	LOAD:
		mov DX, offset INT_LOADED_NOW
		call PRINT
		call LOAD_INTERRUPT
		jmp ENDD

	UNLOAD:
		cmp IS_LOADED, 1
		jne IF_1CH_NOT_SET
		call UNLOAD_INTERRUPT
		mov DX, offset INT_UNLOAD 
		call PRINT
		jmp ENDD

	IF_1CH_NOT_SET:
		mov DX, offset NOT_LOADED
		call PRINT

	ENDD:
		xor AL, AL
		mov AH, 4Ch
		int 21h
MAIN ENDP
CODE ENDS


END MAIN
