
# PRÁCTICA 1: TORRES DE HANÓI (RECURSIVO)
# Integrantes: Gustavo Joya, Leonardo Figueroa

            .data
# Representación de las 3 torres en memoria de datos.
# Cada torre = 16 palabras (64 bytes):
#   torre[0]     = altura (cuántos discos tiene ahora)
#   torre[1..15] = discos, de abajo (1) hacia arriba
#   Un 0 en un slot significa "vacío". Soporta hasta 15 discos.
TorreA:     .space 64                   # 0x10010000
TorreB:     .space 64                   # 0x10010040
TorreC:     .space 64                   # 0x10010080

            .text
            .globl main
main:
            # Cargar número de discos N en el registro s0
            addi s0, x0, 8              # N = 3 discos (modificable)

            # Validación: solo se acepta 1 <= N <= 15
            beq  s0, x0, end   # N == 0: no hay nada que mover
            addi t0, x0, 15             # t0 = 15 (capacidad maxima de cada torre)
            blt  t0, s0, end   # si 15 < N: no caben hay que salir

            # Cargar identificadores/direcciones de las torres en a1, a2, a3
            lui  a1, 0x10010            # Dirección base de Torre A
            addi a1, a1, 0
            lui  a2, 0x10010            # Dirección base de Torre B
            addi a2, a1, 64             # Offset a Torre B (+64 bytes)
            lui  a3, 0x10010            # Dirección base de Torre C
            addi a3, a1, 128            # Offset a Torre C (+128 bytes)

            # Pasar N como primer argumento en a0
            addi a0, s0, 0              # a0 = N

            # Inicializar la Torre A con los discos en memoria (N, N-1, ..., 1)
            sw   s0, 0(a1)              # TorreA[0] = altura = N
            addi t1, a1, 4              # t1 = &TorreA[1] (la base de la torre)
            addi t2, s0, 0              # t2 = disco a colocar; empieza en N (el más grande)
loop:
            beq  t2, x0, endloop       # si t2 == 0 ya se colocaron todos
            sw   t2, 0(t1)              # TorreA[k] = disco actual
            addi t1, t1, 4              # siguiente slot (4 bytes)
            addi t2, t2, -1             # siguiente disco, más chico
            jal  x0, loop
endloop:

            # Llamada inicial a la función hanoi(N, Origen=a1, Auxiliar=a2, Destino=a3)
            jal  ra, hanoi

end:
            # Salir de la ejecución
            addi a7, x0, 10
            ecall


# FUNCIÓN RECURSIVA: hanoi(n, origen, aux, destino)
# Argumentos:
#   a0 = n (número de discos)
#   a1 = Origen
#   a2 = Auxiliar
#   a3 = Destino

hanoi:
            # 1. RESERVAR ESPACIO EN EL STACK (20 bytes para 5 palabras)
            addi sp, sp, -20
            sw   ra, 0(sp)              # Guardar dirección de retorno
            sw   a0, 4(sp)              # Guardar N
            sw   a1, 8(sp)              # Guardar Origen
            sw   a2, 12(sp)             # Guardar Auxiliar
            sw   a3, 16(sp)             # Guardar Destino

            # 2. CASO BASE: Si N == 1, mover disco directo
            addi t0, x0, 1
            beq  a0, t0, mover_un_disco

            # 3. PRIMERA LLAMADA RECURSIVA: hanoi(N-1, Origen, Destino, Auxiliar)
            addi a0, a0, -1             # a0 = N - 1
            lw   a1, 8(sp)              # a1 = Origen
            lw   a2, 16(sp)             # a2 = nuevo Auxiliar = Destino de este nivel
            lw   a3, 12(sp)             # a3 = nuevo Destino  = Auxiliar de este nivel
            jal  ra, hanoi

            # 4. MOVER DISCO N DE ORIGEN A DESTINO
            lw   a0, 4(sp)              # Restaurar N original
            lw   a1, 8(sp)              # Restaurar Origen
            lw   a3, 16(sp)             # Restaurar Destino
            jal  ra, realizar_movimiento

            # 5. SEGUNDA LLAMADA RECURSIVA: hanoi(N-1, Auxiliar, Origen, Destino)
            lw   a0, 4(sp)
            addi a0, a0, -1             # a0 = N - 1
            lw   a1, 12(sp)             # a1 = Origen (ahora es Auxiliar)
            lw   a2, 8(sp)              # a2 = Auxiliar (ahora es Origen)
            lw   a3, 16(sp)             # a3 = Destino
            jal  ra, hanoi
            jal  x0, salir_hanoi

mover_un_disco:
            lw   a1, 8(sp)              # Origen
            lw   a3, 16(sp)             # Destino
            jal  ra, realizar_movimiento

salir_hanoi:
            # RESTAURAR REGISTROS Y LIBERAR STACK
            lw   ra, 0(sp)
            addi sp, sp, 20
            jalr x0, ra, 0              

# funcion para actualizar la memoria de datos (Data Segment)
# entrada: a1 = torre Origen, a3 = torre Destino. Solo usa t0-t2 (no altera a0-a3).
realizar_movimiento:
            # --- sacar el disco de la cima de la torre Origen ---
            lw   t0, 0(a1)              # t0 = h = altura del Origen
            slli t1, t0, 2              # t1 = h * 4 (offset en bytes)
            add  t1, a1, t1             # t1 = Origen[h] (dirección de la cima)
            lw   t2, 0(t1)              # t2 = disco de la cima
            sw   x0, 0(t1)              # Origen[h] = 0 (se borra de memoria)
            addi t0, t0, -1             # h = h - 1
            sw   t0, 0(a1)              # Origen[0] = nueva altura

            # --- poner el disco en la cima de la torre Destino ---
            lw   t0, 0(a3)              # t0 = altura del Destino
            addi t0, t0, 1              # t0 = altura + 1
            sw   t0, 0(a3)              # Destino[0] = nueva altura
            slli t1, t0, 2              # t1 = (altura+1) * 4
            add  t1, a3, t1             # t1 = Destino[altura+1] (nueva cima)
            sw   t2, 0(t1)              # Destino[cima] = disco movido
            jalr x0, ra, 0              # <<< BREAKPOINT >>> aquí ya se movió el disco
