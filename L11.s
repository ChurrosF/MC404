.data
input_file: .asciz "mapa.pgm"

buffer:       .space 4109   # 13 bytes header + 4096 bytes pixels

.text
.globl _start

_start:
    # 1. Abrir arquivo
    la a0, input_file
    li a1, 0          
    li a2, 0
    li a7, 1024       # syscall open
    ecall
    mv s0, a0         # salva fd em s0

    # 2. Ler arquivo para o buffer
    mv a0, s0
    la a1, buffer
    li a2, 4109
    li a7, 63         # syscall read
    ecall

    # 3. Fechar arquivo
    mv a0, s0
    li a7, 57         # syscall close
    ecall

    # 4. Configurar Canvas 64x64
    li a0, 64
    li a1, 64
    li a7, 2201       # syscall setCanvasSize
    ecall




apply_floodfill:

    la t0, buffer
    addi t0, t0, 13

    li t1, 64 # X
    li t2, 64 # Y



    1:
        mv a0, t1
        mv a1, t2
        jal get_pixel_color
        addi t1, t1, -1






floodfill_recursive:
# Parâmetros: a0 = Coordenada X, a1 = Coordenada Y
# Retorno: 1 se pixel é branco, 0 caso contrário



get_pixel_color:
# Parâmetros: a0 = Coordenada X, a1 = Coordenada Y
# Retorno: a0 = Cor do pixel alvo

    la t0, buffer
    addi t0, t0, 13 # Pulando cabeçalho

    li t1, 64
    mul a1, a1, t1 # Offset da linha atual em a1

    add a0, a0, a1 # Offset total do pixel alvo

    add t0, t0, a0

    lb a0, (t0) # Carregando valor do pixel

    ret