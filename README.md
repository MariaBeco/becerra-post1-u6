# becerra-post1-u6

**Laboratorio Post-contenido 1, Unidad 6: Instrucciones y Direccionamiento — Programación en NASM sobre DOSBox**
Arquitectura de Computadores · Universidad Francisco de Paula Santander

- **Estudiante:** Maria Fernanda Becerra Coronel
- **Código:** 1152509
- **Docente:** Ing. Jonathan Rey

## Descripción

El laboratorio tiene dos partes que se entregan en este mismo repositorio. En la **Parte 1**, el programa `lab6_instrucciones.asm` recorre las cuatro categorías de instrucciones x86: transferencia de datos, aritmética, lógica y control de flujo. Además incluye un Bloque 5 que compara las rotaciones `ROL`/`ROR` con los desplazamientos `SHL`/`SHR`. En la **Parte 2**, el programa `lab6_modos.asm` accede a los mismos datos (un array de cinco palabras y un registro de tres campos) con los cuatro modos de direccionamiento: inmediato, directo, indirecto por registro e indexado. Los extiende con un marco de variables locales basado en `BP` y con el acceso a una matriz 3×3 mediante doble indexación. Los dos programas se ensamblaron con NASM dentro de DOSBox y se verificaron instrucción por instrucción con DEBUG.

## Estructura del repositorio

```
becerra-post1-u6/
├── lab6_instrucciones.asm   Parte 1: categorías de instrucciones y rotación
├── lab6_instrucciones.com   Ejecutable .COM de la Parte 1
├── lab6_modos.asm           Parte 2: modos de direccionamiento, marco BP y matriz
├── lab6_modos.com           Ejecutable .COM de la Parte 2
├── capturas/                Evidencia de compilación y sesiones de DEBUG
└── README.md
```

## Entorno y compilación

| Elemento | Valor |
|---|---|
| Emulador | DOSBox 0.74-3, `cycles=3000` |
| Ensamblador | NASM 2.16.03 para DOS (`nasm.exe` con `CWSDPMI.EXE`) |
| Depurador | DEBUG para DOS (versión libre de FreeDOS) |
| Carpeta montada | `mount c c:\lab5` |

DOSBox 0.74 solo maneja nombres de archivo DOS de 8.3 caracteres. Por eso, dentro de DOSBox, los fuentes se ensamblaron con nombres cortos y luego se copiaron al repositorio con los nombres que pide la guía. El contenido es el mismo:

```
nasm -f bin lab6i.asm -o lab6i.com      ; lab6_instrucciones.asm
nasm -f bin lab6m.asm -o lab6m.com      ; lab6_modos.asm
```

Los dos ensamblan sin errores ni advertencias. En formato `.COM`, `CS`, `DS`, `ES` y `SS` apuntan al mismo segmento, el programa empieza en el offset `0100h` y la pila arranca en `SP=FFFEh`. Las direcciones de este README son offsets dentro de ese segmento.

---

# Parte 1: Programa de instrucciones mixtas

## Mapa de memoria de los datos

| Etiqueta | Offset | Valor | Bytes en memoria (little-endian) |
|---|---|---|---|
| `valor_a` | `0102h` | 45 | `2D 00` |
| `valor_b` | `0104h` | 12 | `0C 00` |
| `resultado` | `0106h` | 0, y 57 tras el `ADD` | `00 00` → `39 00` |
| `contador` | `0108h` | 5 | `05` |
| `mascara` | `0109h` | 0Fh | `0F` |

## Bloque 1: Transferencia de datos

`MOV` copia valores de memoria a registro (`AX=002Dh`, `BX=000Ch`) y entre registros (`CX=002Dh`, `DX=000Ch`). `LEA si, [valor_a]` carga en `SI` la **dirección** `0102h`, no el contenido, y `MOV ax, [si]` usa esa dirección para volver a leer 45. `XCHG cx, dx` intercambia los dos registros y la segunda `XCHG` los deja como estaban. `PUSH ax` baja `SP` de `FFFE` a `FFFC`, `MOV ax, 0FFFFh` cambia `AX` y `POP ax` lo restaura a `002Dh` con `SP` de nuevo en `FFFE`. Ninguna de estas instrucciones modifica los flags.

## Bloque 2: Operaciones aritméticas

| Instrucción | Resultado | Flags en DEBUG | Lectura |
|---|---|---|---|
| `ADD ax, [valor_b]` | `AX=0039h` (57) | `NV UP EI PL NZ AC PE NC` | CF=0, ZF=0, OF=0, SF=0. AF=1 porque D+C desborda el nibble bajo |
| `SUB ax, [valor_a]` | `AX=FFDFh` (−33) | `NV UP EI NG NZ AC PO CY` | SF=1 (negativo), CF=1 (12 < 45 sin signo, hubo préstamo), OF=0 |
| `INC ax` / `DEC ax` | `002Eh` / `002Dh` | `CY` se mantiene | `INC` y `DEC` no tocan CF |
| `MUL bl` (10 × 7) | `AX=0046h` (70) | `NC` | La parte alta (AH) es 0, por eso CF=OF=0 |
| `DIV bl` (100 / 7) | `AX=020Eh` | — | AL=0Eh (14, cociente), AH=02h (2, resto) |

El resultado del `ADD` queda guardado en `resultado` (offset `0106h`) como `39 00`.

## Bloque 3: Operaciones lógicas

| Instrucción | Antes | Después | Flags | Efecto |
|---|---|---|---|---|
| `AND al, [mascara]` | `AL=B7h` | `AL=07h` | `PL NZ PO NC` | Limpia los 4 bits altos |
| `OR al, 0F0h` | `AL=B7h` | `AL=F7h` | `NG NZ` | Activa los 4 bits altos |
| `XOR al, 0FFh` | `AL=AAh` | `AL=55h` | `PL NZ` | Invierte todos los bits |
| `XOR bx, bx` | `BX=0007h` | `BX=0000h` | `ZR` | Pone el registro a cero con 2 bytes |
| `TEST al, 01h` | `AL=B7h` | `AL=B7h` | `NZ PO NC` | ZF=0: el bit 0 vale 1 (número impar); AL no cambia |
| `SHL al, 2` | `AL=08h` | `AL=20h` | `NC` | 8 × 4 = 32 |
| `SHR al, 1` | `AL=20h` | `AL=10h` | `NC` | 32 / 2 = 16 |

## Bloque 4: Control de flujo

`CMP ax, [valor_b]` calcula 45 − 12 = 33 sin guardar el resultado y deja `NV PL NZ NA PE NC`. Como ZF=0 y SF=OF, `JG .mayor` salta y `CX` queda en `0001h`, lo que confirma que `valor_a > valor_b`.

El bucle de suma usa `CX=5` como contador y `BX` como valor que se suma. Valores registrados con DEBUG en cada vuelta, al llegar a `LOOP`:

| Iteración | BX sumado | AX | CX tras `LOOP` |
|---|---|---|---|
| 1 | 1 | `0001h` | `0004h` |
| 2 | 2 | `0003h` | `0003h` |
| 3 | 3 | `0006h` | `0002h` |
| 4 | 4 | `000Ah` | `0001h` |
| 5 | 5 | `000Fh` | `0000h` |

Al salir del bucle, en `fin_suma` (offset `0186h`), **AX = 000Fh = 15**.

### Variante: factorial de 5

La variante del Checkpoint 3 reemplaza `ADD ax, bx` por `MUL bx`. También cambia el valor inicial del acumulador a `AX=1`, porque el elemento neutro del producto es 1 y no 0. Cada vuelta multiplica `DX:AX = AX × BX` y luego incrementa `BX`. `AX` pasa por 1, 2, 6, 24 (`18h`) y 120. En `fin_fact` (offset `0194h`) queda **AX = 0078h = 120** y `DX = 0000h`, porque el producto nunca supera 16 bits. Esta variante se agregó en un commit propio.

## Bloque 5: Rotación — ROL/ROR frente a SHL/SHR

Las cuatro primeras operaciones parten del mismo valor, `AL = 81h = 1000 0001b`, que tiene en 1 el bit 7 y el bit 0. Así se ven afectados los dos extremos:

| Instrucción | Registro | Antes | Después | CF | Qué pasó con el bit que sale |
|---|---|---|---|---|---|
| `SHL bl, 1` | BL | `81h` | `02h` (`0000 0010b`) | 1 | El bit 7 se perdió; solo queda en CF |
| `ROL cl, 1` | CL | `81h` | `03h` (`0000 0011b`) | 1 | El bit 7 volvió a entrar como bit 0 |
| `SHR dl, 1` | DL | `81h` | `40h` (`0100 0000b`) | 1 | El bit 0 se perdió; solo queda en CF |
| `ROR bh, 1` | BH | `81h` | `C0h` (`1100 0000b`) | 1 | El bit 0 volvió a entrar como bit 7 |
| `ROL al, 4` | AL | `A5h` | `5Ah` | 0 | Los nibbles A y 5 se intercambiaron |

Las cuatro dejan CF=1 porque en los dos casos el bit que sale vale 1. La diferencia está en el registro. Con `SHL`/`SHR` ese bit desaparece. Con `ROL`/`ROR` reaparece en el extremo opuesto. Tras el bloque, DEBUG muestra `BX=C002h` (BH=C0h, BL=02h), `CX=0003h`, `DX=0040h` y `AX=005Ah`.

## Decisiones técnicas — Parte 1

### Decisión 1: ¿SHL/SHR o ROL/ROR para esta manipulación de bits?

La elección depende de si el bit que sale del registro debe descartarse o conservarse. `SHL` y `SHR` son las adecuadas para la aritmética, como en el Bloque 3, donde `SHL al, 2` multiplicó 8 por 4 y `SHR al, 1` dividió 32 entre 2. Al multiplicar o dividir por una potencia de 2, el bit que sale no forma parte del resultado numérico: o es un desbordamiento, que CF ya reporta, o es el resto de la división. Por eso tiene sentido que se pierda. `ROL` y `ROR` son las adecuadas cuando ningún bit puede perderse: intercambiar los nibbles de un byte, implementar un cifrado por rotación o calcular un checksum circular, donde cada bit del dato original tiene que seguir presente. El intercambio de nibbles no puede lograrse con `SHL`, sin importar cuántas veces se aplique. Cada desplazamiento rellena con ceros por la derecha y expulsa por la izquierda los bits del nibble alto. Tras `SHL al, 4` sobre `A5h`, el nibble A ya no existe en el registro (`AL=50h`). Un `OR` posterior solo puede activar bits, no recuperar información que se borró. Habría que guardar antes una copia del valor y desplazarla en sentido contrario, lo que ya es otra operación. `ROL al, 4` lo hace en una sola instrucción, porque los cuatro bits que salen por la izquierda entran por la derecha. Lo mismo se observó en DEBUG con `AL=81h`. Tras `SHL bl, 1`, el bit 7 original, que valía 1, desapareció del registro (`BL=02h`) y solo quedó visible en CF. Tras `ROL cl, 1` sobre el mismo valor, ese bit reapareció como el nuevo bit 0 (`CL=03h`). Esa diferencia decide la instrucción: si el bit expulsado es información que se necesita, se usa una rotación; si es un sobrante de la aritmética, se usa un desplazamiento.

### Decisión 2: ¿LOOP o DEC/JNZ para el bucle del Bloque 4?

`LOOP .bucle_suma` hace en una sola instrucción lo que `DEC cx` seguido de `JNZ .bucle_suma` hace en dos. Además, ocupa 2 bytes (`E2 FB`) frente a los 3 de la pareja (`49` y `75 xx`). Deja claro en el código fuente que se trata de un bucle contado con `CX` y evita olvidar el decremento. Sin embargo, el número de instrucciones escritas no indica cuántos ciclos de reloj tardará la ejecución. Cada instrucción tiene su propio costo de decodificación y ejecución, y ese costo depende de la microarquitectura. En el 8086 original `LOOP` tomaba unos 17 ciclos cuando saltaba, frente a los 2 de `DEC` más los 16 de `JNZ`, así que era ligeramente más rápida. A partir del 80486, y de forma muy marcada en los procesadores actuales de Intel y AMD, `LOOP` se implementa con microcódigo o como varias microoperaciones y no se fusiona con otras instrucciones. En cambio, `DEC` y `JNZ` son instrucciones simples que el decodificador puede fusionar en una sola microoperación, de modo que una sola instrucción puede ser la más lenta de las dos opciones. Para el bucle de 5 iteraciones del Bloque 4, la diferencia sería de unas decenas de ciclos, es decir, nanosegundos, y no se notaría ni dentro de DOSBox, cuya velocidad la fija el parámetro `cycles` y no el procesador real. La respuesta cambia si el mismo bucle se ejecuta millones de veces dentro de un programa más grande: ahí los ciclos de más por iteración se multiplican y `DEC/JNZ` es la opción recomendada en código moderno. Para este laboratorio se mantuvo `LOOP` porque prioriza la legibilidad y el ejemplo de la guía.

---

# Parte 2: Demostración de modos de direccionamiento

## Mapa de memoria de los datos

Dump obtenido con `d 100` en DEBUG:

| Etiqueta | Offset | Valores | Bytes en memoria |
|---|---|---|---|
| `array` | `0102h` | 10, 20, 30, 40, 50 | `0A 00 14 00 1E 00 28 00 32 00` |
| `nota1` | `010Ch` | 85 | `55 00` |
| `nota2` | `010Eh` | 73 | `49 00` |
| `promedio` | `0110h` | 0, y 79 tras el modo indirecto | `00 00` → `4F 00` |
| `var_x` | `0112h` | 0FFFFh, y 0 tras el modo directo | `FF FF` → `00 00` |
| `tabla_hex` | `0114h` | "0123456789ABCDEF" | `30 31 … 46` |
| `matriz` | `0124h` | 1 a 9, por filas | `01 00 02 00 03 00 04 00 05 00 06 00 07 00 08 00 09 00` |

## Tabla resumen de los modos de direccionamiento

| Modo | Dirección efectiva (EA) | Instrucción NASM | Valor observado en DEBUG |
|---|---|---|---|
| Inmediato | No hay acceso a memoria de datos: el operando va en el opcode | `mov ax, 100` | `U` muestra `MOV AX,0064` (`B8 64 00`); `AX=0064h` |
| Directo | EA = desplazamiento fijo | `mov ax, [var_x]` | `U` muestra `MOV AX,[0112]`; `AX=FFFFh` |
| Directo (escritura) | EA = `0112h` | `mov word [var_x], 0` | `var_x` pasa de `FF FF` a `00 00` |
| Indirecto por registro | EA = SI | `mov ax, [si]` con `SI=010Ch` | `AX=0055h` (85) |
| Indexado base + índice | EA = BX + SI | `mov ax, [bx + si]` con `BX=0102h`, `SI=0004h` | EA = `0106h`, `AX=001Eh` (30 = `array[2]`) |
| Indexado en bucle | EA = BX + SI, con SI = 0, 2, 4, 6, 8 | `add ax, [bx + si]` | `AX=0096h` (150) al final |
| Base + desplazamiento | EA = BX + d | `mov dx, [bx + 4]` con `BX=010Ch` | EA = `0110h`, `DX=004Fh` (79) |
| Indirecto con BP (marco de pila) | EA = BP − d, segmento **SS** | `mov ax, [bp - 2]` con `BP=FFFCh` | EA = `SS:FFFAh`, `AX=0063h` (99) |
| Doble indexación (matriz) | EA = base + fila·6 + columna·2 | `mov dx, [bx + si]` con `BX=0124h`, `SI=000Ah` | EA = `012Eh`, `DX=0006h` |

## Modo inmediato y modo directo

En el modo inmediato, el valor forma parte de la instrucción. Al desensamblar con `u 136`, `MOV AX,0064` aparece codificada como `B8 64 00`: el 64h (100) está en el propio opcode, y la CPU no lee ninguna dirección de datos para obtenerlo. En el modo directo, lo que va en el opcode es la **dirección**. `MOV AX,[0112]` se codifica como `A1 12 01`, y la CPU lee la palabra de `DS:0112h` (`var_x`), por lo que `AX=FFFFh`. Con `mov bx, [array]` se obtiene `BX=000Ah` (10) y con `mov cx, [nota1]`, `CX=0055h` (85). Después, `mov word [var_x], 0` escribe en memoria, y el dump confirma que `0112h` pasa a `00 00`.

## Trazado del modo indirecto por registro

Sesión de DEBUG desde `g 154` y luego `t` paso a paso:

| Instrucción | Registro modificado | Valor resultante |
|---|---|---|
| `mov si, nota1` | SI | `0000h` antes, `010Ch` después |
| `mov ax, [si]` | AX | `0055h` (85) |
| `mov si, nota2` | SI | `010Eh` |
| `mov bx, [si]` | BX | `0049h` (73) |
| `add ax, bx` | AX | `009Eh` (158) |
| `shr ax, 1` | AX | `004Fh` (79) |
| `mov si, promedio` | SI | `0110h` |
| `mov [si], ax` | memoria `0110h` | `4F 00` (79) |

La instrucción `mov ax, [si]` es la misma las dos veces; lo único que cambia entre los dos accesos es el valor de `SI`. Esa es la idea de un puntero: la dirección se decide en tiempo de ejecución.

## Modo indexado y recorrido inverso

`mov ax, [bx + si]` con `BX=0102h` y `SI=0004h` lee `array[2]`: EA = `0102h + 4 = 0106h`, y `AX=001Eh` (30). En el bucle de suma, `SI` avanza de 2 en 2 (0, 2, 4, 6, 8), porque cada elemento ocupa una palabra. `AX` pasa por 10, 30, 60, 100 y 150. En `fin_array` (offset `0199h`), **AX = 0096h = 150**.

La extensión recorre el array al revés. Empieza en `SI=8`, que es `array[4]`, y resta 2 en cada vuelta. `AX` pasa por 50, 90, 120, 140 y 150. En `fin_inverso` (offset `01ABh`) también queda **AX = 0096h = 150**. `SI` termina en `FFFEh`, porque la última resta se hace después de leer `array[0]`, pero ese valor ya no se usa para leer. Esta extensión está en el commit "feat: recorrido inverso del array".

Al final del bloque, `BX = nota1 = 010Ch` sirve como base del "registro de estudiante". `[bx]`, `[bx + 2]` y `[bx + 4]` devuelven `AX=0055h`, `CX=0049h` y `DX=004Fh` (85, 73 y el promedio 79).

## Marco de pila con BP

| Momento | SP | BP | Observación |
|---|---|---|---|
| Antes del bloque | `FFFEh` | `0000h` | Valores iniciales del `.COM` |
| Tras `push bp` / `mov bp, sp` | `FFFCh` | `FFFCh` | BP queda igual a SP: base del marco |
| Tras `sub sp, 4` | `FFF8h` | `FFFCh` | Se reservan 4 bytes para dos locales |
| Tras escribir los locales | `FFF8h` | `FFFCh` | `d ss:fff8 l 4` muestra `FA 00 63 00` |
| Tras `add ax, [bp - 4]` | `FFF8h` | `FFFCh` | `AX=015Dh` (349) |
| Tras `mov sp, bp` / `pop bp` | `FFFEh` | `0000h` | BP y SP vuelven a los valores de antes del bloque |

`local_1 = 99` está en `SS:BP−2 = SS:FFFAh` (`63 00`) y `local_2 = 250` en `SS:BP−4 = SS:FFF8h` (`FA 00`). Por eso, al volcar 4 bytes desde `FFF8h`, primero aparece `FA 00` y luego `63 00`. DEBUG no acepta expresiones como `bp-4` en el comando `d`, así que se usa la dirección calculada: `FFFCh − 4 = FFF8h`.

## Acceso a la matriz con doble indexación

`matriz[1][2]` se ubica así: EA = base + fila × (3 elementos × 2 bytes) + columna × 2 bytes = `0124h + 6 + 4 = 012Eh`.

| Instrucción | Registro | Valor |
|---|---|---|
| `mov ax, 1` / `mov bx, 3` / `mul bx` | AX | `0003h` (fila × ancho, en elementos) |
| `shl ax, 1` | AX | `0006h` (desplazamiento de fila en bytes) |
| `mov si, ax` | SI | `0006h` |
| `mov cx, 2` / `shl cx, 1` | CX | `0004h` (desplazamiento de columna en bytes) |
| `add si, cx` | SI | **`000Ah`** (10) |
| `mov bx, matriz` | BX | `0124h` |
| `mov dx, [bx + si]` | DX | **`0006h`** = `matriz[1][2]` |

## Decisiones técnicas — Parte 2

### Decisión 3: ¿modo directo o modo indexado para un elemento de posición fija?

`matriz[1][2]` siempre está en la misma dirección, `012Eh`, y esa dirección se conoce al compilar. En el Paso 7, el modo indexado necesitó, antes de leer el dato, un `MUL` (la instrucción más cara de las que se usaron: más de cien ciclos en un 8086 con operando de 16 bits), dos `SHL`, un `ADD` y varios `MOV` para cargar fila, columna y base: unas nueve instrucciones solo para calcular algo que ya se sabía. Con modo directo, `mov dx, [matriz + 10]` (en NASM, `[matriz + 1*6 + 2*2]`) deja ese cálculo al ensamblador. La dirección `012Eh` queda escrita en el opcode y la CPU hace una sola lectura de memoria, sin gastar ciclos ni registros (`AX`, `BX`, `CX`, `SI`) en aritmética de direcciones. Por eso, para un elemento de posición fija, el directo es más eficiente. El indexado deja de ser una mala elección y se vuelve indispensable cuando la fila o la columna no se conocen al compilar: un índice que viene de la entrada del usuario, de otro cálculo o de la variable de control de un bucle. En ese caso no existe una dirección fija que escribir en el opcode, y la EA tiene que calcularse en tiempo de ejecución con base más índice. Para recorrer las 9 posiciones y sumarlas, usar 9 etiquetas o 9 desplazamientos directos funcionaría para una matriz de 3×3, pero no es práctico. El código crece con cada elemento, hay que reescribirlo si cambia el tamaño de la matriz y no sirve si las dimensiones solo se conocen en ejecución. Un bucle indexado, como el de la suma del array, recorre cualquier tamaño con las mismas pocas instrucciones.

### Decisión 4: BP frente a BX/SI en direccionamiento indirecto

La arquitectura x86 asigna a cada registro base un segmento por defecto, y esa asignación refleja su uso previsto. `BP` está pensado para el marco de pila: guarda una copia fija de `SP` al entrar a un procedimiento, y desde ella se alcanzan los parámetros (`[bp+4]`, `[bp+6]`) y las variables locales (`[bp−2]`, `[bp−4]`) aunque `SP` siga cambiando con cada `PUSH`. Por eso `[bp + d]` usa **SS** por defecto. `BX`, `SI` y `DI` están pensados como punteros a datos globales y arreglos, y usan **DS**. Esta separación permite que la pila y los datos vivan en segmentos distintos sin escribir el segmento en cada instrucción. En este laboratorio, al ser un `.COM`, `CS = DS = ES = SS`. Por eso `[bp − 2]` y una lectura equivalente con `BX` llegan al mismo byte, y el resultado observable es idéntico. En un `.EXE` con segmentos separados, por ejemplo DS=1000h y SS=2000h, la diferencia sería crítica. Si un programa cargara en `BP` el offset de una variable global, esperando que `[bp + d]` apuntara al mismo sitio que `[bx + d]`, la CPU leería `SS:offset` en lugar de `DS:offset`. Obtendría basura de la pila sin ningún error visible, y si escribiera podría corromper direcciones de retorno guardadas en la pila. Para forzar a una instrucción con `BP` a usar DS se emplea un prefijo de sobrescritura de segmento: en NASM, `mov ax, [ds:bp + 2]`, que añade el byte `3Eh` antes del opcode. Tiene sentido, por ejemplo, en una rutina que usa `BP` como un registro base más para recorrer una estructura en el segmento de datos porque `BX`, `SI` y `DI` ya están ocupados. También cuando un procedimiento recibe en la pila un puntero cercano a datos de DS y quiere usar `BP` para indexarlo.

---

# Capturas

| # | Checkpoint | Archivo |
|---|---|---|
| P1-1 | Compilación de la Parte 1 sin errores en DOSBox | `capturas/p1_cp1_compilacion.png` |
| P1-2 | Trazado de `ADD`, `SUB`, `AND`, `TEST` y `CMP` con sus flags | `capturas/p1_cp2_flags.png` |
| P1-3 | `AX=000F` al final del bucle y `AX=0078` tras la variante factorial | `capturas/p1_cp3_bucle_factorial.png` |
| P1-4 | Bloque 5: BL=02, CL=03, DL=40, BH=C0 con CF=1 y AL=5A | `capturas/p1_cp4_rotacion.png` |
| P2-1 | Compilación de la Parte 2 y dump `d 100` con array, nota1 y nota2 | `capturas/p2_cp1_dump.png` |
| P2-2 | Trazado del modo indirecto (`SI`, `AX=0055`) | `capturas/p2_cp2_indirecto.png` |
| P2-3 | `AX=0096` al final del bucle normal y del inverso | `capturas/p2_cp3_indexado.png` |
| P2-4 | Marco BP: SP/BP, dump `SS:FFF8` y `AX=015D` | `capturas/p2_cp4_marco_bp.png` |
| P2-5 | Dump de la matriz y `SI=000A`, `DX=0006` | `capturas/p2_cp5_matriz.png` |
| P2-6 | Desensamblado `u 136` con los modos inmediato y directo | `capturas/p2_cp6_inmediato_directo.png` |

---

# Conclusiones

- **Los flags cuentan la historia de cada operación.** El mismo `SUB` que da −33 con signo deja CF=1, porque sin signo 12 − 45 requiere préstamo. Leer bien CF, ZF, SF y OF es lo que permite elegir el salto condicional correcto (`JG` con signo frente a `JA` sin signo).
- **Desplazar no es lo mismo que rotar.** `SHL`/`SHR` sirven para la aritmética por potencias de 2. `ROL`/`ROR` conservan todos los bits y por eso resuelven tareas como el intercambio de nibbles.
- **Menos instrucciones no significa menos ciclos.** `LOOP` es más corta y legible que `DEC/JNZ`, pero en procesadores modernos suele ser más lenta.
- **El modo de direccionamiento decide cuándo se calcula la dirección.** En el inmediato y el directo, el ensamblador la fija al compilar. En el indirecto y el indexado, la CPU la calcula en tiempo de ejecución. Esa flexibilidad es la que permite punteros, arreglos, matrices y bucles.
- **BP y BX no son intercambiables en general.** En un `.COM` dan el mismo resultado porque todos los segmentos coinciden. En un `.EXE`, BP trabaja sobre SS y BX sobre DS, y confundirlos produce errores silenciosos.
