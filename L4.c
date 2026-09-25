#define STDIN_FD  0
#define STDOUT_FD 1

int read(int __fd, const void *__buf, int __n)
{
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


void write(int __fd, const void *__buf, int __n)
{
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

void exit(int code)
{
__asm__ __volatile__(
    "mv a0, %0           # return code\n"
    "li a7, 93           # syscall exit (64) \n"
    "ecall"
    :   // Output list
    :"r"(code)    // Input list
    : "a0", "a7"
);
}


int char2int(char c)
{
    return c - '0';
}


unsigned int multiply(unsigned int a, unsigned int b)
{
    int result = 0;
    int current_bit;

    for (int i = 0; i < 10; i++)
    {
        current_bit = b & 1;
        b >>= 1;
        if (current_bit) result += a;
        a <<= 1;
    }
    
    return result;
}


unsigned int divide(unsigned int dividend, unsigned int divisor)
{
    int quotient = 0;
    int remainder = 0;
    int mask = 512;
    int current_bit;

    for (int i = 0; i < 10; i++)
    {
        current_bit = (dividend & mask) >> (9 - i);
        mask >>= 1;

        quotient <<= 1;

        remainder = (remainder << 1) | current_bit;
        if (remainder >= divisor)
        {
            remainder -= divisor;
            quotient |= 1;
        }

    }
    return quotient;
}


unsigned int remainder(unsigned int dividend, unsigned int divisor)
{
    int remainder = 0;
    int mask = 512;
    int current_bit;

    for (int i = 0; i < 10; i++)
    {
        current_bit = (dividend & mask) >> (9 - i);
        mask >>= 1;

        remainder = (remainder << 1) | current_bit;
        if (remainder >= divisor)
        {
            remainder -= divisor;
        }
    }
        
    return remainder;
}


void int2char(int n, char *dst)
{
    int current_bit;
    for (int i = 0; i < 7; i++) {
        dst[6 - i] = (n % 10) + '0';
        n /= 10;
    }
}



int main()
{
    char buffer[10];
    char *answer = "0000000\n";
    int n = read(STDIN_FD, (void*) buffer, 10);
    int result;

    char op_code = buffer[4];

    int n1 = (buffer[0] - '0') * 100 + (buffer[1] - '0') * 10 + buffer[2] - '0';
    int n2 = (buffer[6] - '0') * 100 + (buffer[7] - '0') * 10 + buffer[8] - '0';


    switch(op_code) {
        case '*':
            result = multiply(n1, n2);
            break;
        case '/':
            result = divide(n1, n2);
            break;
        case '%':
            result = remainder(n1, n2);
            break;
    }

    int2char(result, answer);

    write(STDOUT_FD, (void*) answer, 8);

    return 0;
}


void _start()
{
    int ret_code = main();
    exit(ret_code);
}