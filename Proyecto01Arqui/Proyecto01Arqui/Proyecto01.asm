;  Proyecto01.asm (x64)

;option casemap:none  ;  Sensible a mayúsculas/minúsculas

EXTERN _MCD: PROC
EXTERN ExitProcess: PROC

.DATA
    a_val   DQ 365
    b_val   DQ 70
    mcm_val DQ ?
    overflow_msg DB "Overflow", 0

.CODE

inicio_programa PROC
    ;  --- Calcular el MCD ---
    MOV RCX, a_val
    MOV RDX, b_val
    CALL _MCD
    MOV R8, RAX

    ;  --- Calcular el MCM: (a * b) / MCD ---
    MOV RAX, a_val
    MUL b_val
    CMP RDX, 0
    JNE manejar_overflow

    MOV RAX, a_val
    MUL b_val
    CMP RDX, 0
    JNE manejar_overflow
    MOV RCX, RAX
    XOR RDX, RDX
    DIV R8
    MOV mcm_val, RAX

    ;  --- Llamar a ExitProcess ---
    MOV RCX, 0
    CALL ExitProcess
    JMP fin_programa

manejar_overflow PROC
    LEA RCX, overflow_msg
    ;  ... (Código para mostrar el mensaje de overflow)
    RET

fin_programa:
    RET
inicio_programa ENDP

END inicio_programa ;  <--- Especificamos el punto de entrada aquí