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

.equ MAX_SIZE, 192
.equ MAX_INPUT, MAX_SIZE * 33 + 10

# ============================================================
# Data Segment

.data

main_buffer:   .space MAX_SIZE * 4
aux_buffer:    .space MAX_SIZE * 4
input_buffer:  .space MAX_INPUT
output_buffer: .space MAX_INPUT

# ============================================================
# Code Segment

.text

.globl _start

# Ler valores de suporte
# Ler matriz 3D (Converter hexadecimal por bit shifting)
# Aplicar atualização de vx e vy (difusão 2d)
# Escrever matriz

_start:

    # read from Linux stdin
    jal read_input_procedure

    # execute a diffusion_1d
    jal diffusion_2d

    # write on Linux stdout
    jal write_input_procedure #1386

    # syscall exit
    li a0, 0
    li a7, 93
    ecall



# Retorna array em main_buffer e aux_buffer, s1 = L, s2 = C, s3 = T, s4 = V
read_input_procedure:
# t0 = input_buffer; t1 = main_buffer; t2 = aux_buffer; t4 = aux 1; t5 = aux 2; t6 = const 10

    li a0, 0            # file descriptor = 0 (stdin)
    la a1, input_buffer # buffer
    li a2, MAX_INPUT
    li a7, 63           # syscall read (63)
    ecall
    
    la t0, input_buffer
    li t6, 10

    lb s1, 0(t0)
    addi s1, s1, -'0'
    addi t0, t0, 2


    read_columns:
        lb t5, 0(t0)
        addi t5, t5, -'0'
        lb t4, 1(t0)
        addi t4, t4, -'\n'
        add s2, s2, t5 # Adicionar em s2
        beqz t4, 1f # Checar se existe próximo caractere
        mul s2, s2, t6 # Multiplicar número atual por 10 caso exista próximo
        addi t0, t0, 1 # Ir para o pŕoximo caractere
        j read_columns
    1:
        addi t0, t0, 2 # Colocar t0 no endereço da próxima linha
    
    read_iterations:
        lb t5, 0(t0)
        addi t5, t5, -'0'
        lb t4, 1(t0)
        addi t4, t4, -' '
        add s3, s3, t5
        beqz t4, 2f
        mul s3, s3, t6
        addi t0, t0, 1
        j read_iterations
    2:
        addi t0, t0, 2 # Colocar t0 no endereço da próxima leitura

    read_viscosity:
        lb t5, 0(t0)
        addi t5, t5, -'0'
        lb t4, 1(t0)
        addi t4, t4, -'\n'
        add s4, s4, t6
        beqz t4, 3f
        mul s4, s4, t6
        addi t0, t0, 1
        j read_viscosity
    3:
        addi t0, t0, 2
    
    li t4, 0 # i
    li t5, 0 # j

    read_matrix:
        beq t4, s1, read_input_procedure_end
        addi t4, t4, 1


        addi t0, t0, 11 # Ir para a próxima linha
        
        bne t5, s2, 4f 
        # São iguais
        li t5, t5, 0
        j read_matrix

        4: 
            addi t5, t5, 1

read_input_procedure_end:
    ret




    la t1, main_buffer
    la t2, aux_buffer