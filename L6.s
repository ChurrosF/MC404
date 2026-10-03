# ============================================================
# 1D Fluid Diffusion - RV32I
#
# Formula:
#   difference = left + right - 2 * center
#   change     = difference >> 2
#   new_value  = center + change
#
# The first and last elements remain unchanged.
# All test cases have a number of elements >= 3.

# ============================================================
# Constants Definition

.equ MAX_SHAPE, 128
.equ MAX_INPUT, MAX_SHAPE * 3

# ============================================================
# Data Segment

.data

main_buffer:   .space MAX_SHAPE * 4
aux_buffer:    .space MAX_SHAPE * 4
input_buffer:  .space MAX_INPUT
output_buffer: .space MAX_INPUT

# ============================================================
# Code Segment

.text

.globl _start

# preciso ler o array e guardar na memória em char
# converto de char para int e coloco no main buffer e no buffer aux
# depois opero com o array para cada posição realizando k operações
# converto de int para char e coloco no output buffer
# dou write no output buffer

_start:

    # read from Linux stdin
    jal read_input_procedure
    # Return: array (main_buffer e aux_buffer), n (a3), iterations (a4)

    # execute a diffusion_1d
    # Uses: array, n (a3), iterations (a4)
    jal diffusion_1d

    # write on Linux stdout
    # Uses: array, n
    jal write_input_procedure #1386

    # syscall exit
    li a0, 0
    li a7, 93
    ecall


diffusion_1d:
    # t0 = *main_buffer; t1 = *aux_buffer; t2 = números restantes para aplicar a fórmula/copiar; t3 = número atual; t4 = aux; t5 = números restantes para copiar
    # 1: Loop para contar iterações
    1:
        mv t2, a3
        addi t2, t2, -2

        mv t6, a3
        addi t6, t6, -2

        # Carregar buffers e pular primeiro número
        la t0, main_buffer
        la t1, aux_buffer

        addi t0, t0, 4
        addi t1, t1, 4

        # Contador de iterações
        beqz a4, 1f
        addi a4, a4, -1

    update_array:
        # Quantas vezes aplicar algoritmo
        beqz t2, copy_array
        addi t2, t2, -1

        
        # Algoritmo
        lw t3, -4(t1)
        lw t4, 4(t1)

        add t3, t3, t4
        lw t4, (t1)

        add t4, t4, t4

        sub t3, t3, t4

        srai t3, t3, 2 #154
        lw t4, (t1)

        add t3, t3, t4

        # Modifica main buffer
        sw t3, (t0)

        # Pula para o próximo número
        addi t0, t0, 4
        addi t1, t1, 4

        j update_array
    # Loop para copiar main_buffer para aux_buffer
    copy_array:
        beqz t6, 1b

        lw t4, -4(t0)
        sw t4, -4(t1)

        addi t6, t6, -1
        addi t0, t0, -4
        addi t1, t1, -4

        j copy_array
    1:
        ret


# Retorna array em main_buffer e aux_buffer, a3 = n, a4 = iterations
read_input_procedure:
    li a0, 0            # file descriptor = 0 (stdin)
    la a1, input_buffer # buffer
    li a2, MAX_INPUT
    li a7, 63           # syscall read (63)
    ecall
    
    la t0, input_buffer
    li t6, 10

    # Carregando iterações em a4
    lb a4, (t0)
    addi a4, a4, -'0'
    mul a4, a4, t6
    lb t3, 1(t0)
    addi t3, t3, -'0'
    add a4, a4, t3
    
    # # Lendo array
    # li a2, MAX_INPUT
    # ecall

    addi t0, t0, 3

    li a3, 0
    la t1, main_buffer
    la t2, aux_buffer
    j read_array


    read_input_procedure_end:
        ret

    read_array:
        # t0 = input_buffer; t1 = main_buffer; t2 = aux_buffer; t3 = 0, se estamos lendo o último número; t4 = num atual (int); t5 = aux; t6 = const 10;

        # n++
        addi a3, a3, 1

        # Carregando num em t4  
        lbu t4, 0(t0)
        addi t4, t4, -'0'
        mul t4, t4, t6
        lbu t5, 1(t0)
        addi t5, t5, -'0'
        add t4, t4, t5  #30

        # Escrevendo t4 em ambos os buffers
        sw t4, (t1)
        sw t4, (t2)

        # Checar se esse é o último número
        lbu t4, 2(t0)
        addi t3, t4, -'\n'
        beqz t3, read_input_procedure_end #131

        # Realizar próxima leitura/escrição
        addi t0, t0, 3
        addi t1, t1, 4
        addi t2, t2, 4

        j read_array


write_input_procedure:
    mv t2, a3
    la t0, output_buffer
    la t1, main_buffer
    li t3, 10
    j write_loop

write_procedure_end:
    li t4, '\n'
    sb t4, -1(t0)

    li a0, 1            # file descriptor = 1 (stdout)
    la a1, output_buffer       # buffer
    li a2, MAX_INPUT           # size - Writes MAX_INPUT bytes.
    li a7, 64           # syscall write (64)
    ecall
    ret

write_loop:
    # t0 = output_buffer, t1 = main_buffer, t2 = números restantes, # t3 = const 10, # t4 = num atual, # t5 = word atual de main buffer
    beqz t2, write_procedure_end

    lw t5, (t1)

    rem t4, t5, t3
    addi t4, t4, '0'
    sb t4, 1(t0)
    div t5, t5, t3

    rem t4, t5, t3
    addi t4, t4, '0'
    sb t4, (t0)

    li t4, 0
    addi t4, t4, ' '

    sb t4, 2(t0)

    addi t2, t2, -1
    addi t1, t1, 4
    addi t0, t0, 3

    j write_loop

# read:
#     li a0, 0            # file descriptor = 0 (stdin)
#     la a1, input_address # buffer
#     li a2, 6            # size - Reads 6 bytes.
#     li a7, 63           # syscall read (63)
#     ecall
#     ret