AStack    SEGMENT  STACK
          DW 50 DUP(1)    
AStack    ENDS



DATA      SEGMENT


PARAMS dw 0 ;сегментный адрес среды
	   dd 0 ;сегмент и смещение командной строки
	   dd 0 ;сегмент и смещение первого FCB 
	   dd 0 ;сегмент и смещение второго FCB 
                  
oldSS dw 0
oldSP dw 0

modulePath db 50 dup (0)

MEMORY_7 db 'Сontrol memory block destroyed',13,10,'$'
MEMORY_8 db 'Low memory size for function',13,10,'$'
MEMORY_9 db 'Invalid memory address',13,10,'$'

LOAD_ERROR_1 db 'Incorrect function number',13,10,'$'
LOAD_ERROR_2 db 'File lab2.com was not found',13,10,'$'
LOAD_ERROR_5 db 'Disk error',13,10,'$'
LOAD_ERROR_8 db 'Not enough memory',13,10,'$'
LOAD_ERROR_10 db 'Incorrect enviroment string',13,10,'$'
LOAD_ERROR_11 db 'Incorrect format',13,10,'$'

EXECUTE_0 db 13,10,'Normal termination. Exit code =    ',13,10,'$'

EXECUTE_1 db 'Ctrl-Break termination',13,10,'$'
EXECUTE_2 db 'Device error termination',13,10,'$'
EXECUTE_3 db 'int 31h termination',13,10,'$'

DATA      ENDS

CODE      SEGMENT
          ASSUME CS:CODE, DS:DATA, SS:AStack
		  
oldDS dw 0

BYTE_TO_DEC PROC near
; перевод в 10с/с, SI - адрес поля младшей цифры
   push CX
   push DX
   xor AH,AH
   xor DX,DX
   mov CX,10
loop_bd:
   div CX
   or DL,30h
   mov [SI],DL
   dec SI
   xor DX,DX
   cmp AX,10
   jae loop_bd
   cmp AL,00h
   je end_l
   or AL,30h
   mov [SI],AL
end_l:
   pop DX
   pop CX
   ret
BYTE_TO_DEC ENDP


PRINT	  PROC  NEAR
          mov   AH,9
          int   21h 
          ret
PRINT     ENDP

FREE_MEM PROC near


	lea ax, final

	mov cl, 4
	shr ax, cl

	inc ax
	add ax, 50h
	mov bx,ax
	mov ax,0
	mov ah,4Ah
	int 21h
	jnc no_errors
	
mem_err7:	
	cmp ax, 7
	jne mem_err8
	mov dx, offset MEMORY_7
	call PRINT
	jmp no_errors
mem_err8:
	cmp ax, 8
	jne mem_err9
	mov dx, offset MEMORY_8
	call PRINT
	jmp no_errors
mem_err9:
	cmp ax, 9
	jne no_errors
	mov dx, offset MEMORY_9
	call PRINT

	
no_errors:
	ret
	
FREE_MEM	ENDP


CALL_MODULE PROC NEAR

	push es

	mov oldSP,sp
	mov oldSS,ss
	mov ax,ds
	mov es,ax

	lea dx, modulePath
	lea bx, PARAMS
	mov ax,4B00h
	int 21h

	mov dx, word ptr cs:[0]
	mov ds, dx
	
	
	mov sp,oldSP
	mov ss,oldSS
	

	pop es
	
	ret
CALL_MODULE ENDP


RESULTS PROC

	jc err1
	mov ax, 0
	mov ah, 4Dh
	int 21h

	cmp ah,1
	jne term2
	mov dx, offset EXECUTE_1
	call PRINT
	jmp endFunc
	
term2:

	cmp ah,2
	jne term3
	mov dx, offset EXECUTE_2
	call PRINT
	jmp endFunc
term3:
	cmp ah,3
	jne term0
	mov dx, offset EXECUTE_3
	call PRINT
	jmp endFunc
	
term0:
	
	mov dx, offset EXECUTE_0
	mov si, dx
	add si, 36
	call BYTE_TO_DEC

	call PRINT
	jmp endFunc

err1:
	cmp ax,1
	jne err2
	mov dx, offset LOAD_ERROR_1
	call PRINT
	jmp endFunc
err2:
	cmp ax,2
	jne err5
	mov dx, offset LOAD_ERROR_2
	call PRINT
	jmp endFunc
err5:

	cmp ax,5
	jne err8
	mov dx, offset LOAD_ERROR_5
	call PRINT
	jmp endFunc
	
err8:

	cmp ax,8
	jne err10
	mov dx, offset LOAD_ERROR_8
	call PRINT
	jmp endFunc

err10:

	cmp ax,10
	jne err11
	mov dx, offset LOAD_ERROR_10
	call PRINT
	jmp endFunc

err11:

	cmp ax,11
	jne endFunc
	mov dx, offset LOAD_ERROR_11
	call PRINT
	jmp endFunc
  
   
endFunc:  

   ret
RESULTS ENDP


GET_PATH proc near


	push es
	
	
	mov bx, 2ch
	mov es, es:[bx]
	mov di, 0
	mov si, 0
enviromentalContentLoop:


	mov dl, es:[di]
	TEST dl, dl
	jz firstZeroByte
	inc di
	jmp enviromentalContentLoop
	
firstZeroByte:

	inc di
	mov dl, es:[di]
	TEST dl, dl
	jnz enviromentalContentLoop

secondZeroByte:
	
	add di, 3

pathLoop:	

	mov dl, es:[di]
	TEST dl, dl
	jz endPath
	mov modulePath[si], dl
	
	inc si
	inc di
	jmp pathLoop
	
endPath:

	mov modulePath[si], '0'
	sub si, 5
	mov modulePath[si], 50
	mov modulePath[si+2], 99
	mov modulePath[si+3], 111
	mov modulePath[si+4], 109
	

	pop es
	
	ret
GET_PATH endp


Main   PROC  FAR 

	push  DS       ;\  Сохранение адреса начала PSP в стеке
	sub   AX,AX    ; > для последующего восстановления по
	push  AX       ;/  команде ret, завершающей процедуру.
	mov   AX,DATA             ; Загрузка сегментного
	mov   DS,AX               ; регистра данных.

	mov oldDS, ax
	call FREE_MEM
	
	
	mov ax,es:[2ch]
	mov PARAMS, ax
	mov PARAMS+2,es
	mov PARAMS+4,80h
	
	call GET_PATH
	call CALL_MODULE
	call RESULTS
	
endMain:
	
	xor 	AL, AL
	mov 	AH, 4CH
	int 	21H


final:
	 
Main      ENDP

CODE      ENDS


   END Main