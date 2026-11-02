# Ler vetor como int
# Ordenar vetor (insertion sort)
# Printar vetor ordenado


# Constants Definition

.equ MAX_SHAPE, 10
.equ MAX_INPUT, MAX_SHAPE * 8

# ============================================================
# Data Segment

.data

main_buffer:   .space MAX_SHAPE * 4
input_buffer:  .space MAX_INPUT
output_buffer: .space MAX_INPUT

# ============================================================
# Code Segment

.text

.globl _start

_start:

    # read from Linux stdin
    jal read_input_procedure
    # Return: array (main_buffer), n (a3)

    jal insertion_sort
    # Return: sorted array (main_buffer)

    # write on Linux stdout
    # Uses: array, n
    jal write_input_procedure #1386

    # syscall exit
    li a0, 0
    li a7, 93
    ecall


insertion_sort:
    # t0 = i; t1 = j; t2 = const 0; t3 = j * 4; t4 = main_buffer[j]; t5 = main_buffer[j - 1]; t6 = temp; s0 = main_buffer; 

    li t0, 1
    li t2, 0

    1:
        beq a3, t0, 1f

        mv t1, t0 # j = i
        addi t0, t0, 1

    2:
        la s0, main_buffer
        slli t3, t1, 2 # j * 4 
    
        add s0, s0, t3

        lw t4, (s0) # a[j]
        lw t5, -4(s0) # a[j - 1]

        beq t1, t2, 1b # j = 0
        bge t4, t5, 1b # a[j] > a[j - 1]

        sw t4, -4(s0)
        sw t5, (s0)

        addi t1, t1, -1 # j--

        j 2b

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
    li t2, -1
    li s1, 10
    li s2, 100
    li s3, 1000
    li s4, 10000
    li s5, 100000

    li a3, 0
    la t1, main_buffer
    j read_array


    read_input_procedure_end:
        ret

    read_array:
        # t0 = input_buffer; t2 = const -1; t1 = main_buffer; t4 = num atual (int); t5 = aux; s1 = const 10; s2 = const 100; s3 = const 1000; s4 = const 10000
        # s5 = const 100000

        # n++
        addi a3, a3, 1

        # Checando sinal do número
        lbu t5, 0(t0)
        addi t5, t5, -'-'
        beqz t5, read_negative_number 

        read_positive_number:

            # Carregando num em t4
            lbu t4, 0(t0)
            addi t4, t4, -'0'
            mul t4, t4, s5
            
            lbu t5, 1(t0)
            addi t5, t5, -'0'
            mul t5, t5, s4
            add t4, t4, t5

            lbu t5, 2(t0)
            addi t5, t5, -'0'
            mul t5, t5, s3
            add t4, t4, t5
            
            lbu t5, 4(t0)
            addi t5, t5, -'0'
            mul t5, t5, s2
            add t4, t4, t5
            
            lbu t5, 5(t0)
            addi t5, t5, -'0'
            mul t5, t5, s1
            add t4, t4, t5

            lbu t5, 6(t0)
            addi t5, t5, -'0'
            add t4, t4, t5

            # Escrevendo t4 em main_buffer
            sw t4, (t1)

            # Checar se esse é o último número
            lbu t4, 7(t0)
            addi t5, t4, -'\n'
            beqz t5, read_input_procedure_end #131

            addi t0, t0, 8
            addi t1, t1, 4

            j read_array

        read_negative_number:
        # Carregando num em t4
            lbu t4, 1(t0)
            addi t4, t4, -'0'
            mul t4, t4, s5
            
            lbu t5, 2(t0)
            addi t5, t5, -'0'
            mul t5, t5, s4
            add t4, t4, t5

            lbu t5, 3(t0)
            addi t5, t5, -'0'
            mul t5, t5, s3
            add t4, t4, t5
            
            lbu t5, 5(t0)
            addi t5, t5, -'0'
            mul t5, t5, s2
            add t4, t4, t5
            
            lbu t5, 6(t0)
            addi t5, t5, -'0'
            mul t5, t5, s1
            add t4, t4, t5

            lbu t5, 7(t0)
            addi t5, t5, -'0'
            add t4, t4, t5

            # Inverter sinal de t4
            mul t4, t4, t2

            # Escrevendo t4 em main_buffer
            sw t4, (t1)

            # Checar se esse é o último número
            lbu t4, 8(t0)
            addi t5, t4, -'\n'
            beqz t5, read_input_procedure_end #131

            addi t0, t0, 9
            addi t1, t1, 4

            j read_array


write_input_procedure:
    mv t2, a3
    la t0, output_buffer
    la t1, main_buffer
    li t3, 10
    li t6, 0
    li s0, -1
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
    # t0 = output_buffer, t1 = main_buffer, t2 = números restantes, # t3 = const 10, # t4 = num atual, # t5 = word atual de main buffer, # t6 = const 0
    # s0 = const -1
    beqz t2, write_procedure_end

    lw t5, (t1)

    blt t5, t6, write_negative_number

    write_positive_number:
    
        rem t4, t5, t3
        addi t4, t4, '0'
        sb t4, 6(t0)
        div t5, t5, t3

        rem t4, t5, t3
        addi t4, t4, '0'
        sb t4, 5(t0)
        div t5, t5, t3

        rem t4, t5, t3
        addi t4, t4, '0'
        sb t4, 4(t0)
        div t5, t5, t3

        li t4, '.'
        sb t4, 3(t0)

        rem t4, t5, t3
        addi t4, t4, '0'
        sb t4, 2(t0)
        div t5, t5, t3

        rem t4, t5, t3
        addi t4, t4, '0'
        sb t4, 1(t0)
        div t5, t5, t3

        rem t4, t5, t3
        addi t4, t4, '0'
        sb t4, 0(t0)
        div t5, t5, t3

        li t4, ' '
        sb t4, 7(t0)

        addi t2, t2, -1
        addi t1, t1, 4
        addi t0, t0, 8

        j write_loop

    write_negative_number:

        li t4, '-'
        sb t4, (t0)

        mul t5, t5, s0
        
        rem t4, t5, t3
        addi t4, t4, '0'
        sb t4, 7(t0)
        div t5, t5, t3

        rem t4, t5, t3
        addi t4, t4, '0'
        sb t4, 6(t0)
        div t5, t5, t3

        rem t4, t5, t3
        addi t4, t4, '0'
        sb t4, 5(t0)
        div t5, t5, t3

        li t4, '.'
        sb t4, 4(t0)

        rem t4, t5, t3
        addi t4, t4, '0'
        sb t4, 3(t0)
        div t5, t5, t3

        rem t4, t5, t3
        addi t4, t4, '0'
        sb t4, 2(t0)
        div t5, t5, t3

        rem t4, t5, t3
        addi t4, t4, '0'
        sb t4, 1(t0)
        div t5, t5, t3

        li t4, ' '
        sb t4, 8(t0)

        addi t2, t2, -1
        addi t1, t1, 4
        addi t0, t0, 9

        j write_loop