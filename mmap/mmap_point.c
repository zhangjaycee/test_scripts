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
#include <string.h>

// map 3 GB
#define MAP_SIZE (15UL*1024*1024*1024)

// buffer size 100MB
#define BUF_SIZE (128UL*1024*1024)


#define COUNT 10000

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
     unsigned long long t = td(&ts, &te);
     printf("%s\t%d times: %llu us\t", str, COUNT, t);
     return t;
}

void check(void *buf, unsigned long len, char c)
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


    // ====================== B. POINT ACCESS ======================
    printf("====================== B. POINT ACCESS======================\n");
    printf("overwriting...\n");
    // allocate 100 MB buffer:
    // overwrite first!
    void *buf = malloc(BUF_SIZE);
    memset(buf, 'X', BUF_SIZE);
    for (i = 0; i < MAP_SIZE; i += BUF_SIZE) {
        //printf("i: %lu\n", i);
        memcpy(addr + i, buf, BUF_SIZE);
    }
    msync(addr, MAP_SIZE, MS_SYNC); 
    printf("overwrite done,,,checking...\n");
    check(addr, MAP_SIZE, 'X');
    printf("checking OK , all %c\n", ((char *)addr)[0]);

    // B1 point write
    gen_rand(rand_off);
    st();
    for (i = 0; i < COUNT; i++) {
        *((char *)(addr + rand_off[i])) = 'A';
    }
    t = et(COUNT, "point write time:\n");
    for (i = 0; i < COUNT; i++) {
        if (*((char *)(addr + rand_off[i])) != 'A') {
            printf("B1: not A!\n");
            exit(-1);
        }
    }
    printf("\n");

    // B2 point write with msync
    gen_rand(rand_off);
    st();
    for (i = 0; i < COUNT; i++) {
        *((char *)(addr + rand_off[i])) = 'A';
        msync(addr + rand_off[i], 1, MS_SYNC);
    }
    t = et(COUNT, "point write + msync\n");
    for (i = 0; i < COUNT; i++) {
        if (*((char *)(addr + rand_off[i])) != 'A') {
            printf("B1: not A!\n");
            exit(-1);
        }
    }
    printf("\n");

    // B1 point write
    gen_rand(rand_off);
    st();
    for (i = 0; i < COUNT; i++) {
        *((char *)(addr + rand_off[i])) = 'A';
    }
    t = et(COUNT, "point write time:\n");
    for (i = 0; i < COUNT; i++) {
        if (*((char *)(addr + rand_off[i])) != 'A') {
            printf("B1: not A!\n");
            exit(-1);
        }
    }
    printf("\n");

    // B3 point write with clflush
    gen_rand(rand_off);
    st();
    for (i = 0; i < COUNT; i++) {
        *((char *)(addr + rand_off[i])) = 'A';
        _mm_clflush(addr + rand_off[i]);
    }
    t = et(COUNT, "point write + clflush:\n");
    for (i = 0; i < COUNT; i++) {
        if (*((char *)(addr + rand_off[i])) != 'A') {
            printf("B1: not A!\n");
            exit(-1);
        }
    }
    printf("\n");

    // B1 point write
    gen_rand(rand_off);
    st();
    for (i = 0; i < COUNT; i++) {
        *((char *)(addr + rand_off[i])) = 'A';
    }
    t = et(COUNT, "point write time:\n");
    for (i = 0; i < COUNT; i++) {
        if (*((char *)(addr + rand_off[i])) != 'A') {
            printf("B1: not A!\n");
            exit(-1);
        }
    }
    printf("\n");


    // B4 point read
    char read_arr[COUNT];
    gen_rand(rand_off);
    st();
    for (i = 0; i < COUNT; i++) {
        read_arr[i] = *((char *)(addr + rand_off[i]));
    }
    t = et(COUNT, "point read time:\n");
    for (i = 0; i < COUNT; i+=100) {
        printf("%c", read_arr[i]);
    }
    printf("\n");


    munmap(addr, MAP_SIZE);
    return 0;
}
