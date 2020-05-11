
CODE      SEGMENT
          ASSUME CS:CODE, DS:DATA, SS:AStack
		  
		  
interruption:

intStack dw 48 dup (?)	
stackEnd dw ?	
command db "lab3.com$"
scanCodes db 26h, 1eh, 30h, 04h, 34h, 2eh, 18h, 32h
key db 58h ; f12
nextSymbol db 0	  
oldSS dw 0
oldSP dw 0
oldAX dw 0  
PSP dw ?	
KEEP_IP DW 0 ; и смещения прерывания  
KEEP_CS DW 0 ; для хранения сегмента
signature dw 0f11fh
  
ROUT PROC FAR



	
	
	;;;;;;;;;
	
	push ax
	in al,60h
	cmp al,cs:key
	pop ax
	je userInt
	jmp dword ptr cs:KEEP_IP
	;call dword ptr cs:KEEP_IP
	jmp onlyExit
	
	
userInt:


	mov cs:oldSS,ss
	mov cs:oldSP,sp
	mov cs:oldAX,ax

	mov ax, cs
	mov ss,ax
	mov sp, ax
	add sp, 96;64
   
   
	push ax
	push bx
	push cx
	push dx
	push bp
	
	
	
	in al,61h
	mov ah, al    
	or al, 80h    
	out 61h, al  
	xchg ah, al    
	out 61h, al   
	
	mov di, 0
	
writeInBuf:

	mov ah, 05h
	mov cl, cs:command[di]
	cmp cl, '$'
	je exit
	mov ch, cs:scanCodes[di]
	int 16h
	or al,al
	jnz clear
	inc di
	jmp writeInBuf
	
clear:

  	push es
	CLI	;запрещаем прерывания
	xor ax, ax
	MOV es, ax	
	MOV al, es:[41AH];\\	
	MOV es:[41CH], al;- head=tail 	
	STI	;разрешаем прерывания
	pop es
	
   jmp writeInBuf

	
	
exit:
	pop bp
	pop dx
	pop cx
	pop bx
	pop ax
	
	mov ax, cs:oldSS
	mov ss, ax
	mov ax, cs:oldAX
	mov sp, cs:oldSP
	
	mov al, 20h     
	out 20h, al  

onlyExit:
	iret			
ROUT  ENDP 

endInterruption:


setInt proc

	push ds
	mov dx, OFFSET ROUT
	mov ax, SEG ROUT
	mov ds, ax
	mov ah,25h
	mov al, 09h;1ch
	int 21h
	pop ds


	;lea dx, final
	lea dx, endInterruption
	lea ax, interruption
	sub dx, ax
	

	mov cl, 4
	shr dx, cl
	inc dx
	
	add dx, 16

	mov ah, 31h
	mov al, 0
	int 21h
	
	
	ret
setInt endp


restoreInt proc

	push es

	mov ah, 35h
	mov al, 09h;1ch
	int 21h
	
	mov  ax, es:[bx-4]
	mov KEEP_CS, ax
	mov  ax, es:[bx-6]
	mov KEEP_IP, ax
	mov ax, es:[bx-8]
	mov PSP, ax
	
	cli
	push ds
	mov dx, KEEP_IP
	mov ax, KEEP_CS
	mov ds, ax
	mov ah, 25h
	mov al, 09h;1ch
	int 21h
	pop ds
	
	
	
	mov ax, PSP
    mov es,ax
    push es
   
    mov ax,es:[2ch] ; очистка данных из префикса
    mov es,ax
    mov ah,49h
    int 21h
   
    pop es
	
    mov ah,49h
    int 21h
	

	sti
	
	
	pop es
	
	ret

restoreInt endp


PRINT	  PROC  NEAR
          mov   AH,9
          int   21h 
          ret
PRINT     ENDP


Main   PROC  FAR 

	push  DS       ;\  Сохранение адреса начала PSP в стеке
	sub   AX,AX    ; > для последующего восстановления по
	push  AX       ;/  команде ret, завершающей процедуру.
	mov   AX,DATA             ; Загрузка сегментного
	mov   DS,AX               ; регистра данных.
	 
	mov ax, es
	mov PSP, ax
	

	push es
	;если не загружен
	mov ah, 35h
	mov al, 09h;1ch
	int 21h
	
	mov  dx, es:[bx-2]
	mov ax, signature
	cmp dx, ax
	je loaded
	
	
	mov KEEP_IP, bx
	mov KEEP_CS, es
	
	
	pop es
	
	jmp notLoaded
	

loaded:

	pop es ;;от строки 269
	
	mov		DX, OFFSET LOADED_STR
	call 	PRINT
	
	
	mov cx, 0
	mov cl, es:[80h]
	cmp cl, 0
	je endMain
	

	mov al, es:[82h]
	cmp al, '/'
	jne endMain
	
	
	mov al, es:[83h]
	cmp al, 'u'
	jne endMain
	
	
	
	mov al, es:[84h]
	cmp al, 'n'
	jne endMain
	
	
	mov		DX, OFFSET UNLOADED_STR
	call 	PRINT
	
	call restoreInt
	
	jmp endMain

notLoaded:

	mov		DX, OFFSET NOT_LOADED_STR
	call 	PRINT
	call setInt

endMain:
	
	xor 	AL, AL
	mov 	AH, 4CH
	int 	21H


final:
	 
Main      ENDP

CODE      ENDS




AStack    SEGMENT  STACK
          DW 100 DUP(1)    
AStack    ENDS



DATA      SEGMENT


NOT_LOADED_STR db "Resident is not uploaded", 13, 10, "$"
LOADED_STR db "Resident is uploaded", 13, 10, "$"
UNLOADED_STR db "Resident was unloaded", 13, 10, "$"



DATA      ENDS


		  


          END Main
		  
		  
