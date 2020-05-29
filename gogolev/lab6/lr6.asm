ASSUME  CS:CODE,    DS:DATA,    ss:ASTACK

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
	COMMAND_TAIL       db  9, "tail LR6", 0
	PARAMS 			   dw 	7 dup(?)
    CHILD_BEGINS_STR   db 13, 10, "<----- Child begins ----->", 13, 10, "$"
    CHILD_END_STR      db 13, 10, "<----- Child ends ----->", 13, 10, "$"
    PATH 		       db 	256 dup(0)
	PATH_WITH_FILENAME db  256 dup(0)
    FILE_STR 		   db 	"lr2bin.com", "$"
    KEEP_PSP 		   dw 	0
    KEEP_SS 		   dw 	0
    KEEP_SP 		   dw 	0
    MEMORY_ERROR 	   db 	0

DATA ENDS

CODE SEGMENT

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
		mov 	ax, es
		sub 	bx, ax
		mov 	cl, 4
		shr 	bx, cl
		mov 	ah, 4Ah
		int 	21h
		jc 		FREE_MEM_ERR
		jmp 	FREE_MEM_SUCCESS
	FREE_MEM_ERR:
		mov 	MEMORY_ERROR, 1
	FREE_MEM_SUCCESS:
	    ret
FREE_MEM 	ENDP



FORM_PATHS		PROC	near
		push    ax
		push    es
		push    si
        push    di
		push    dx

		mov     ax, es:[2Ch]
        mov     es, ax

		mov     si, 0
SYMBOL:
        add     si, 1
		mov     al, es:[si]
		mov     ah, es:[si+1]
		cmp     ax, 0
		jne     SYMBOL

        add     si, 4
        mov     di, 0
PATH_LOOP:
        mov     al, es:[si]
        cmp     al, 0
        je      DIR_END

        mov     PATH[di], al

        inc     di
        add     si, 1
        jmp     PATH_LOOP

DIR_END:
        cmp     PATH[di - 1], "\"
        je      APPENSION
        mov     PATH[di - 1], "$"
        dec     di
        jmp     DIR_END

APPENSION:
        mov     PATH[di], "$"

        mov     si, 0
        mov     di, 0
PATH_LOOP_COPY:
        cmp     PATH[di], "$"
        je      ADD_NAME_PREP
        mov     al, PATH[di]
        mov     PATH_WITH_FILENAME[si], al
        inc     si
        inc     di
        jmp     PATH_LOOP_COPY

ADD_NAME_PREP:
        mov     di, 0
PATH_LOOP_FILE_NAME:
        cmp     FILE_STR[di], "$"
        je      FORM_PATHS_END
        mov     al, FILE_STR[di]
        mov     PATH_WITH_FILENAME[si], al
        inc     si
        inc     di
        jmp     PATH_LOOP_FILE_NAME

FORM_PATHS_END:
        mov     PATH_WITH_FILENAME[si], "$"

		pop     dx
        pop     di
		pop     si
		pop     es
		pop     ax
		ret
FORM_PATHS		ENDP



MAIN PROC
		mov 	ax, DATA
		mov 	ds, ax
        call    FORM_PATHS

        mov     dx, offset START_STR_NAME
        call    WRITE_STR
        mov     dx, offset FILE_STR
        call    WRITE_STR
        mov     dx, offset START_STR_PATH
        call    WRITE_STR
        mov     dx, offset PATH
        call    WRITE_STR
        mov     dx, offset START_STR_END
        call    WRITE_STR

		call 	FREE_MEM
		cmp 	MEMORY_ERROR, 0
		jne 	RESULT_END

        mov     PARAMS[0], 0
        mov     PARAMS[2], offset COMMAND_TAIL
        mov     PARAMS[4], ds

        mov     dx, offset CHILD_BEGINS_STR
        call    WRITE_STR

		push 	ds
		pop 	es

        mov     ax, ds
        mov     es, ax
		mov 	dx, offset PATH_WITH_FILENAME
		mov 	bx, offset PARAMS

		mov 	KEEP_SS, ss
		mov 	KEEP_SP, sp

		mov 	ax, 4B00h ; main call
		int 	21h

        mov     cx, DATA
        mov     ds, cx

		mov 	ss, KEEP_SS
		mov 	sp, KEEP_SP

        mov     dx, offset CHILD_END_STR
        call    WRITE_STR

		jc 		RESULT_NO_FOUND
		jmp 	RESULT_SUCCESS

	RESULT_NO_FOUND:
		mov 	dx, offset NO_FILE_STR
		call 	WRITE_STR
		mov 	dx, offset FILE_STR
		call 	WRITE_STR
		jmp 	RESULT_END

	RESULT_SUCCESS:
		mov 	ah, 4Dh
		int 	21h
		cmp 	ah, 1
		je 		RESULT_CTRL_C
	RESULT_EXIT_CODE:
		mov 	dx, offset EXIT_CODE_STR
		call 	WRITE_STR
		call	WRITE_BYTE
		mov 	dl, ah
		mov 	ah, 2h
		int 	21h
		jmp 	RESULT_END
	RESULT_CTRL_C:
		mov 	dx, offset EXIT_CTRL_C_STR
		call 	WRITE_STR

	RESULT_END:
		mov 	ah, 4Ch
		int 	21h
MAIN ENDP
PROGEND:

CODE ENDS

end MAIN
