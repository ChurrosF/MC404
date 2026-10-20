.data
    # Buffers na memória para ler a entrada e gravar a saída
    input_buffer:   .skip 32
    output_buffer:  .skip 12

.text
.globl _start

_start:
  # TODO: Ler a entrada do usuário (coordenadas e tempos)
  jal read

  # TODO: Implementar o cálculo das distâncias
  jal calculate_distances

  # TODO: Converter os resultados de X e Y (inteiros) de volta
  jal write

  li a0, 0
  li a7, 93                   # syscall de exit (93)
  ecall


# ============================================================
# Método auxiliar: Raiz Quadrada (Método Babilônico)
# ============================================================
# Entrada: a0 (Valor que você deseja calcular a raiz)
# Saída:   a0 (Resultado inteiro da raiz quadrada)
# ============================================================
sqrt:
    li t2, 1
    ble a0, t2, sqrt_end 

    li t2, 21                   # t2 = Contador de iterações (precisão)
    mv t0, a0                   # Copia o valor de entrada para t0
    srli t0, t0, 1              # t0 = Chute inicial (Entrada / 2)

loop_sqrt:
    div t1, a0, t0              # t1 = Entrada / Chute
    add t1, t1, t0              # t1 = Chute + (Entrada / Chute)
    srli t0, t1, 1              # t0 = Novo Chute (Divide tudo por 2)

    addi t2, t2, -1             # Diminui o contador de iterações
    bnez t2, loop_sqrt          # Se não chegou a zero, repete o loop

    mv a0, t0                   # Coloca o resultado final em a0

sqrt_end:
    ret


write:
# Usa: t0 = output_buffer; t1 = const 10; t3 = const -1; t2 = digito atual
    la t0, output_buffer
    li t1, 10
    li t3, -1


    li t2, '+'
    sb t2, 0(t0)
    sb t2, 6(t0)

    bge a5, t3, 1f
    li t2, '-'
    sb t2, 0(t0)
    mul a5, a5, t3
    1:


    bge a6, t3, 2f
    li t2, '-'
    sb t2, 6(t0)
    mul a6, a6, t3
    2:

    remu t2, a5, t1
    addi t2, t2, '0'
    divu a5, a5, t1
    sb t2, 4(t0)

    remu t2, a5, t1
    addi t2, t2, '0'
    divu a5, a5, t1
    sb t2, 3(t0)

    remu t2, a5, t1
    addi t2, t2, '0'
    divu a5, a5, t1
    sb t2, 2(t0)

    remu t2, a5, t1
    addi t2, t2, '0'
    divu a5, a5, t1
    sb t2, 1(t0)

    li t2, ' '
    sb t2, 5(t0)

// ------------------------

    remu t2, a6, t1
    addi t2, t2, '0'
    divu a6, a6, t1
    sb t2, 10(t0)

    remu t2, a6, t1
    addi t2, t2, '0'
    divu a6, a6, t1
    sb t2, 9(t0)

    remu t2, a6, t1
    addi t2, t2, '0'
    divu a6, a6, t1
    sb t2, 8(t0)

    remu t2, a6, t1
    addi t2, t2, '0'
    divu a6, a6, t1
    sb t2, 7(t0)

    li t2, '\n'
    sb t2, 11(t0)

    li a0, 1
    la a1, output_buffer       # buffer
    li a2, 12
    li a7, 64           # syscall write (64)
    ecall
    ret



calculate_distances:
# Retorno: a5 = x, a6 = y
# Usa: s4 = Da; s5 = Db; s6 = Dc; t0 = const 3; t1 = const 10; s1 = TA -> TA - TR; s2 = TB -> TB - TR; s3 = TC -> TC - TR
# t2 = Da^2; t3 = Db^2; t4 = Yb^2, t5 = Xc^2, t6 = Dc^2
    
    li t0, 3
    li t1, 10

    sub s1, s0, s1 # delta TA
    sub s2, s0, s2 # delta TB
    sub s3, s0, s3 # delta TC

    mul s4, s1, t0 
    div s4, s4, t1

    mul s5, s2, t0
    div s5, s5, t1

    mul s6, s3, t0
    div s6, s6, t1

    mul t2, s4, s4 # Da^2
    mul t3, s5, s5 # Db^2
    mul t6, s6, s6 # Dc^2
    mul t4, a4, a4 # Yb^2
    mul t5, a3, a3 # Xc^2

    # Calculando y
    add a6, t2, t4
    sub a6, a6, t3

    div a6, a6, a4
    srai a6, a6, 1

    # Calculando x
    add a5, t5, t2
    sub a5, a5, t6

    div a5, a5, a3
    srai a5, a5, 1

    ret



read:
# Retorno: a3 = Xc; a4 = Yb; s0 = TR; s1 = TA; s2 = TB; s3 = TC
# Usa: t0 = input_buffer; t1 = aux; t2 = const 10; t3 = const 100; t4 = const 1000; t5 = -1
    li a0, 0            # file descriptor = 0 (stdin)
    la a1, input_buffer # buffer
    li a2, 32   
    li a7, 63           # syscall read (63)
    ecall

    li t2, 10
    li t3, 100
    li t4, 1000
    li t5, -1

    li a3, 0

    la t0, input_buffer

    # Carregando valor negativo de Xc em a3
    lb t1, 1(t0)
    addi t1, t1, -'0'
    add a3, t1, a3
    mul a3, a3, t4

    lb t1, 2(t0)
    addi t1, t1, -'0'
    mul t1, t1, t3
    add a3, t1, a3

    lb t1, 3(t0)
    addi t1, t1, -'0'
    mul t1, t1, t2
    add a3, t1, a3

    lb t1, 4(t0)
    addi t1, t1, -'0'
    add a3, t1, a3

    mul a3, a3, t5

    # Carregando valor negativo de Yb em a4
    lb t1, 7(t0)
    addi t1, t1, -'0'
    add a4, t1, a4
    mul a4, a4, t4

    lb t1, 8(t0)
    addi t1, t1, -'0'
    mul t1, t1, t3
    add a4, t1, a4

    lb t1, 9(t0)
    addi t1, t1, -'0'
    mul t1, t1, t2
    add a4, t1, a4

    lb t1, 10(t0)
    addi t1, t1, -'0'
    add a4, t1, a4

    mul a4, a4, t5

    # Calculando sinal de a3 (Xc)
    lb t1, (t0)
    addi t1, t1, -44
    mul a3, a3, t1

    # Calculando sinal de a4 (Yb)
    lb t1, 6(t0)
    addi t1, t1, -44
    mul a4, a4, t1


    # Carregando TR em s0
    lb t1, 12(t0)
    addi t1, t1, -'0'
    add s0, t1, s0
    mul s0, s0, t4

    lb t1, 13(t0)
    addi t1, t1, -'0'
    mul t1, t1, t3
    add s0, t1, s0

    lb t1, 14(t0)
    addi t1, t1, -'0'
    mul t1, t1, t2
    add s0, t1, s0

    lb t1, 15(t0)
    addi t1, t1, -'0'
    add s0, t1, s0

    # Carregando TA em s1
    lb t1, 17(t0)
    addi t1, t1, -'0'
    add s1, t1, s1
    mul s1, s1, t4

    lb t1, 18(t0)
    addi t1, t1, -'0'
    mul t1, t1, t3
    add s1, t1, s1

    lb t1, 19(t0)
    addi t1, t1, -'0'
    mul t1, t1, t2
    add s1, t1, s1

    lb t1, 20(t0)
    addi t1, t1, -'0'
    add s1, t1, s1

    # Carregando TB em s2
    lb t1, 22(t0)
    addi t1, t1, -'0'
    add s2, t1, s2
    mul s2, s2, t4

    lb t1, 23(t0)
    addi t1, t1, -'0'
    mul t1, t1, t3
    add s2, t1, s2

    lb t1, 24(t0)
    addi t1, t1, -'0'
    mul t1, t1, t2
    add s2, t1, s2

    lb t1, 25(t0)
    addi t1, t1, -'0'
    add s2, t1, s2

    # Carregando TC em s3
    lb t1, 27(t0)
    addi t1, t1, -'0'
    add s3, t1, s3
    mul s3, s3, t4

    lb t1, 28(t0)
    addi t1, t1, -'0'
    mul t1, t1, t3
    add s3, t1, s3

    lb t1, 29(t0)
    addi t1, t1, -'0'
    mul t1, t1, t2
    add s3, t1, s3

    lb t1, 30(t0)
    addi t1, t1, -'0'
    add s3, t1, s3

    ret