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
    CMP R8, 0
    JE  fin_ciclo_MCD

    MOV RCX, R8    ;  temp = b
    MOV R8, RDX    ;  b    = r
    XOR RDX, RDX
    DIV RCX        ;  RAX  = cociente, RDX = residuo
    MOV RDX, RCX   ;  a    = temp

    JMP ciclo_MCD

fin_ciclo_MCD:
    MOV RAX, R8  ;  El MCD se devuelve en RAX
    RET
_MCD ENDP
_TEXT ENDS   ;  Fin del segmento de código

END