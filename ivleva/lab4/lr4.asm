CODE    SEGMENT
ASSUME  CS:CODE,    DS:DATA,    SS:ASTACK

INTERRUPTION    PROC    FAR
        jmp     START
    INT_DATA:
        STR_COUNTER    DB  "000 interruptions"
        INT_CODE        DW  3158h

        INT_STACK 	DW 	100 dup (?)
        KEEP_SS		DW  0
		KEEP_SP 	DW  0
        KEEP_IP 	DW  0
        KEEP_CS 	DW  0
		KEEP_PSP 	DW	0
        KEEP_AX     DW  0

    
    START:
        mov 	KEEP_SS, SS 
        mov 	KEEP_SP, SP 
        mov 	KEEP_AX, AX 
		mov 	AX, seg INT_STACK 
		mov 	SS, AX 
		mov 	SP, offset INT_STACK
		add		SP, 200h
		mov 	AX, KEEP_AX
		push	AX
		push    BX
		push    CX
		push    DX
		push    SI
        push    ES
        push    DS
    SET_STACK:
		mov 	AX, seg STR_COUNTER
		mov 	DS, AX
        
    SET_CURSOR:
        mov     AH, 03h
		mov     BH, 0h
		int     10h
        push    DX

        mov     AH, 02h
		mov     BH, 0h
		mov     DX, 0920h 
		int     10h

	INCR:
		mov 	AX, SEG STR_COUNTER
		push 	DS
		mov 	DS, AX
		mov 	SI, offset STR_COUNTER
		add		SI, 2
		mov 	CX, 3
	CYCLE:
		mov 	AH, [SI]
		inc 	AH
		mov 	[SI], AH
		cmp 	AH, ':'
		jne 	END_CYCLE
		mov 	AH, '0'
		mov 	[SI], AH
		dec 	SI
		loop 	CYCLE		
	END_CYCLE:
		pop 	DS

	PRINT:
		push 	ES
		push	BP
        mov     AX, SEG STR_COUNTER
		mov     ES, AX
		mov     BP, offset STR_COUNTER
		mov     AH, 13h
		mov     AL, 1h
		mov 	BL, 3h
		mov     BH, 0
		mov     CX, 17
		int     10h

		pop		BP
		pop		ES

        pop     DX
        mov     AH, 02h
		mov     BH, 0h
		int     10h

		pop     DS
		pop     ES
		pop		SI
		pop     DX
		pop     CX
		pop     BX
		pop		AX

        mov 	AX, KEEP_SS
		mov 	SS, AX
		mov		AX, KEEP_AX
		mov 	SP, KEEP_SP

		mov     AL, 20h
		out     20h, AL
		iret
INTERRUPTION    ENDP
    LAST_BYTE:

INT_CHECK       PROC
		push    AX
		push    BX
		push    SI
		mov     AH, 35h
		mov     AL, 1Ch
		int     21h
		mov     SI, offset INT_CODE
		sub     SI, offset INTERRUPTION
		mov     AX, ES:[BX + SI]
		cmp	    AX, INT_CODE
		jne     INT_CHECK_END
		mov     INT_LOADED, 1
	INT_CHECK_END:
		pop     SI
		pop     BX
		pop     AX
		ret
INT_CHECK       ENDP

INT_LOAD        PROC
        push    AX
		push    BX
		push    CX
		push    DX
		push    ES
		push    DS
        mov     AH, 35h
		mov     AL, 1Ch
		int     21h
		mov     KEEP_CS, ES
        mov     KEEP_IP, BX
        mov     AX, seg INTERRUPTION
		mov     DX, offset INTERRUPTION	
		mov     DS, AX
		mov     AH, 25h
		mov     AL, 1Ch
		int     21h
		pop		DS
        mov     DX, offset LAST_BYTE
		mov     CL, 4h
		shr     DX, CL
		add		DX, 10Fh
		inc     DX
		xor     AX, AX
		mov     AH, 31h
		int     21h
        pop     ES
		pop     DX
		pop     CX
		pop     BX
		pop     AX
		ret
INT_LOAD        ENDP

INT_UNLOAD      PROC
        CLI
		push    AX
		push    BX
		push    DX
		push    DS
		push    ES
		push    SI
		mov     AH, 35h
		mov     AL, 1Ch
		int     21h
		mov 	SI, offset KEEP_IP
		sub 	SI, offset INTERRUPTION
		mov 	DX, ES:[BX + SI]
		mov 	AX, ES:[BX + SI + 2]
		push 	DS
		mov     DS, AX
		mov     AH, 25h
		mov     AL, 1Ch
		int     21h
		pop 	DS
		mov 	AX, ES:[BX + SI + 4]
		mov 	ES, AX
		push 	ES
		mov 	AX, ES:[2Ch]
		mov 	ES, AX
		mov 	AH, 49h
		int 	21h
		pop 	ES
		mov 	AH, 49h
		int 	21h
		STI
		pop     SI
		pop     ES
		pop     DS
		pop     DX
		pop     BX
		pop     AX
		ret
INT_UNLOAD      ENDP

CL_CHECK        PROC
        push    AX
		push    ES
		mov     AX, KEEP_PSP
		mov     ES, AX
		cmp     byte ptr ES:[82h], '/'
		jne     CL_CHECK_END
		cmp     byte ptr ES:[83h], 'u'
		jne     CL_CHECK_END
		cmp     byte ptr ES:[84h], 'n'
		jne     CL_CHECK_END
		mov     UNLOAD_CL, 1
	CL_CHECK_END:
		pop     ES
		pop     AX
		ret
CL_CHECK        ENDP

WRITE    PROC    NEAR
        push    AX
        mov     AH, 09h
        int     21h
        pop     AX
    	ret
WRITE    ENDP

MAIN 	PROC
		push    DS
		xor     AX, AX
		push    AX
		mov     AX, DATA
		mov     DS, AX
		mov     KEEP_PSP, ES
		call    INT_CHECK
		call    CL_CHECK
		cmp     UNLOAD_CL, 1
		je      UNLOAD
		mov     AL, INT_LOADED
		cmp     AL, 1
		jne     LOAD
		mov     DX, offset STR_WAS_LOADED
		call    WRITE
		jmp     MAIN_END
	LOAD:
		call    INT_LOAD
		jmp     MAIN_END
	UNLOAD:
		cmp     INT_LOADED, 1
		jne     NOT_EXIST
		call    INT_UNLOAD
		jmp     MAIN_END
	NOT_EXIST:
		mov     DX, offset STR_NOT_LOADED
		call    WRITE
	MAIN_END:
		xor 	AL, AL
		mov 	AH, 4Ch
		int 	21h
MAIN 	ENDP

CODE    ENDS

ASTACK  SEGMENT STACK
    DW  128 dup(0)
ASTACK  ENDS

DATA    SEGMENT
	STR_WAS_LOADED     DB  "Int was already loaded", 10, 13,"$"
	STR_NOT_LOADED		DB  "Int is not loaded", 10, 13,"$"
    INT_LOADED          DB  0
    UNLOAD_CL               DB  0
DATA    ENDS

END 	MAIN