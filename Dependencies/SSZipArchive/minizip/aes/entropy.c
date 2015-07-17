#include <fcntl.h>
#include <unistd.h>

#if defined(__cplusplus)
extern "C"
{
#endif

int entropy_fun(unsigned char buf[], unsigned int len)
{

    int frand = open("/dev/random", O_RDONLY);
    ssize_t rlen = 0;
    if (frand != -1)
    {
        rlen = read(frand, buf, len);
        close(frand);
    }
    return (int)rlen;
}
    
#if defined(__cplusplus)
}
#endif
