#define _GNU_SOURCE
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <assert.h>
#include <sys/time.h>
#include <immintrin.h>

// map 3 GB
#define MAP_SIZE (3L*1024*1024*1024)

// buffer size 100MB
#define BUF_SIZE (100L*1024*1024)


#define COUNT 10

struct timeval ts, te;

unsigned long long td( struct timeval *t1, struct timeval *t2 )
{
    unsigned long long dt = t2->tv_sec * 1000000 + t2->tv_usec;
    return dt - t1->tv_sec * 1000000 - t1->tv_usec;
}

void st()
{
    gettimeofday(&ts, NULL);
}

unsigned long long et(int count, char *str)
{
     gettimeofday(&te, NULL);
     unsigned long long t = td(&ts, &te) / count;
     printf("%s: %llu us\n", str, t);
     return t;
}

void check(void *buf, unsigned long len, char *c)
{
    unsigned long i;
    for (i = 0; i < len; i++) {
        if (((char *)buf)[i] != c)  {
            printf("WRONG: not %c, wrong copy result!\n", c);
            exit(-1);
        }
    }
}


int main(int argc, char *argv[])
{
    unsigned long i, j;
    unsigned long long t; 
    int fd = open("mmap.test", O_RDWR | O_CREAT, 0755); 
    assert(fd > 0);
    assert(!fallocate(fd, 0, 0, MAP_SIZE));

    void *addr;
    st();
    addr = mmap(NULL, MAP_SIZE, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    t = et(1, "mmap time");
    assert(MAP_FAILED != addr);

    // range memcpy to file

    // allocate 100 MB buffer:
    void *buf = malloc(BUF_SIZE);
    // overwrite first!
    memset(buf, 'X', BUF_SIZE);
    memcpy(addr, buf, BUF_SIZE);
    msync(addr, BUF_SIZE, MS_SYNC); 

    memset(buf, 'A', BUF_SIZE);
    st();
    for (i = 0; i < COUNT; i++)
        memcpy(addr, buf, BUF_SIZE);
    t = et(COUNT, "memcpy write (store) 100 MB time");
    check(buf, BUF_SIZE, 'A');

    memset(buf, 'B', BUF_SIZE);
    st();
    for (i = 0; i < COUNT; i++) {
        memcpy(addr, buf, BUF_SIZE);
        msync(addr, BUF_SIZE, MS_SYNC); 
    }
    t = et(COUNT, "memcpy write (store) + msync 100 MB time");
    check(buf, BUF_SIZE, 'B');

    memset(buf, 'C', BUF_SIZE);
    st();
    for (i = 0; i < COUNT; i++) {
        memcpy(addr, buf, BUF_SIZE);
        for (j = 0; j < BUF_SIZE; j += 64);
            _mm_clflush(addr + j);
    }
    _mm_sfence();
    t = et(COUNT, "memcpy write (store) + clfluch 100 MB time");
    check(buf, BUF_SIZE, 'C');

    // range memcpy from file
    void *buf2 = malloc(BUF_SIZE);
    st();
    for (i = 0; i < COUNT; i++) {
        memcpy(buf2, addr, BUF_SIZE);
    }
    t = et(COUNT, "memcpy read (load) 100 MB time");
    check(buf2, BUF_SIZE, 'C');

    munmap(addr, MAP_SIZE);
    return 0;
}
