;-----------------------------------------------------------
; Programa: Cálculo del MCM (mínimo común múltiplo)
;           Implementación en ensamblador (MASM) para 64?bits en Visual Studio.
;
; La idea es:
;   1. Convertir dos "hileras" ASCII (formato: primer byte = longitud, seguido de dígitos)
;      a números enteros de 32 bits.
;   2. Verificar que la aritmética (multiplicación) no provoque overflow.
;   3. Calcular el MCM usando la fórmula:
;
;           mcm(a,b) = (a * b) / gcd(a,b)
;
;   4. Convertir el resultado (o la cadena "overflow" si se detecta error) a ASCII,
;      dejándolo en el buffer de resultado.
;
; Se usan los siguientes procedimientos:
;     ascii_to_int    : convierte hilera ASCII a entero (retorna -1 en caso de error).
;     gcd             : calcula el máximo común divisor (Euclides).
;     mcm             : calcula el mínimo común múltiplo (verifica overflow en la multiplicación).
;     int_to_ascii    : convierte entero a hilera ASCII (null-terminada).
;     string_copy     : copia una cadena ASCII (null-terminada) a otro buffer.
;
; La comunicación entre módulos se hace vía registros y pila de acuerdo a la convención
; de Windows x64.
;
;-----------------------------------------------------------



; Se declara la API de Windows para terminar el programa.
EXTERN ExitProcess: PROC

.data
    ; Los números se definen en modo carácter:
    ; Primer byte: longitud; luego la hilera de dígitos (sin terminador nulo)
    numA_str    byte 5, "10318"    ; Ejemplo: "10318"
    numB_str    byte 4, "3147"     ; Ejemplo: "3147"
    
    ; Variables para los números (32 bits)
    numA        dd 0
    numB        dd 0
    mcm_result  dd 0
    
    ; Buffer para la hilera resultado (suficiente para 10 dígitos más terminador)
    result_ascii  byte 12 dup(0)
    
    ; Cadena a mostrar en caso de overflow
    overflow_str  byte "overflow", 0
    
    ; Constante: máximo entero permitido (2^31 - 1 = 2147483647)
    max_int_val dd 2147483647

.code

;-----------------------------------------------------------
; main PROC:
;   Entrada: Sin parámetros.
;   Flujo:
;     – Convierte numA_str y numB_str a enteros (ascii_to_int).
;     – Si alguno da error (retorno -1), salta a main_overflow.
;     – Calcula mcm pasando a y b en ECX y EDX (Windows x64).
;     – Si mcm retorna -1, salta a main_overflow.
;     – Convierte el entero resultado a ASCII (int_to_ascii).
;     – Llama a ExitProcess(0).
;-----------------------------------------------------------
main PROC
    ; Reservamos 40 bytes en la pila (shadow space, etc.)
    sub rsp, 40

    ; ----- Conversión de numA_str a entero -----
    lea rcx, numA_str         ; RCX = dirección de numA_str
    call ascii_to_int         ; resultado en EAX
    cmp eax, -1
    je main_overflow
    mov dword ptr [numA], eax

    ; ----- Conversión de numB_str a entero -----
    lea rcx, numB_str
    call ascii_to_int
    cmp eax, -1
    je main_overflow
    mov dword ptr [numB], eax

    ; ----- Cálculo del mcm -----
    ; Se pasan los parámetros en ECX (a) y EDX (b)
    mov ecx, dword ptr [numA]
    mov edx, dword ptr [numB]
    call mcm
    cmp eax, -1
    je main_overflow
    mov dword ptr [mcm_result], eax

    ; ----- Conversión de mcm_result a ASCII -----
    ; Se pasan: en ECX el número y en RDX la dirección del buffer resultado.
    mov ecx, dword ptr [mcm_result]
    lea rdx, result_ascii
    call int_to_ascii

    ; Termina el programa (ExitProcess con código 0)
    mov ecx, 0      ; Primer parámetro en RCX
    call ExitProcess

main_overflow:
    ; Se copia la cadena "overflow" al buffer de resultado
    lea rcx, result_ascii    ; destino
    lea rdx, overflow_str    ; fuente
    call string_copy
    mov ecx, 0
    call ExitProcess
main ENDP


;-----------------------------------------------------------
; ascii_to_int PROC:
;   Convierte una hilera ASCII a entero de 32 bits.
;   Formato de la hilera: primer byte = longitud, luego dígitos.
;   Entrada: RCX = dirección de la hilera.
;   Salida: EAX = entero (o -1 en caso de error o overflow).
;
; La comprobación de overflow se realiza de forma “estándar”:
; Si acumulador > 214748364 (es decir, max_int/10) o 
; si acumulador = 214748364 y el dígito > 7 (porque 2147483647 es el máximo),
; se produce error.
;-----------------------------------------------------------
ascii_to_int PROC
    push rbp
    mov rbp, rsp
    push rbx
    push rsi
    push rdi
    push r12
    push r13

    mov r12, rcx                ; r12 = puntero a la hilera
    movzx eax, byte ptr [r12]   ; EAX = longitud
    mov r13d, eax               ; r13d = cantidad de dígitos
    cmp r13d, 0
    je ascii_to_int_done_zero
    lea rsi, [r12+1]            ; rsi apunta al primer dígito

    xor rax, rax                ; acumulador = 0
    mov ebx, 214748364          ; umbral = max_int/10

ascii_to_int_loop:
    cmp r13d, 0
    je ascii_to_int_done_loop
    movzx edx, byte ptr [rsi]   ; edx = carácter actual
    cmp dl, '0'
    jl ascii_to_int_error_label
    cmp dl, '9'
    jg ascii_to_int_error_label
    sub dl, '0'                 ; convierte a dígito (0–9)

    ; Comprobación de overflow:
    cmp rax, rbx
    ja ascii_to_int_error_label
    je check_last_digit_simple
    ; Si no hay riesgo, actualizar acumulador:
    imul rax, rax, 10
    add rax, rdx
    inc rsi
    dec r13d
    jmp ascii_to_int_loop

check_last_digit_simple:
    ; Si rax == 214748364, sólo se permite dígito <= 7.
    movzx edx, byte ptr [rsi]
    sub dl, '0'
    cmp dl, 7
    ja ascii_to_int_error_label
    imul rax, rax, 10
    add rax, rdx
    inc rsi
    dec r13d
    jmp ascii_to_int_loop

ascii_to_int_done_loop:
    jmp ascii_to_int_done
ascii_to_int_done_zero:
    xor rax, rax
    jmp ascii_to_int_done
ascii_to_int_error_label:
    mov eax, -1

ascii_to_int_done:
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    pop rbp
    ret
ascii_to_int ENDP


;-----------------------------------------------------------
; gcd PROC:
;   Calcula el máximo común divisor (MCD) usando el algoritmo de Euclides.
;   Entrada: RCX = a, RDX = b (valores de 32 bits)
;   Salida: EAX = gcd(a, b)
;-----------------------------------------------------------
gcd PROC
    push rbx
    mov eax, ecx        ; a
    mov ebx, edx        ; b
gcd_loop:
    cmp ebx, 0
    je gcd_done
    xor edx, edx
    div ebx             ; EAX = a div b, EDX = a mod b.
    mov eax, ebx
    mov ebx, edx
    jmp gcd_loop
gcd_done:
    pop rbx
    ret
gcd ENDP


;-----------------------------------------------------------
; mcm PROC:
;   Calcula el mínimo común múltiplo (MCM) usando:
;
;         mcm = (a * b) / gcd(a, b)
;
; Se verifica que la multiplicación no exceda el máximo entero de 32 bits.
; Entrada: RCX = a, RDX = b (32 bits)
; Salida: EAX = mcm o -1 en caso de overflow
;-----------------------------------------------------------
mcm PROC
    ; Check if any input is zero.
    cmp ecx, 0
    je mcm_zero_no_push
    cmp edx, 0
    je mcm_zero_no_push

    push rbx              ; Push RBX ONLY once now.
    mov r8d, ecx          ; a -> r8d
    mov r9d, edx          ; b -> r9d

    ; Comprobación de overflow en la multiplicación:
    ; Si a > (max_int_val / b) se produciría overflow.
    mov eax, dword ptr [max_int_val]
    mov ebx, r9d
    xor edx, edx
    div ebx             ; EAX = max_int_val / b
    cmp r8d, eax
    ja mcm_overflow_pop

    ; Calcula el producto (a * b).
    mov eax, r8d
    imul eax, r9d
    mov r10d, eax       ; almacena el producto en r10d

    ; Calcula gcd(a, b).
    mov ecx, r8d
    mov edx, r9d
    call gcd
    mov ebx, eax        ; EBX = gcd

    ; Calcula mcm = (a * b) / gcd.
    mov eax, r10d
    xor edx, edx
    div ebx

    pop rbx             ; Balance the stack before return.
    ret

mcm_overflow_pop:
    mov eax, -1
    pop rbx             ; Pop the saved register.
    ret

mcm_zero_no_push:
    mov eax, 0         ; If either input is 0, return 0.
    ret
mcm ENDP



;-----------------------------------------------------------
; int_to_ascii PROC:
;   Convierte un entero de 32 bits (en ECX) a una hilera ASCII 
;   null-terminada.
;   Se usa un buffer temporal local para generar los dígitos en orden inverso,
;   para luego vaciarlos al destino en orden correcto.
;
;   Entrada: 
;       RCX = número entero (32 bits)
;       RDX = puntero al buffer donde colocar la cadena (suficiente espacio).
;-----------------------------------------------------------
int_to_ascii PROC
    push rbp
    mov  rbp, rsp
    push r12            ; Save nonvolatile register r12.
    push rdi            ; Save RDI which will hold our safe copy of RDX.
    sub  rsp, 32        ; Reserve space for the temporary buffer.

    ; Save the destination pointer from RDX in RDI.
    mov rdi, rdx       

    ; If the number is zero, write "0" and terminate.
    mov eax, ecx
    cmp eax, 0
    jne int_to_ascii_convert
    mov byte ptr [rdi], '0'
    mov byte ptr [rdi+1], 0
    jmp int_to_ascii_done

int_to_ascii_convert:
    lea r8, [rbp-32]      ; r8 = temporary buffer base.
    xor r10d, r10d        ; digit counter = 0.

int_to_ascii_loop:
    cmp eax, 0
    je int_to_ascii_loop_end
    xor edx, edx         ; Clear EDX (part of the dividend for div).
    mov ebx, 10
    div ebx              ; Divide EDX:EAX by 10.
    add dl, '0'
    mov byte ptr [r8 + r10], dl   ; Store digit in temporary buffer.
    inc r10d
    jmp int_to_ascii_loop

int_to_ascii_loop_end:
    ; Setup for reverse copy (r10d = number of digits).
    lea r12, [r8 + r10 - 1]  ; r12 points to last digit in the temporary buffer.

int_to_ascii_reverse_loop:
    cmp r10d, 0
    je int_to_ascii_write_null
    mov al, byte ptr [r12]
    mov byte ptr [rdi], al   ; Use RDI (the safe copy) instead of RDX.
    inc rdi                ; Increment our destination pointer.
    dec r12
    dec r10d
    jmp int_to_ascii_reverse_loop

int_to_ascii_write_null:
    mov byte ptr [rdi], 0   ; Write null terminator.

int_to_ascii_done:
    add rsp, 32
    pop rdi             ; Restore RDI.
    pop r12             ; Restore R12.
    pop rbp
    ret
int_to_ascii ENDP




;-----------------------------------------------------------
; string_copy PROC:
;   Copia una cadena ASCII (null-terminada) desde la fuente a destino.
;   Entrada: 
;       RCX = puntero al destino
;       RDX = puntero a la fuente
;-----------------------------------------------------------
string_copy PROC
    push rbp
    mov rbp, rsp
    mov rdi, rcx      ; destino
    mov rsi, rdx      ; fuente
string_copy_loop:
    lodsb             ; carga byte en AL desde [rsi] y avanza rsi
    stosb             ; almacena AL en [rdi] y avanza rdi
    cmp al, 0
    jne string_copy_loop
    pop rbp
    ret
string_copy ENDP

;-----------------------------------------------------------
END
