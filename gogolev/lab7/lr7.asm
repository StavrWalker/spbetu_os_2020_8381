ASSUME  CS:OVER,    DS:DATA,    ss:ASTACK

ASTACK SEGMENT STACK
    dw  128 dup(0)
ASTACK ENDS

DATA SEGMENT

    EXIT_CODE_STR	   db	"Exit code: ", "$"
    EXIT_CTRL_C_STR	   db	"Exit code: CRTL+C", 13, 10, "$"
    NO_FILE_STR	  	   db  "No file in: ", "$"
    START_STR_NAME     db "File: ", "$"
    START_STR_PATH     db "Directory: ", "$"
    START_STR_END      db " ...", 13, 10, "$"
    OVER_NO_F_ERROR     db "File not found in:$"
    OVER_PATH_STR       db "Path: $"
    OVER_MEM_ERR        db "Not enought memory!$"
    LOAD_ERR           db "Overlay isn't loaded!", 13, 10, "$"
	COMMAND_TAIL       db  9, "tail LR6", 0
	PARAMS 			   dw 	7 dup(?)
    CHILD_BEGINS_STR   db 13, 10, "<----- Child begins ----->", 13, 10, "$"
    CHILD_END_STR      db 13, 10, "<----- Child ends ----->", 13, 10, "$"
    PATH 		       db 	256 dup(0)
	OVER_FIRST         db "over1.ovl", 0, "$"
    OVER_SECOND         db "over2.ovl", 0, "$"
    KEEP_PSP 		   dw 	0
    KEEP_SS 		   dw 	0
    KEEP_SP 		   dw 	0
	O_ADDRESS          dd 0
	MEMORY_FREE_CODE   db 0
	ENDL               db 13, 10, "$"

DATA ENDS

OVER SEGMENT

WRITE_BYTE	PROC
		push 	ax
		push 	bx
		push 	dx

		mov 	ah, 0
		mov 	bl, 10h
		div 	bl
		mov 	dx, ax
		mov 	ah, 02h
		cmp 	dl, 0Ah
		jl 		PRINT
		add 	dl, 07h
	PRINT:
		add 	dl, '0'
		int 	21h;

		mov 	dl, dh
		cmp 	dl, 0Ah
		jl 		PRINT_EXT
		add 	dl, 07h
	PRINT_EXT:
		add 	dl, '0'
		int 	21h;

		pop 	dx
		pop 	bx
		pop 	ax
	    ret
WRITE_BYTE	ENDP

WRITE_STR 	PROC	near
		push 	ax
		mov 	ah, 09h
		int		21h
		pop 	ax
	    ret
WRITE_STR 	ENDP



FREE_MEM 	PROC
		mov 	bx, offset PROGEND
		mov ax, es
		sub bx, ax
		mov cl, 4
		shr bx, cl
		inc bx
		
		xor ax, ax
		mov ah, 4Ah
		int 21h
		jc 		FREE_MEM_ERR
		jmp 	FREE_MEM_SUCCESS
	FREE_MEM_ERR:
		mov 	OVER_MEM_ERR, 1
	FREE_MEM_SUCCESS:
	    ret
FREE_MEM 	ENDP



FORM_PATHS PROC
		push 	ax
		push 	es
		push 	si
		push 	di
		push 	dx

		push ax
		mov es, es:[2Ch]
		mov si, 0

	SKIP:
		mov ax, es:[si]
		inc si
		cmp ax, 0
		jne SKIP
		add si, 3
		mov di, offset PATH

	EMPATH:
		mov al, es:[si]
		mov BYTE PTR [di], al
		cmp al, 0
		je DEPATH
		inc di
		inc si
		jmp EMPATH

	DEPATH:
		mov al, [di]
		cmp al, '\'
		je RECALL
		mov BYTE PTR [di], 0
		dec di
		jmp DEPATH

	RECALL:
		pop si

	APPEND:
		inc di
		mov al, [si]
		cmp al, 0
		je PROCEED
		mov BYTE PTR [di], al
		inc si
		jmp APPEND

	PROCEED:
		mov BYTE PTR [di], 0
		mov BYTE PTR [di + 1], '$'

		mov dx, offset PATH
		call WRITE_STR

		pop  	dx
		pop  	di
		pop  	si
		pop  	es
		pop  	ax

		ret
FORM_PATHS ENDP


OVERLAY_MODULE PROC
        push ax
        push bx
        push cx
        push dx
        push si
        push es

        mov ah, 4Eh
        mov cx, 0
        mov dx, offset PATH
        int 21h
            jnc NO_ERROR
        mov dx, offset LOAD_ERR
        call WRITE_STR
        cmp ax, 2
            je NO_FILE
        cmp ax, 3
            je NO_FILE
        cmp ax, 12h
            je NO_FILE
        jmp EXEC_DEF

    NO_FILE:
        mov dx, offset OVER_NO_F_ERROR
        call WRITE_STR
        mov dx, offset OVER_PATH_STR
        call WRITE_STR
        mov dx, offset PATH
        call WRITE_STR
		mov dx, offset ENDL
        call WRITE_STR
        jmp EXEC_DEF

    NO_ERROR:
        mov si, 0080h
        add si, 1Ah
        mov bx, es:[si]
        mov ax, es:[si + 2]
        mov	cl, 4
        shr bx, cl
        mov	cl, 12
        shl ax, cl
        add bx, ax
        add bx, 2

        mov ah, 48h
        int 21h

        jnc PREPARE_DATA
        mov dx, offset OVER_MEM_ERR
        call WRITE_STR
        jmp EXEC_DEF

    PREPARE_DATA:
        mov PARAMS, ax
        mov WORD PTR O_ADDRESS + 2, ax

        mov dx, offset PATH
        push ds
        pop es
        mov bx, offset PARAMS
        mov ax, 4B03h
        int 21h

        jnc LOADED
        mov dx, offset LOAD_ERR
        call WRITE_STR
        jmp EXEC_DEF

    LOADED:
        mov ax, PARAMS
        mov es, ax

        mov dx, offset CHILD_BEGINS_STR
        call WRITE_STR

        call O_ADDRESS

        mov dx, offset CHILD_END_STR
        call WRITE_STR

        mov es, ax
        mov ah, 49h
        int 21h

    EXEC_DEF:
        pop es
        pop si
        pop dx
        pop cx
        pop bx
        pop ax

        ret
OVERLAY_MODULE ENDP

MAIN PROC
		mov 	ax, DATA
		mov 	ds, ax

	call 	FREE_MEM
		cmp 	MEMORY_FREE_CODE, 0
		jne 	RESULT_END

	mov ax, offset OVER_FIRST
	call FORM_PATHS
	call OVERLAY_MODULE

	mov ax, offset OVER_SECOND
	call FORM_PATHS
	call OVERLAY_MODULE

	RESULT_END:
		mov 	ah, 4Ch
		int 	21h
MAIN ENDP
PROGEND:

OVER ENDS

end MAIN
