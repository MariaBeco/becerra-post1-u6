; =============================================================================
; lab6_instrucciones.asm - Categorias de instrucciones x86 (Post1 U6, Parte 1)
; Estudiante: Maria Fernanda Becerra Coronel - 1152509
; Compilar:   nasm -f bin lab6_instrucciones.asm -o lab6_instrucciones.com
; Formato .COM: CS = DS = ES = SS, el programa empieza en el offset 0100h
; =============================================================================
org  100h                   ; los primeros 256 bytes son el PSP de DOS

; -- Datos --------------------------------------------------------------------
        jmp  inicio         ; saltar sobre los datos hacia el codigo

valor_a     dw  45          ; primer operando  (002Dh)
valor_b     dw  12          ; segundo operando (000Ch)
resultado   dw  0           ; guarda el resultado del ADD
contador    db  5           ; contador de bucle
mascara     db  0Fh         ; mascara de los 4 bits bajos

; -- Codigo -------------------------------------------------------------------
inicio:

; == BLOQUE 1: Transferencia de datos =========================================
        mov  ax, [valor_a]      ; AX = 45  (contenido de valor_a)
        mov  bx, [valor_b]      ; BX = 12  (contenido de valor_b)

        mov  cx, ax             ; CX = AX = 45 (registro a registro)
        mov  dx, bx             ; DX = BX = 12

        lea  si, [valor_a]      ; SI = direccion de valor_a, no su valor
        mov  ax, [si]           ; AX = mem[SI] = 45 (acceso indirecto)

        xchg cx, dx             ; intercambio: CX = 12, DX = 45
        xchg cx, dx             ; restaurar:   CX = 45, DX = 12

        push ax                 ; guardar AX = 45 en la pila
        mov  ax, 0FFFFh         ; modificar AX temporalmente
        pop  ax                 ; restaurar AX = 45

; == BLOQUE 2: Operaciones aritmeticas ========================================
        mov  ax, [valor_a]      ; AX = 45
        add  ax, [valor_b]      ; AX = 45 + 12 = 57 (0039h); ZF=0 CF=0 OF=0
        mov  [resultado], ax    ; guardar 57 en memoria

        mov  ax, [valor_b]      ; AX = 12
        sub  ax, [valor_a]      ; AX = 12 - 45 = -33 (FFDFh); SF=1 CF=1 OF=0

        mov  ax, [valor_a]      ; AX = 45
        inc  ax                 ; AX = 46 (INC no modifica CF)
        dec  ax                 ; AX = 45 (DEC no modifica CF)

        mov  al, 10             ; AL = 10
        mov  bl, 7              ; BL = 7
        mul  bl                 ; AX = AL * BL = 70 (0046h)

        mov  ax, 100            ; AX = 100 (dividendo)
        mov  bl, 7              ; BL = 7   (divisor)
        div  bl                 ; AL = 14 (cociente), AH = 2 (resto) -> AX = 020Eh

; == BLOQUE 3: Operaciones logicas ============================================
        mov  al, 0B7h           ; AL = 1011 0111b
        and  al, [mascara]      ; AL = B7h AND 0Fh = 07h (limpia bits altos)

        mov  al, 0B7h           ; restaurar AL
        or   al, 0F0h           ; AL = B7h OR F0h = F7h (activa bits altos)

        mov  al, 0AAh           ; AL = 1010 1010b
        xor  al, 0FFh           ; AL = 55h (invierte todos los bits)

        xor  bx, bx             ; BX = 0 (forma corta de poner a cero)

        mov  al, 0B7h           ; AL = 1011 0111b
        test al, 01h            ; AND sin guardar: ZF=0 porque el bit 0 vale 1

        mov  al, 08h            ; AL = 8
        shl  al, 2              ; AL = 8 * 4 = 32 (20h)
        shr  al, 1              ; AL = 32 / 2 = 16 (10h)

; == BLOQUE 4: Control de flujo ===============================================
        ; if/else: comparar valor_a con valor_b (con signo)
        mov  ax, [valor_a]      ; AX = 45
        cmp  ax, [valor_b]      ; 45 - 12 = 33 > 0 -> ZF=0 SF=0 OF=0
        jg   .mayor             ; salta si AX > valor_b
        je   .igual             ; salta si AX = valor_b
        xor  cx, cx             ; caso menor: CX = 0 (no se alcanza)
        jmp  .fin_cmp
.mayor:
        mov  cx, 1              ; CX = 1: valor_a > valor_b
        jmp  .fin_cmp
.igual:
        mov  cx, 2              ; CX = 2: valores iguales
.fin_cmp:

        ; Bucle de suma acumulada 1 + 2 + 3 + 4 + 5
        xor  ax, ax             ; AX = 0 (acumulador)
        mov  cx, 5              ; CX = 5 iteraciones
        mov  bx, 1              ; BX = primer valor a sumar
.bucle_suma:
        add  ax, bx             ; AX += BX
        inc  bx                 ; BX = siguiente valor
        loop .bucle_suma        ; CX--; si CX != 0 repite
fin_suma:                       ; aqui AX = 15 (000Fh)

        ; Variante (Checkpoint 3): factorial 5! = 1*2*3*4*5 = 120
        mov  ax, 1              ; AX = 1 (acumulador del producto)
        mov  cx, 5              ; CX = 5 iteraciones
        mov  bx, 1              ; BX = primer factor
.bucle_fact:
        mul  bx                 ; DX:AX = AX * BX (DX queda en 0)
        inc  bx                 ; BX = siguiente factor
        loop .bucle_fact        ; CX--; si CX != 0 repite
fin_fact:                       ; aqui AX = 120 (0078h)

        int  20h                ; retornar a DOS
