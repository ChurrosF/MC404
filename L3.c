#define STDIN_FD  0
#define STDOUT_FD 1

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


int onebyte_char2int(char c)
{
    return c - '0';
}


char onebyte_int2char(int num)
{
    return num + '0';
}


int bin2int(char *bin, int size)
{
    int result = 0;
    int base = 1;
    for (int i = size - 1; i >= 0; i--)
    {
        result += base * onebyte_char2int(bin[i]);
        base *= 2;
    }
    return result;
}


void int2char(int num, char *dst)
{
    int size = 0;
    int b = num;

    if (b == 0) 
    {
        dst[0] = '0';
        dst[1] = '\n';
        return;
    }

    while (b != 0)
    {
        b /= 10;
        size += 1;
    }

    int string_end = size - 1;

    if (num < 0) {
        dst[0] = '-';
        num *= -1;
        string_end += 1;
    }


    for (int i = 0; i < size; i++) {
        dst[string_end - i] = num % 10 + '0';
        num /= 10;
    }

    dst[string_end + 1] = '\n';
}


void extract_bits(int num, char *dst)
{
    for (int i = 0; i < 32; i++)
    {
        dst[33 - i] = onebyte_int2char(num & 1);
        num = num >> 1;
    }
}


void big2little_endian(char *src, char *dst)
{
    for (int i = 0; i < 32; i++)
    {
        dst[26 - ((i / 8) * 8) + (i % 8)] = src[i + 2];
    }
}


void bin2hex(char *src, char *dst)
{
    const char *hex_array = "0123456789abcdef";
    char aux[4];
    for (int i = 0; i < 32; i++)
    {
        aux[i % 4] = src[i + 2];
        if ((i + 1) % 4 == 0)
        {
            int hex_index = bin2int(aux, 4);
            dst[((i - 3) / 4) + 2] = hex_array[hex_index];
        }
    }
}


int main()
{
    char buffer[32];

    int n = read(STDIN_FD, (void*) buffer, 32);

    unsigned int sign = onebyte_char2int(buffer[0]) ? -1 : 1;
    char exp_string[8];
    char binfloat_string[24];

    char decimal_string[32];

    char twos_complement_bin_big_endian[35];
    twos_complement_bin_big_endian[0] = '0';
    twos_complement_bin_big_endian[1] = 'b';
    twos_complement_bin_big_endian[34] = '\n';

    char twos_complement_bin_little_endian[35];
    twos_complement_bin_little_endian[0] = '0';
    twos_complement_bin_little_endian[1] = 'b';
    twos_complement_bin_little_endian[34] = '\n';

    char twos_complement_hex_big_endian[11];
    twos_complement_hex_big_endian[0] = '0';
    twos_complement_hex_big_endian[1] = 'x';
    twos_complement_hex_big_endian[10] = '\n';

    char twos_complement_hex_little_endian[11];
    twos_complement_hex_little_endian[0] = '0';
    twos_complement_hex_little_endian[1] = 'x';
    twos_complement_hex_little_endian[10] = '\n';

    int num_int;

    for (int i = 1; i < 9; i++) 
    {
        exp_string[i - 1] = buffer[i];
    }
    
    int exp_int = bin2int(exp_string, 8) - 127;
    if (exp_int < 0) 
    {
        num_int = 0;
    }
    else 
    {
        binfloat_string[0] = '1';

        for (int i = 9; i < 9 + exp_int; i++) 
        {
            binfloat_string[i - 8] = buffer[i];
        }
        
        binfloat_string[exp_int + 1] = '\0';
        num_int = bin2int(binfloat_string, 1 + exp_int) * sign;
        
        
    }
        int2char(num_int, decimal_string);
        
        write(STDOUT_FD, (void*) decimal_string, 32);
    
        extract_bits(num_int, twos_complement_bin_big_endian);
        write(STDOUT_FD, (void*) twos_complement_bin_big_endian, 35);

        big2little_endian(twos_complement_bin_big_endian, twos_complement_bin_little_endian);
        write(STDOUT_FD, (void*) twos_complement_bin_little_endian, 35);

        bin2hex(twos_complement_bin_big_endian, twos_complement_hex_big_endian);
        write(STDOUT_FD, (void*) twos_complement_hex_big_endian, 11);

        bin2hex(twos_complement_bin_little_endian, twos_complement_hex_little_endian);
        write(STDOUT_FD, (void*) twos_complement_hex_little_endian, 11);

  return 0;
}


void _start()
{
  int ret_code = main();
  exit(ret_code);
}