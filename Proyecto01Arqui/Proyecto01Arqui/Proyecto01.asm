;------------------------------------------------------------------
;Programa MCM
;Daniel Díaz
;Jeffrey


;-----------------------------------------------------------
;Calcular MCM
;mcm(a,b) = (a * b) / gcd(a,b)

EXTERN ExitProcess: PROC

.data
    ;Los números se definen en modo carácter
    ;Primer byte: longitud; luego la hilera de dígitos
    numA_str    byte 5, "10318" 
    numB_str    byte 4, "3147" 
    
    ;Variables para los números, de 32 bits
    numA        dd 0
    numB        dd 0
    mcm_result  dd 0
    
    ;Buffer para la hilera
    result_ascii  byte 12 dup(0)
    
    ;Cadena en caso de overflow
    overflow_str  byte "overflow", 0
    
    ;Valor máximo de entero
    max_int_val dd 2147483647

.code

;------------------------------------------------------------------
;main
main PROC

    sub rsp, 40

    ;-----A Entero
    lea rcx, numA_str         ;RCX = dirección de numA_str
    call ascii_to_int         ;resultado en EAX
    cmp eax, -1
    je main_overflow
    mov dword ptr [numA], eax

    ;-----String a Entero
    lea rcx, numB_str
    call ascii_to_int
    cmp eax, -1
    je main_overflow
    mov dword ptr [numB], eax

    ;-----MCM
    mov ecx, dword ptr [numA]
    mov edx, dword ptr [numB]
    call mcm
    cmp eax, -1
    je main_overflow
    mov dword ptr [mcm_result], eax

    ;-----A ASCII
    ;Se pasan: en ECX el número y en RDX la dirección del buffer resultado.
    mov ecx, dword ptr [mcm_result]
    lea rdx, result_ascii
    call int_to_ascii

    ;Termina
    mov ecx, 0      ;Primer parámetro en RCX
    call ExitProcess

main_overflow:
    ;Se copia la cadena "overflow" al buffer de resultado
    lea rcx, result_ascii    ;destino
    lea rdx, overflow_str    ;fuente
    call string_copy
    mov ecx, 0
    call ExitProcess
main ENDP


;------------------------------------------------------------------
;ASCII a Entero
;Pasa una hilera ASCII a un entero de 32 bits
;Hilera: primer byte = longitud, luego dígitos
;Entrada: RCX = dirección de la hilera
;Salida: EAX = entero (o -1 si da error u overflow)
ascii_to_int PROC
    push rbp
    mov rbp, rsp
    push rbx
    push rsi
    push rdi
    push r12
    push r13

    mov r12, rcx                ;r12 puntero a la hilera
    movzx eax, byte ptr [r12]   ;EAX longitud
    mov r13d, eax               ;r13d cantidad de dígitos
    cmp r13d, 0
    je ascii_to_int_done_zero
    lea rsi, [r12+1]            ;rsi apunta al primer dígito

    xor rax, rax                ;acumulador 0
    mov ebx, 214748364

ascii_to_int_loop:
    cmp r13d, 0
    je ascii_to_int_done_loop
    movzx edx, byte ptr [rsi]   ;edx carácter actual
    cmp dl, '0'
    jl ascii_to_int_error_label
    cmp dl, '9'
    jg ascii_to_int_error_label
    sub dl, '0'                 ;convierte a dígito del 0 al 9

    ;Comprueba overflow
    cmp rax, rbx
    ja ascii_to_int_error_label
    je check_last_digit_simple
    ;Si no hay riesgo, actualiza el acumulador
    imul rax, rax, 10
    add rax, rdx
    inc rsi
    dec r13d
    jmp ascii_to_int_loop

check_last_digit_simple:
    ;Si rax == 214748364, sólo se permite dígito <= 7.
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


;------------------------------------------------------------------
;gcd
;Entrada: RCX = a, RDX = b (32b)
;Salida: EAX = gcd(a, b)
gcd PROC
    push rbx
    mov eax, ecx        ;a
    mov ebx, edx        ;b
gcd_loop:
    cmp ebx, 0
    je gcd_done
    xor edx, edx
    div ebx
    mov eax, ebx
    mov ebx, edx
    jmp gcd_loop
gcd_done:
    pop rbx
    ret
gcd ENDP


;------------------------------------------------------------------
;MCM
;mcm = (a * b) / gcd(a, b)
;Verifica que la multiplicación no pase de 32 bits
;Entrada: RCX = a, RDX = b
;Salida: EAX = mcm o -1 si da overflow
mcm PROC
    ; Check if any input is zero.
    cmp ecx, 0
    je mcm_zero_no_push
    cmp edx, 0
    je mcm_zero_no_push

    push rbx 
    mov r8d, ecx 
    mov r9d, edx 

    ;Comprueba si da overflow en la multiplicación:
    ;Si a > (max_int_val / b) entonces da overflow.
    mov eax, dword ptr [max_int_val]
    mov ebx, r9d
    xor edx, edx
    div ebx             ; EAX = max_int_val / b
    cmp r8d, eax
    ja mcm_overflow_pop

    ;Calcula a*b
    mov eax, r8d
    imul eax, r9d
    mov r10d, eax       ;almacena en r10d

    ; Calcula gcd(a, b).
    mov ecx, r8d
    mov edx, r9d
    call gcd
    mov ebx, eax        ;EBX = gcd

    ;Calcula mcm = (a * b) / gcd.
    mov eax, r10d
    xor edx, edx
    div ebx

    pop rbx 
    ret

mcm_overflow_pop:
    mov eax, -1
    pop rbx 
    ret

mcm_zero_no_push:
    mov eax, 0         ;Si da 0, lo retorna
    ret
mcm ENDP



;------------------------------------------------------------------
;Entero a ASCII
;Convierte un entero de 32 bits a una hilera ASCII 
;Se usa un buffer temporal local para generar los dígitos en orden inverso, para luego vaciarlos al destino en orden.
;Entrada: RCX = número entero (32 bits), RDX = puntero al buffer donde colocar la cadena (suficiente espacio).
int_to_ascii PROC
    push rbp
    mov  rbp, rsp
    push r12 
    push rdi            ;RDI guarda a RDX
    sub  rsp, 32        ;Reserva espacio para el buffer temporal

    ;Guarda el puntero RDX en RDI
    mov rdi, rdx       

    ;Si el num es 0, lo escribe y termina
    mov eax, ecx
    cmp eax, 0
    jne int_to_ascii_convert
    mov byte ptr [rdi], '0'
    mov byte ptr [rdi+1], 0
    jmp int_to_ascii_done

int_to_ascii_convert:
    lea r8, [rbp-32] 
    xor r10d, r10d  

int_to_ascii_loop:
    cmp eax, 0
    je int_to_ascii_loop_end
    xor edx, edx
    mov ebx, 10
    div ebx              ;Divide EDX:EAX por 10.
    add dl, '0'
    mov byte ptr [r8 + r10], dl 
    inc r10d
    jmp int_to_ascii_loop

int_to_ascii_loop_end:
    ; Setup for reverse copy (r10d = number of digits).
    lea r12, [r8 + r10 - 1]  

int_to_ascii_reverse_loop:
    cmp r10d, 0
    je int_to_ascii_write_null
    mov al, byte ptr [r12]
    mov byte ptr [rdi], al  
    inc rdi                
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


;------------------------------------------------------------------
;Copiar String
;Copia una cadena ASCII
;Entrada RCX = puntero al destino, RDX = puntero a la fuente
string_copy PROC
    push rbp
    mov rbp, rsp
    mov rdi, rcx      ;destino
    mov rsi, rdx      ;fuente
string_copy_loop:
    lodsb             
    stosb             
    cmp al, 0
    jne string_copy_loop
    pop rbp
    ret
string_copy ENDP


END
