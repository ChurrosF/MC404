int read(int __fd, const void *__buf, int __n){
    int ret_val;
  __asm__ __volatile__(
    "mv a0, %1           # file descriptor\n"
    "mv a1, %2           # buffer \n"
    "mv a2, %3           # size \n"
    "li a7, 63           # syscall write code (63) \n"
    "ecall               # invoke syscall \n"
    "mv %0, a0           # move return value to ret_val\n"
    : "=r"(ret_val)  // Output list
    : "r"(__fd), "r"(__buf), "r"(__n)    // Input list
    : "a0", "a1", "a2", "a7"
  );
  return ret_val;
}

void write(int __fd, const void *__buf, int __n){
  __asm__ __volatile__(
    "mv a0, %0           # file descriptor\n"
    "mv a1, %1           # buffer \n"
    "mv a2, %2           # size \n"
    "li a7, 64           # syscall write (64) \n"
    "ecall"
    :   // Output list
    :"r"(__fd), "r"(__buf), "r"(__n)    // Input list
    : "a0", "a1", "a2", "a7"
  );
}

void exit(int code){
  __asm__ __volatile__(
    "mv a0, %0           # return code\n"
    "li a7, 93           # syscall exit (64) \n"
    "ecall"
    :   // Output list
    :"r"(code)    // Input list
    : "a0", "a7"
  );
}

void _start()
{
  int ret_code = main();
  exit(ret_code);
}

#define STDIN_FD  0
#define STDOUT_FD 1

/* Aloca um buffer com 10 bytes.*/
char buffer[10];
int n1;
int n2;
int result_int;
char result_string[6];

int main()
{
  /* Lê uma string da entrada padrão */
  int n = read(STDIN_FD, (void*) buffer, 8);


    n1 = (buffer[0] - '0') * 10 + buffer[1] - '0';
    n2 = (buffer[5] - '0') * 10 + buffer[6] - '0';

    switch(buffer[3]) {
        case '+':
            result_int = n1 + n2;
            break;
        case '-':
            result_int = n1 - n2;
            break;
        case '*':
            result_int = n1 * n2;
            break;
        case '/':
            result_int = n1 / n2;
            break;
    }


    for (int i = 0; i < 5; i++) {
        result_string[4 - i] = result_int % 10 + '0';
        result_int /= 10; 
    }


    result_string[5] = '\n';


  /* Imprime a string lida e os dois caracteres adicionados 
   * na saída padrão. */
  write(STDOUT_FD, (void*) result_string, 6);

  return 0;
}
