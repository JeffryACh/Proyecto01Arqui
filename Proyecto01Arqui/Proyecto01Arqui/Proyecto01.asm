; File: Proyecto01.asm

option casemap:none

EXTERN _MCD: PROC
EXTERN ExitProcess: PROC

; Bloque de definici�n de datos
.DATA

    ; Variable de 64 bits (quadword) que almacena el valor decimal 365
    a_val       DQ 365

    ; Variable de 64 bits (quadword) que almacena el valor decimal 70
    b_val       DQ 70

    ; Arreglo de 20 bytes (byte) que almacena el resultado de un c�lculo
    ; Los valores iniciales son desconocidos (?)
    mcm_result  DB 20 DUP (?)

    ; Cadena de caracteres que contiene el texto "Overflow" seguido de un terminador nulo (0)
    ; Se utiliza para mostrar un mensaje de error en caso de desbordamiento
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

    ; --- (Aqui podr�as convertir R9 a ASCII y guardarlo en mcm_result) ---

    ; --- Terminar programa ---
    MOV RCX, 0
    CALL ExitProcess

inicio_programa ENDP

manejar_overflow PROC
    ; Cargar direcci�n de la cadena de error en RCX
    LEA RCX, overflow_msg
    
    ; Cargar direcci�n de destino para copiar la cadena de error en RDI
    MOV RDI, OFFSET mcm_result
    
    ; Cargar direcci�n de la cadena de error en RSI
    MOV RSI, OFFSET overflow_msg
    
    ; Llamar a la funci�n para copiar la cadena de error
    CALL copy_string

    ; Cargar c�digo de salida en RCX (1 = error)
    MOV RCX, 1
    
    ; Llamar a la funci�n para terminar el programa
    CALL ExitProcess

manejar_overflow ENDP

; Copia una cadena de caracteres terminada en null desde la direcci�n de origen en RSI hasta la direcci�n de destino en RDI.
copy_string PROC
    ; Bucle hasta llegar al terminador null
copy_loop:
    ; Carga el car�cter actual desde la cadena de origen
    MOV AL, [RSI]
    ; Verifica si el car�cter actual es el terminador null
    CMP AL, 0
    ; Si es as�, sale del bucle
    JE copy_done
    ; Copia el car�cter actual a la cadena de destino
    MOV [RDI], AL
    ; Incrementa el puntero de destino
    INC RDI
    ; Incrementa el puntero de origen
    INC RSI
    ; Vuelve al inicio del bucle
    JMP copy_loop
copy_done:
    ; La operaci�n de copia ha finalizado
    RET

copy_string ENDP

END

