;  MCD.asm (x64)

option casemap:none  ;  Sensible a mayúsculas/minúsculas

PUBLIC _MCD  ;  Hacemos _MCD visible desde otros módulos

.CODE
_TEXT SEGMENT ;  Inicio del segmento de código
_MCD PROC
;  Convención de llamada x64 (Windows):
;  RCX = a
;  RDX = b

    MOV RAX, RCX  ;  RAX = a
    MOV R8, RDX   ;  R8  = b
    XOR RDX, RDX  ;  RDX = 0 (para la división)

ciclo_MCD:
    CMP R8, 0         ; Compara el valor de R8 con 0. Si R8 es 0, salta a la etiqueta "fin_ciclo_MCD"
    JE  fin_ciclo_MCD  ; Si la comparación anterior es verdadera, salta a la etiqueta "fin_ciclo_MCD"

    MOV RCX, R8        ; Copia el valor de R8 en RCX (temp = b)
    MOV R8, RDX        ; Copia el valor de RDX en R8 (b = r)
    XOR RDX, RDX       ; Pone a cero el valor de RDX (residuo = 0)
    DIV RCX            ; Divide RAX entre RCX (cociente = RAX, residuo = RDX)
    MOV RDX, RCX       ; Copia el valor de RCX en RDX (a = temp)

    JMP ciclo_MCD      ; Salta a la etiqueta "ciclo_MCD" para repetir el ciclo

fin_ciclo_MCD:
    MOV RAX, R8  ;  El MCD se devuelve en RAX
    RET
_MCD ENDP
_TEXT ENDS   ;  Fin del segmento de código

END