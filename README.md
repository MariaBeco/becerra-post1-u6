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

