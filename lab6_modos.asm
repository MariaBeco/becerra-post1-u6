; =============================================================================
; lab6_modos.asm - Modos de direccionamiento x86 (Post1 U6, Parte 2)
; Estudiante: Maria Fernanda Becerra Coronel - 1152509
; Compilar:   nasm -f bin lab6_modos.asm -o lab6_modos.com
; Formato .COM: CS = DS = ES = SS, el programa empieza en el offset 0100h
; =============================================================================
org  100h

; -- Datos de prueba ----------------------------------------------------------
        jmp  inicio

array       dw  10, 20, 30, 40, 50      ; 5 enteros de 16 bits

; Registro de estudiante: nota1 (+0), nota2 (+2), promedio (+4)
nota1       dw  85
nota2       dw  73
promedio    dw  0

var_x       dw  0FFFFh                  ; variable para el modo directo

tabla_hex   db  30h,31h,32h,33h,34h,35h,36h,37h
            db  38h,39h,41h,42h,43h,44h,45h,46h

; Matriz de 3 filas x 3 columnas de enteros de 16 bits (6 bytes por fila)
matriz      dw  1, 2, 3
            dw  4, 5, 6
            dw  7, 8, 9

inicio:

; == MODO 1: INMEDIATO ========================================================
; El operando va dentro del codigo de la instruccion (U muestra MOV AX,0064)
        mov  ax, 100            ; AX = 100 (0064h)
        mov  bx, 0A5h           ; BX = 00A5h
        add  cx, 55             ; CX += 55 (inmediato en aritmetica)
        and  dx, 00FFh          ; DX AND mascara inmediata

; == MODO 2: DIRECTO ==========================================================
; La direccion del operando va fija en la instruccion: EA = desplazamiento
        mov  ax, [var_x]        ; AX = mem[var_x] = FFFFh
        mov  bx, [array]        ; BX = mem[array] = 10 (000Ah)
        mov  cx, [nota1]        ; CX = mem[nota1] = 85 (0055h)
        mov  word [var_x], 0    ; escribe 0 en mem[var_x]

; == MODO 3: INDIRECTO POR REGISTRO ===========================================
; El registro guarda la direccion: EA = SI
        mov  si, nota1          ; SI = direccion de nota1 (no su valor)
        mov  ax, [si]           ; AX = mem[SI] = 85 (0055h)

        mov  si, nota2          ; SI = direccion de nota2
        mov  bx, [si]           ; BX = mem[SI] = 73 (0049h)

        add  ax, bx             ; AX = 85 + 73 = 158
        shr  ax, 1              ; AX = 158 / 2 = 79 (004Fh)
        mov  si, promedio       ; SI = direccion de promedio
        mov  [si], ax           ; mem[SI] = 79 (guarda via puntero)
fin_indirecto:

; == MODO 3b: INDIRECTO CON BP - marco de variables locales ===================
; BP es la base convencional para datos en la pila: por defecto usa SS (no DS)
        push bp                 ; preservar el BP anterior
        mov  bp, sp             ; BP = SP: base del nuevo marco de pila
        sub  sp, 4              ; reservar 2 palabras para variables locales

        mov  word [bp - 2], 99  ; local_1 = 99  (0063h) en SS:BP-2
        mov  word [bp - 4], 250 ; local_2 = 250 (00FAh) en SS:BP-4
locales_listos:

        mov  ax, [bp - 2]       ; AX = local_1 = 99
        add  ax, [bp - 4]       ; AX = 99 + 250 = 349 (015Dh)
suma_locales:

        mov  sp, bp             ; liberar las variables locales
        pop  bp                 ; restaurar el BP anterior
fin_marco:

; == MODO 4: INDEXADO (BASE + INDICE + DESPLAZAMIENTO) ========================
; EA = BX + SI (+ desplazamiento)
        mov  bx, array          ; BX = direccion base del array
        mov  si, 4              ; SI = 2 elementos * 2 bytes
        mov  ax, [bx + si]      ; AX = array[2] = 30 (001Eh)

        ; Suma de todos los elementos del array
        xor  ax, ax             ; AX = 0 (acumulador)
        mov  bx, array          ; BX = direccion base
        mov  cx, 5              ; CX = numero de elementos
        xor  si, si             ; SI = 0 (indice en bytes)
.bucle_array:
        add  ax, [bx + si]      ; AX += array[SI/2]
        add  si, 2              ; siguiente elemento (2 bytes)
        loop .bucle_array
fin_array:                      ; aqui AX = 150 (0096h)

        ; Extension: el mismo recorrido en orden inverso, de array[4] a array[0]
        xor  ax, ax             ; AX = 0 (acumulador)
        mov  bx, array          ; BX = direccion base
        mov  cx, 5              ; CX = numero de elementos
        mov  si, 8              ; SI = 4 * 2 bytes (ultimo elemento)
.bucle_inverso:
        add  ax, [bx + si]      ; AX += array[SI/2]
        sub  si, 2              ; elemento anterior (2 bytes)
        loop .bucle_inverso
fin_inverso:                    ; aqui AX = 150 (0096h) y SI = FFFEh

        ; Campos del "struct" con desplazamiento fijo: EA = BX + d
        mov  bx, nota1          ; BX = base del registro
        mov  ax, [bx]           ; AX = nota1    = 85 (offset 0)
        mov  cx, [bx + 2]       ; CX = nota2    = 73 (offset 2)
        mov  dx, [bx + 4]       ; DX = promedio = 79 (offset 4)

; == ACCESO A MATRIZ: doble indexacion (fila, columna) =======================
; EA = base + fila * (3 * 2 bytes) + columna * 2 bytes; elemento matriz[1][2]
        mov  ax, 1              ; AX = fila = 1
        mov  bx, 3              ; BX = ancho de fila = 3 elementos
        mul  bx                 ; AX = 1 * 3 = 3 elementos
        shl  ax, 1              ; AX = 3 * 2 = 6 bytes (desplazamiento de fila)
        mov  si, ax             ; SI = desplazamiento de fila

        mov  cx, 2              ; CX = columna = 2
        shl  cx, 1              ; CX = 2 * 2 = 4 bytes (desplazamiento de columna)
        add  si, cx             ; SI = 6 + 4 = 10 (000Ah)

        mov  bx, matriz         ; BX = direccion base de la matriz
        mov  dx, [bx + si]      ; DX = matriz[1][2] = 6 (0006h)
fin_matriz:

        int  20h                ; retornar a DOS
