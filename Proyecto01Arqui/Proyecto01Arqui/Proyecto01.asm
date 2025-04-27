; File: Proyecto01.asm

option casemap:none

EXTERN _MCD: PROC
EXTERN ExitProcess: PROC

.DATA
    a_val       DQ 365
    b_val       DQ 70
    mcm_result  DB 20 DUP (?)
    overflow_msg DB "Overflow", 0

.CODE

inicio_programa PROC
    ; --- Calcular el MCD ---
    MOV RCX, a_val
    MOV RDX, b_val
    CALL _MCD
    MOV R8, RAX  ; Guardar el MCD

    ; --- Calcular el MCM ---
    MOV RAX, a_val
    MUL b_val

    CMP RDX, 0
    JNE manejar_overflow

    ; --- Dividir el producto por el MCD ---
    MOV RCX, R8
    XOR RDX, RDX
    DIV RCX
    MOV R9, RAX  ; Resultado de la division (MCM)

    ; --- (Aqui podrías convertir R9 a ASCII y guardarlo en mcm_result) ---

    ; --- Terminar programa ---
    MOV RCX, 0
    CALL ExitProcess

inicio_programa ENDP

manejar_overflow PROC
    LEA RCX, overflow_msg
    MOV RDI, OFFSET mcm_result
    MOV RSI, OFFSET overflow_msg
    CALL copy_string

    MOV RCX, 1
    CALL ExitProcess

manejar_overflow ENDP

copy_string PROC
copy_loop:
    MOV AL, [RSI]
    CMP AL, 0
    JE copy_done
    MOV [RDI], AL
    INC RDI
    INC RSI
    JMP copy_loop

copy_done:
    RET

copy_string ENDP

END

