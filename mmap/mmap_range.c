#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <assert.h>
#include <sys/time.h>
#include <immintrin.h>

// map 3 GB
#define MAP_SIZE (15UL*1024*1024*1024)

// buffer size 100MB
#define BUF_SIZE (128UL*1024*1024)


#define COUNT 100

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
     printf("%s\t%llu us\t", str, t);
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

void gen_rand(unsigned long *rand_off)
{
    int i;
    for (i = 0; i < COUNT; i++) {
        rand_off[i] = (unsigned long)rand() % (MAP_SIZE - 100UL*1024*1024);
        assert(rand_off[i] < MAP_SIZE);
        //printf("%lu MB \n", rand_off[i] / 1024 / 1024);
    }
}

int main(int argc, char *argv[])
{

    unsigned long i, j;
    unsigned long long t; 
    time_t tt;
    srand((unsigned) time(&tt));
    unsigned long rand_off[COUNT];

    int fd = open("mmap.test", O_RDWR | O_CREAT, 0755); 
    assert(fd > 0);
    assert(!fallocate(fd, 0, 0, MAP_SIZE));

    void *addr;
    st();
    addr = mmap(NULL, MAP_SIZE, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    t = et(1, "mmap time\n");
    printf("\n\n");
    assert(MAP_FAILED != addr);

    // ====================== A. RANGE memcpy ======================
    printf("====================== A. RANGE memcpy ======================\n");

    printf("overwriting...\n");
    // allocate 100 MB buffer:
    void *buf = malloc(BUF_SIZE);
    // overwrite first!
    memset(buf, 'X', BUF_SIZE);
    for (i = 0; i < MAP_SIZE; i += BUF_SIZE) {
        //printf("i: %lu\n", i);
        memcpy(addr + i, buf, BUF_SIZE);
    }
    msync(addr, MAP_SIZE, MS_SYNC); 
    printf("overwrite done,,,checking...\n");
    check(addr, MAP_SIZE, 'X');
    printf("checking OK , all %c\n", ((char *)addr)[0]);

    // A1 range write without sync 
    memset(buf, 'A', BUF_SIZE);
    gen_rand(rand_off);
    st();
    for (i = 0; i < COUNT; i++) {
        memcpy(addr + rand_off[i], buf, BUF_SIZE);
    }
    t = et(COUNT, "memcpy write (store) 100 MB time\n");
    printf("Bandwidth: %lu MB/s\n\n", BUF_SIZE / 1024 / 1024 * 1000000 / t);
    check(addr + rand_off[COUNT-1], BUF_SIZE, 'A');

    // A2 range write with msync
    memset(buf, 'B', BUF_SIZE);
    gen_rand(rand_off);
    st();
    for (i = 0; i < COUNT; i++) {
        memcpy(addr + rand_off[i], buf, BUF_SIZE);
        msync(addr + rand_off[i], BUF_SIZE, MS_SYNC); 
    }
    t = et(COUNT, "memcpy write (store) + msync 100 MB time\n");
    printf("Bandwidth: %lu MB/s\n\n", BUF_SIZE / 1024 / 1024 * 1000000 / t);
    check(addr + rand_off[COUNT - 1], BUF_SIZE, 'B');

    // A3 range write with clflush
    memset(buf, 'C', BUF_SIZE);
    gen_rand(rand_off);
    st();
    for (i = 0; i < COUNT; i++) {
        memcpy(addr + rand_off[i], buf, BUF_SIZE);
        for (j = 0; j < BUF_SIZE; j += 64);
            _mm_clflush(addr + rand_off[i] + j);
    }
    _mm_sfence();
    t = et(COUNT, "memcpy write (store) + clfluch 100 MB time\n");
    printf("Bandwidth: %lu MB/s\n\n", BUF_SIZE / 1024 / 1024 * 1000000 / t);
    check(addr + rand_off[COUNT - 1], BUF_SIZE, 'C');

    // range memcpy from file
    void *buf2 = malloc(BUF_SIZE);
    st();
    for (i = 0; i < COUNT; i++) {
        memcpy(buf2, addr + rand_off[i], BUF_SIZE);
    }
    t = et(COUNT, "memcpy read (load) 100 MB time\n");
    printf("Bandwidth: %lu MB/s\n\n", BUF_SIZE / 1024 / 1024 * 1000000 / t);
    check(buf2, BUF_SIZE, 'C');


    munmap(addr, MAP_SIZE);
    return 0;
}
