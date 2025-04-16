;Convierte de caracter ascii a binario
includelib \Windows\System32\kernel32.dll

ExitProcess proto

.data
    char   db 'A'                ; Carácter ASCII que queremos convertir
    binario db 32 dup('0')       ; Espacio para binario de 32 bits, inicializado con ceros

.code
main PROC

    ; Cargar direcciones válidas en registros de 64 bits
    mov rsi, OFFSET char         ; Dirección del carácter ASCII en RSI
    mov rdi, OFFSET binario      ; Dirección del binario en RDI
    call _AsciiABinario32        ; Llama a la función para convertir ASCII a binario

    ; Finaliza el programa
    call ExitProcess

main ENDP

_AsciiABinario32 PROC
; Convierte un carácter ASCII en su representación binaria de 32 bits
; Entrada: RSI -> dirección del carácter ASCII
; Salida: RDI -> dirección del binario de 32 bits

    ; Rellenar los primeros 24 bits con ceros
    mov rcx, 24                  ; Contador para rellenar 24 ceros
RellenarCeros:
    mov byte ptr [rdi], '0'      ; Escribe '0' en la posición actual de RDI
    inc rdi                      ; Avanza al siguiente byte
    loop RellenarCeros           ; Repite hasta completar los 24 ceros

    ; Procesar el carácter ASCII
    mov al, byte ptr [rsi]       ; Carga el carácter ASCII en AL
    xor ah, ah                   ; Limpia AH para trabajar con AX
    mov rcx, 8                   ; Contador para los 8 bits del carácter
GenerarBinario:
    shl ax, 1                    ; Desplaza el bit más significativo a CF
    jc EsUno                     ; Si el bit es 1, salta a EsUno
    mov byte ptr [rdi], '0'      ; Escribe '0' si el bit es 0
    jmp Siguiente
EsUno:
    mov byte ptr [rdi], '1'      ; Escribe '1' si el bit es 1
Siguiente:
    inc rdi                      ; Avanza al siguiente byte
    loop GenerarBinario          ; Repite para los 8 bits del carácter

    ret                          ; Retorna al llamador
_AsciiABinario32 ENDP

END