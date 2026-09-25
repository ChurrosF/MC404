.globl _start

_start:
  li a0, 220826
  li a1, 0
  li a2, 0
  li a3, -1
loop:
  andi t0, a0, 1
  add  a2, a2, t0
  xor  a1, a1, t0
  addi a3, a3, 2
  srli a0, a0, 1
  bnez a0, loop

end:
  la a0, result
  sw a2, 0(a0)
  li a0, 0
  li a7, 93
  ecall

result:
  .word 0