# ============================================================
# Constants Definition

.equ MAX_SIZE, 192
.equ MAX_INPUT, MAX_SIZE * 33 + 10

# ============================================================
# Data Segment

.data

main_buffer:   .space MAX_SIZE * 4
next_buffer:   .space MAX_SIZE * 4
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

    # execute a diffusion_2d
    jal diffusion_2d

    # write on Linux stdout
    jal write_input_procedure #1386

    # syscall exit
    li a0, 0
    li a7, 93
    ecall


diffusion_2d:
# s0 = máscara 10 bits, s5 = stride (s2 * 4), s6 = vxy_new, s7 = grid_current, s8 = grid_next, s9 = iterações restantes
# t2 = i, t3 = j, t4 = info_cel, t5 = v_difusao, t6 = aux1, a5 = aux2
    beqz s3, diffusion_2d_end       # Se T == 0, encerra imediatamente

    srli s4, s4, 5                  # k = V >> 5
    li s5, 4
    mul s5, s5, s2                  # s5 = stride = s2 * 4
    li s0, 0x3FF                    # máscara 10 bits

    la s7, main_buffer              # s7 = grid_current inicial (origem)
    la s8, next_buffer              # s8 = grid_next inicial (destino)
    mv s9, s3                       # s9 = contador de iterações T

    diffusion_iterations_loop:
        # Prepara ponteiros para a iteração atual:
        # t1 lê de s7 (grid_current)
        # t0 escreve em s8 (grid_next)
        mv t1, s7
        mv t0, s8

        add t0, t0, s5
        add t1, t1, s5

        addi t2, s1, -2                 # t2 = contador de linhas internas (s1 - 2)

        diffusion_loop_rows:
            beqz t2, end_iteration_rows
            addi t2, t2, -1
            addi t3, s2, -2
            addi t0, t0, 4
            addi t1, t1, 4
            diffusion_loop_columns:
            beqz t3, end_columns
            addi t3, t3, -1

            lw t4, (t1) # Carrega informação da célula

            calculate_vx_new:
                li a5, 0
                # right
                lw t6, 4(t1)

                # Extrair vx_right           
                slli t6, t6, 12
                srai t6, t6, 22

                add a5, a5, t6

                # left
                lw t6, -4(t1)

                # Extrair vx_left
                slli t6, t6, 12
                srai t6, t6, 22

                add a5, a5, t6

                add t1, t1, s5
                # down
                lw t6, 0(t1)

                # Extrair vx_down
                slli t6, t6, 12
                srai t6, t6, 22

                add a5, a5, t6
                sub t1, t1, s5

                sub t1, t1, s5
                
                # up
                lw t6, 0(t1)

                # Extrair vx_up
                slli t6, t6, 12
                srai t6, t6, 22
                
                add t1, t1, s5
                add a5, a5, t6

                # a5 = avg_x
                srai a5, a5, 2

                # t6 = vx_atual, a5 = difference_x
                lw t6, 0(t1)
                slli t6, t6, 12
                srai t6, t6, 22

                sub a5, a5, t6

                sra a5, a5, s4

                # t5 = vx_difusao
                add t5, t6, a5

                # Colocar grad_px em a5

                lw t6, -4(t1)
                srli t6, t6, 20 # Extrair Pressure_west

                mv a5, t6

                lw t6, 4(t1)
                srli t6, t6, 20 # Extrair Pressure_east

                sub a5, a5, t6
                srai a5, a5, 4

                # Colocar vx_new em a5
                add a5, t5, a5
                li t6, 511
                
                ble a5, t6, 7f
                li a5, 511 
                7:
                    li t6, -512
                    bge a5, t6, 8f
                li a5, -512
                8:

                and a5, a5, s0 # Mantém apenas 10 bits de vx_new
                slli a5, a5, 10 # vx_new deslocado em 10 bits a esquerda
                mv s6, a5

            calculate_vy_new:
                li a5, 0

                # right
                lw t6, 4(t1)

                # Extrair vy_right
                slli t6, t6, 22
                srai t6, t6, 22

                add a5, a5, t6

                # left
                lw t6, -4(t1)

                # Extrair vy_left
                slli t6, t6, 22
                srai t6, t6, 22

                add a5, a5, t6

                add t1, t1, s5
                # down
                lw t6, 0(t1)

                # Extrair vy_down
                slli t6, t6, 22
                srai t6, t6, 22

                add a5, a5, t6
                sub t1, t1, s5

                sub t1, t1, s5
                
                # up
                lw t6, 0(t1)

                # Extrair vy_up
                slli t6, t6, 22
                srai t6, t6, 22
                
                add t1, t1, s5
                add a5, a5, t6

                # a5 = avg_y
                srai a5, a5, 2

                # t6 = vy_atual, a5 = difference_y
                lw t6, 0(t1)
                slli t6, t6, 22
                srai t6, t6, 22

                sub a5, a5, t6

                sra a5, a5, s4

                # t5 = vy_difusao
                add t5, t6, a5

                # Colocar grad_py em a5

                sub t1, t1, s5
                lw t6, 0(t1)
                srli t6, t6, 20 # Extrair Pressure_north
                add t1, t1, s5

                mv a5, t6

                add t1, t1, s5
                lw t6, 0(t1)
                srli t6, t6, 20 # Extrair Pressure_south
                sub t1, t1, s5

                sub a5, a5, t6
                srai a5, a5, 4

                # Colocar vy_new em a5
                add a5, t5, a5
                li t6, 511
                
                ble a5, t6, 9f
                li a5, 511 
                9:
                    li t6, -512
                    bge a5, t6, 10f
                li a5, -512
                10:

                and a5, a5, s0
                or s6, s6, a5 # s6 = (vx_new << 10) | vy_new

                # Pressure
                srli t6, t4, 20
                slli t6, t6, 20
                or s6, s6, t6 # s6 = [Pressure (31:20) | vx_new (19:10) | vy_new (9:0)]

                # Escrever célula calculada na matriz de destino (grid_next)
                sw s6, 0(t0)

                addi t1, t1, 4
                addi t0, t0, 4 
                j diffusion_loop_columns

        end_columns:
            addi t0, t0, 4
            addi t1, t1, 4
            j diffusion_loop_rows

        end_iteration_rows:
            # Fim de 1 iteração completa de difusão sobre o grid
            # Ping-pong buffering: troca os ponteiros de buffer (grid_current <-> grid_next)
            mv t6, s7
            mv s7, s8
            mv s8, t6

            # Decrementa o contador de iterações restantes
            addi s9, s9, -1
            bnez s9, diffusion_iterations_loop

    # Após T iterações, se o resultado mais recente estiver em next_buffer (caso T ímpar),
    # copia de volta para main_buffer para garantir que o resultado final esteja sempre em main_buffer
    la t6, main_buffer
    beq s7, t6, diffusion_2d_end

    la t0, main_buffer
    la t1, next_buffer
    mul t2, s1, s2                      # Total de elementos = L * C
    copy_to_main_buffer:
        beqz t2, diffusion_2d_end
        lw t3, 0(t1)
        sw t3, 0(t0)
        addi t0, t0, 4
        addi t1, t1, 4
        addi t2, t2, -1
        j copy_to_main_buffer

diffusion_2d_end:
    ret

# Retorna array em main_buffer e next_buffer, s1 = L, s2 = C, s3 = T, s4 = V
read_input_procedure:
# t0 = input_buffer; t1 = main_buffer; t2 = next_buffer; t4 = aux 1; t5 = aux 2; t6 = const 10

    li a0, 0            # file descriptor = 0 (stdin)
    la a1, input_buffer # buffer
    li a2, MAX_INPUT
    li a7, 63           # syscall read (63)
    ecall

    la t0, input_buffer
    li t6, 10
    li s1, 0
    li s2, 0
    li s3, 0
    li s4, 0

read_rows:
    lb t5, 0(t0)
    addi t5, t5, -'0'
    lb t4, 1(t0)
    addi t4, t4, -' '
    add s1, s1, t5
    beqz t4, 0f
    mul s1, s1, t6
    addi t0, t0, 1
    j read_rows
0:
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
    add s4, s4, t5
    beqz t4, 3f
    mul s4, s4, t6
    addi t0, t0, 1
    j read_viscosity
    3:
    addi t0, t0, 2

li t4, 0 # i
li t5, 0 # j
la t1, main_buffer
la t2, next_buffer

read_matrix:
    beq t4, s1, read_input_procedure_end
    addi t4, t4, 1



    check_line_end:
        bne t5, s2, read_number 
        # Leitura da linha encerrada
        li t5, 0 # Zerar contagem de colunas
        j read_matrix # Próxima linha

    read_number:
        addi t0, t0, 9
        li t3, 0
        li t6, 0
        li s9, 8
        li s10, 'A'
        hex_to_int:
            # t3 número atual, t6 = tamanho do shift, a5 = aux

            beqz s9, 6f
            lb a5, (t0)
            bge a5, s10, 4f # É alfabético salta
            addi a5, a5, -'0'
            j 5f
            
            4:
                addi a5, a5, -55 
            5:
                sll a5, a5, t6
                add t3, t3, a5
                addi t0, t0, -1
                addi s9, s9, -1
                addi t6, t6, 4
                j hex_to_int

            6:
                sw t3, 0(t1)
                sw t3, 0(t2)

                addi t1, t1, 4
                addi t2, t2, 4
             

        addi t0, t0, 10 # Pular para o próximo número
        addi t5, t5, 1 # Próximo número da coluna a ser lido
        j check_line_end

    read_input_procedure_end:
        ret


write_input_procedure:
    la a1, output_buffer        # Início do output_buffer (usado na syscall)
    mv a4, a1                   # a4 = ponteiro corrente de escrita
    la a3, main_buffer          # a3 = ponteiro corrente de leitura

    mv t0, s1                   # t0 = linhas restantes (L)

write_row_loop:
    beqz t0, write_done         # Se acabou as linhas, finaliza escrita
    mv t1, s2                   # t1 = colunas restantes nesta linha (C)

write_col_loop:
    beqz t1, write_row_end      # Fim das colunas desta linha

    # Escreve o prefixo "0x"
    li t4, '0'
    sb t4, 0(a4)
    li t4, 'x'
    sb t4, 1(a4)
    addi a4, a4, 2

    # Lê a palavra da célula de main_buffer
    lw t3, 0(a3)
    addi a3, a3, 4

    # Converte os 8 dígitos hexadecimais (32 bits = 8 nibbles)
    li t2, 8                    # Contador de nibbles
convert_hex_digit:
    srli t4, t3, 28             # Pega os 4 bits mais significativos
    andi t4, t4, 0xF            # Máscara de 4 bits
    li t5, 10
    blt t4, t5, hex_is_digit
    addi t4, t4, 55             # 10 + 55 = 65 = 'A'
    j hex_store_char
hex_is_digit:
    addi t4, t4, '0'
hex_store_char:
    sb t4, 0(a4)
    addi a4, a4, 1
    slli t3, t3, 4              # Desloca para o próximo nibble
    addi t2, t2, -1
    bnez t2, convert_hex_digit

    # Decide o separador: ' ' se não for a última coluna, '\n' se for a última
    addi t1, t1, -1             # Decrementa coluna restante
    beqz t1, write_newline_char

    li t4, ' '
    sb t4, 0(a4)
    addi a4, a4, 1
    j write_col_loop

write_newline_char:
    li t4, '\n'
    sb t4, 0(a4)
    addi a4, a4, 1
    j write_row_end

write_row_end:
    addi t0, t0, -1             # Decrementa linha restante
    j write_row_loop

write_done:
    # Calcula a quantidade exata de bytes escritos: a2 = a4 - a1
    sub a2, a4, a1

    li a0, 1                    # stdout (file descriptor 1)
    # a1 já aponta para output_buffer
    li a7, 64                   # syscall write (64)
    ecall

    ret

