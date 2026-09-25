.globl _start

_start:
    jal main
    li a0, 0
    li a7, 93 # exit
    ecall


main:
    jal read

    la t0, input_address
    li t3, 10

    # primeiro número em t1
    lb t1, (t0)
    addi t1, t1, -'0'
    
    mul t1, t1, t3

    lb t2, 1(t0)
    addi t2, t2, -'0'

    add t1, t1, t2

    # segundo número em t2
    lb t2, 3(t0)
    addi t2, t2, -'0'

    mul t2, t2, t3

    lb t4, 4(t0)
    addi t4, t4, -'0'

    add t2, t2, t4


loop:
    # t1 = A, # t2 = B # t3 = A -> MDC # t4 = R # t5 = B 
    beqz t4, end_loop
    mv t3, t1
    mv t4, t2
    mv t5, t2
    
    rem t4, t3, t4 # Calcula R e coloca em t4
    mv t3, t5 # Coloca o valor de B antigo no t3
    mv t5, t4 # Coloca o novo valor de B no t5

    j loop

end_loop:
    # t3 = MDC # t4 = MMC
    mul t4, t1, t2
    div t4, t4, t3

    la t0, result
    sw t4, t0

    a


read:
    li a0, 0            # file descriptor = 0 (stdin)
    la a1, input_address # buffer
    li a2, 6            # size - Reads 6 bytes.
    li a7, 63           # syscall read (63)
    ecall
    ret

write:
    li a0, 1            # file descriptor = 1 (stdout)
    la a1, result       # buffer
    li a2, 5           # size - Writes 5 bytes.
    li a7, 64           # syscall write (64)
    ecall
    ret


.bss

input_address: .skip 0x06  # buffer

result: .skip 0x5