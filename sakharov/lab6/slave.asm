LAB2 SEGMENT
      ASSUME CS:LAB2, DS:LAB2, ES:NOTHING, SS:NOTHING
      ORG 100H ; PSP

START: JMP BEGIN


;DATA SEGMENT
    WR_MEM          db 'Address of the unavailable memory: ', '$'
    ENV_ADDRESS     db 'Address of the environment: ', '$'
    COMMAND_TAIL    db 'Command line tail: ', '$'
    COMMAND_NO_TAIL db 'no tail.', '$'
    ENV_DATA        db 'Content of the environment: ' , '$'
    PATH            db 'Load module path: ' , '$'
    PRESS_ANY_KEY   db 'Press any key to continue$'
    ENDL            db 0dh, 0ah, '$'
;DATA ENDS

;CODE SEGMENT
WRITE PROC near
    push AX
    mov ah, 09h
    int 21h
    pop AX
    ret
WRITE ENDP

WRITE_LINE PROC near
    call WRITE
    mov DX, offset ENDL
    call WRITE
    ret
WRITE_LINE ENDP

WRITE_HEX_WORD PROC
    push AX
    push BX

    mov BX, AX
    mov AL, AH
    call WRITE_HEX_BYTE
    mov AX, BX
    call WRITE_HEX_BYTE

    pop BX
    pop AX
    ret
WRITE_HEX_WORD ENDP

WRITE_HEX_BYTE PROC
    push AX
    push BX
    push DX

    mov AH, 0
    mov BL, 16
    div BL
    mov DX, AX
    mov AH, 02h
    cmp DL, 0Ah
        jl PRINT_BYTE
    add DL, 7
    PRINT_BYTE:
    add DL, '0'
    int 21h;

    mov DL, DH
    cmp DL, 0Ah
        jl PRINT_BYTE_2
    add DL, 7
    PRINT_BYTE_2:
    add DL, '0'
    int 21h;

    pop DX
    pop BX
    pop AX
    ret
WRITE_HEX_BYTE ENDP

WRITE_CHAR PROC
    push AX
    push DX

    xor DX, DX
    mov DL, AL
    mov AH, 02h
    int 21h

    pop DX
    pop AX
    ret
WRITE_CHAR ENDP

TETR_TO_HEX PROC near
    and AL,0Fh
    cmp AL,09
    jbe NEXT
    add AL,07
    NEXT:
    add AL,30h
    ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
    push CX ; байт в AL переводится в два символа шестн. числа в AX
    mov AH,AL
    call TETR_TO_HEX
    xchg AL,AH
    mov CL,4
    shr AL,CL
    call TETR_TO_HEX ; в AL старшая цифра
    pop CX ; в AH младшая
    ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near ; 16 с/с 16 bit. В AX - число, DI – адрес последнего символа
    push BX
    mov BH,AH
    call BYTE_TO_HEX
    mov [DI],AH
    dec DI
    mov [DI],AL
    dec DI
    mov AL,BH
    call BYTE_TO_HEX
    mov [DI],AH
    dec DI
    mov [DI],AL
    pop BX
    ret
WRD_TO_HEX ENDP

BYTE_TO_DEC PROC near ; 10 с/с, SI - адрес поля младшей цифры
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

GET_NA_MEMORY PROC near
    push AX
    push DX

    mov DX, offset WR_MEM
    call WRITE

    mov AX, DS:[2h]
    call WRITE_HEX_WORD

    mov DX, offset ENDL
    call WRITE

    pop DX
    pop AX
    ret
GET_NA_MEMORY ENDP

GET_ENV_ADDRESS PROC near
    push AX
    push DX

    mov DX, offset ENV_ADDRESS
    call WRITE

    mov AX, DS:[2Ch]
    call WRITE_HEX_WORD

    mov DX, offset ENDL
    call WRITE

    pop DX
    pop AX
    ret
GET_ENV_ADDRESS ENDP

GET_COMMAND_TAIL PROC near
    push AX
    push CX
    push DX

    mov DX, offset COMMAND_TAIL
    call WRITE

    xor AX, AX
    mov AL, ES:[80h]
    add AL, 81h
    
    mov SI, AX
    push ES:[SI]
    mov byte ptr ES:[SI+1], '$'
    push DS
    mov CX, ES
    mov DS, CX
    mov DX, 81h
    call WRITE_LINE

    pop ds
    pop ES:[SI]

    pop DX
    pop CX
    pop AX
    ret
GET_COMMAND_TAIL ENDP

GET_ENV_DATA PROC near
    push AX
    push BX
    push DX
    push ES
    push SI

    mov DX, offset ENV_DATA
    call WRITE_LINE
    
    xor SI, SI
    mov BX, 2Ch
    mov ES, [BX]
    WRITE_ENV:
        cmp BYTE PTR ES:[SI], 0h
            je NEW_LINE
        mov AL, ES:[SI]
        call WRITE_CHAR
        jmp CHECK_END

    NEW_LINE:
        mov DX, offset ENDL
        call WRITE
    CHECK_END:
        inc SI
        cmp WORD PTR ES:[SI], 0001h
            je WRITE_PATH
        jmp WRITE_ENV

    WRITE_PATH:
        mov DX, offset PATH
        call WRITE
        add SI, 2
    PATH_FOR:
        cmp BYTE PTR ES:[SI], 00h
        je END_ENV_DATA
        mov AL, ES:[SI]
        call WRITE_CHAR
        inc SI
        jmp PATH_FOR

    END_ENV_DATA:
        pop SI
        pop ES
        pop DX
        pop BX
        pop AX
    ret
GET_ENV_DATA ENDP

BEGIN:
    push  DS
    sub   AX,AX
    push  AX
    ;mov   AX,DATA
    ;mov   DS,AX
    ; Начало
    call GET_NA_MEMORY
    call GET_ENV_ADDRESS
    call GET_COMMAND_TAIL
    call GET_ENV_DATA
    ; Выход
    xor AL,AL
    mov dx, offset ENDL
    call WRITE
    mov dx, offset PRESS_ANY_KEY
    call WRITE_LINE
    mov ah, 01h
    int 21h
    mov AH,4Ch
    int 21H
    ret

LAB2 ENDS
      END START



