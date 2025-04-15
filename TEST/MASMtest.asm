; Programa que implementa la funcion de Maximo Comun Divisor para variables enteras de 16 bits

includelib \Windows\System32\kernel32.dll

ExitProcess  proto

.data
    a   dw 365
    b   dw 70
    mcd dw ?

.code
main PROC

   push a       ; Prepara el stack frame para la llamada
   push b       ; a la funci�n MCD
   sub RSP,2    ;

   call _MCD     ; Recupera el valor calculado por MCD
   pop AX       ; y "limpia" la pila
   add RSP,4    ;

   mov mcd,AX   ; "Anuncia" el resultado

   call ExitProcess

main ENDP

_MCD PROC
; Stack Frame:
; (ret.addr.): +0
; (ret.val.):  +8
; b:           +10
; a:           +12

   mov R9w,[RSP+12]   ;R8 <- a
   mov R10w,[RSP+10]  ;R9 <- b
                      ;R10<-r
   mov AX,0

ciclo_MCD:           ; Ciclo "while" de MCD
   mov R8w,R9w       ; Corrimiento de los valores de b y r
   mov R9w,R10w      ;

   xor DX,DX         ; Prepara la division entera
   mov AX,R8w

   idiv R9w          ;Despu�s de idiv AX<-cociente, DX<-residuo
   mov R10w,DX
   cmp R10w,0
   je fin_ciclo_mcd
   jmp ciclo_MCD     ; Fin del "while" de MCD
fin_ciclo_MCD:
   mov [RSP+8],R9w
   ret

_MCD ENDP

END