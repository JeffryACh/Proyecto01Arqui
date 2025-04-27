;  MCD.asm (x64)

option casemap:none  ;  Sensible a may�sculas/min�sculas

PUBLIC _MCD  ;  Hacemos _MCD visible desde otros m�dulos

.CODE
_TEXT SEGMENT ;  Inicio del segmento de c�digo
_MCD PROC
;  Convenci�n de llamada x64 (Windows):
;  RCX = a
;  RDX = b

    MOV RAX, RCX  ;  RAX = a
    MOV R8, RDX   ;  R8  = b
    XOR RDX, RDX  ;  RDX = 0 (para la divisi�n)

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
_TEXT ENDS   ;  Fin del segmento de c�digo

END