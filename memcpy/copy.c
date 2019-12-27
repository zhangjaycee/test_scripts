#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <string.h>
#include <fcntl.h>
#include <assert.h>
#include <sys/mman.h>
#include <sys/time.h>


#include "spdk/stdinc.h"
#include "spdk/ioat.h"
#include "spdk/env.h"
#include "spdk/queue.h"
#include "spdk/string.h"
#include "ioat_channel.h"
extern TAILQ_HEAD(, ioat_device) g_devices;
extern int g_ioat_chan_num;
extern struct ioat_device *g_next_device;

#define MALLOC_MEM 0
#define DAXFS 1
#define N 10
#define DAX_PATH "/mnt/pmem1"
//#define BUFFER_SIZE (1024 * 1024 * 1024)
#define BUFFER_SIZE (128 * 1024 * 1024)
//#define BUFFER_SIZE (2 * 1024 * 1024)
//#define BUFFER_SIZE (64 * 1024)

struct timeval t0, t1;
unsigned long long td( struct timeval *t1, struct timeval *t2 )
{
    unsigned long long dt = t2->tv_sec * 1000000 + t2->tv_usec;
    return dt - t1->tv_sec * 1000000 - t1->tv_usec;
}

void print_result(size_t buffer_size) 
{
    unsigned long long time = td(&t0, &t1);
    printf("time: %llu us bandwidth: %llu MB/s (%llu KB/s)\n", td(&t0, &t1), 
                                buffer_size / 1024 / 1024 * N * 1000 * 1000 / time,
                                buffer_size / 1024 * N * 1000 * 1000 / time);
}

void *my_malloc(size_t size)
{
    return spdk_malloc(size, 4096, NULL, SPDK_ENV_LCORE_ID_ANY, SPDK_MALLOC_DMA);
    //return malloc(size);
}


void *memcpy_single(void *dst, const void *src, size_t n)
{
    return memcpy(dst, src, n);
}

struct memcpy_th_arg {
    void *dst;
    void *src;
    size_t n;
};

void *memcpy_st(void *args)
{
    struct memcpy_th_arg *my_args = (struct memcpy_th_arg *)args;
    return memcpy(my_args->dst, my_args->src, my_args->n);
}

void *memcpy_mt(void *dst, const void *src, size_t buffer_size, int thread_number)
{
    pthread_t memcpy_th[thread_number];
    size_t chunk_size = buffer_size / thread_number;
    for (int i = 0; i < thread_number; i++) {
        struct memcpy_th_arg *my_args = malloc(sizeof(struct memcpy_th_arg));
        my_args->dst = dst + chunk_size * i;
        my_args->src = src + chunk_size * i;
        my_args->n = chunk_size;
        if (pthread_create(&memcpy_th[i], NULL, memcpy_st, (void *)my_args)) {
            printf("Creating thread failed!\n");
        }
    }
    for (int i = 0; i < thread_number; i++) {
        pthread_join(memcpy_th[i], NULL);
    }
    return NULL;
}


void copy_completion_cb(void *arg)
{
    // here, arg is the `copy_done`
    *(bool *)arg = true;
}
int ioat_copy_single_channel(void *dst, void *src, size_t buffer_size, int thread_number)
{
    /*
    if (TAILQ_EMPTY(&g_devices)) {
        printf("empty!\n");
    } else {
        printf("not empty!\n");
    }
    */
    g_next_device = TAILQ_FIRST(&g_devices);
    bool copy_done = false;
    struct spdk_ioat_chan *ch = get_next_chan();
    if (ch != NULL) {
        spdk_ioat_submit_copy(
            ch,
            &copy_done,
            copy_completion_cb,
            dst,
            src,
            buffer_size);
        while (!copy_done)
            spdk_ioat_process_events(ch);
    } else {
        printf("no ioat channel is probed\n"); 
        ioat_exit();
        return -1;
    }
    return 0;
}


int ioat_copy_multi_channel(void *dst, void *src, size_t buffer_size, int thread_number)
{
    if (g_ioat_chan_num < thread_number) {
        printf("number of ioat channel is not enough\n");
        return -1;
    }
    bool copy_done[thread_number];
    for (int i = 0; i < thread_number; i++)
        copy_done[i] = false;
    struct spdk_ioat_chan *ch;
    size_t chunk_size = buffer_size / thread_number;
    g_next_device = TAILQ_FIRST(&g_devices);
    for (int i = 0; i < thread_number; i++) {
        ch = get_next_chan();
        spdk_ioat_submit_copy(
            ch,
            &copy_done[i],
            copy_completion_cb,
            dst + i * chunk_size,
            src + i * chunk_size,
            chunk_size);
    }
    g_next_device = TAILQ_FIRST(&g_devices);
    for (int i = 0; i < thread_number; i++) {
        ch = get_next_chan();
        while (!copy_done[i])
            spdk_ioat_process_events(ch);
    }
    return 0;
}

int my_copy_task(int ram_device, size_t buffer_size, int thread_number)
{
    if (buffer_size % thread_number != 0) {
        printf("buffer_size should be multiple times of the thread_number!\n");
        return -1; 
    }

    void *buf_src;
    void *buf_dst; 
    if (ram_device == DAXFS) {
        printf("DAX not supportted for ioat copying now\n");
        return -1;
        // TODO
        char dax_filename[100];
        sprintf(dax_filename, "%s/testfile_for_test_copy\0", DAX_PATH);
        int fd = open(dax_filename, O_CREAT|O_RDWR, 0755);
        if (fd == -1) {
            printf("dax file open failed!\n");
            return -1;
        } else {
            printf("dax file opened!\n");
        }
        fallocate(fd, 0, 0, buffer_size * 2);
        buf_dst = mmap(NULL, buffer_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        assert(buf_dst != MAP_FAILED);
        buf_src = mmap(NULL, buffer_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, buffer_size);
        assert(buf_src != MAP_FAILED);
        printf("================================ DAX ==============================\n");
    } else {    
        //buf_src = malloc(buffer_size);
        //buf_dst = malloc(buffer_size);
        buf_src = my_malloc(buffer_size);
        buf_dst = my_malloc(buffer_size);
        printf("================================ MEM ==============================\n");
    }

    printf("Starting new task:\n\tBuffer Size: %d MB  thread_number: %d chunk_size: %d KB\n",
                    buffer_size / 1024 / 1024, thread_number, buffer_size / thread_number);
/**/
    printf("-----------------------------------------------------------------------\n");
    
    printf("starting single thread memcpy test.. (%d times)\n", N);
    gettimeofday(&t0, NULL);
    for (int i = 0; i < N; i++) {
        memcpy_single(buf_dst, buf_src, buffer_size);
    }
    gettimeofday(&t1, NULL);
    print_result(buffer_size);

    printf("-----------------------------------------------------------------------\n");
    printf("starting multi-thread memcpy test.. (%d times)\n", N);
    gettimeofday(&t0, NULL);
    for (int i = 0; i < N; i++){
        memcpy_mt(buf_dst, buf_src, buffer_size, thread_number);
    }
    gettimeofday(&t1, NULL);
    print_result(buffer_size);
/**/
    
    printf("-----------------------------------------------------------------------\n");


    printf("starting single thread ioat copy test.. (%d times)\n", N);
    gettimeofday(&t0, NULL);
    for (int i = 0; i < N; i++){
        ioat_copy_single_channel(buf_dst, buf_src, buffer_size, thread_number);
    }
    gettimeofday(&t1, NULL);
    print_result(buffer_size);

    printf("-----------------------------------------------------------------------\n");
    printf("starting multi-thread ioat copy test.. (%d times)\n", N);
    gettimeofday(&t0, NULL);
    for (int i = 0; i < N; i++){
        ioat_copy_multi_channel(buf_dst, buf_src, buffer_size, thread_number);
    }
    gettimeofday(&t1, NULL);
    print_result(buffer_size);
    printf("=======================================================================\n");
    return 0;
}

int main(int argc, void **argvs)
{
    if (argc != 2) {
        printf("Usage: %s [mem|dax]\n", argvs[0]);
        return -1;
    }
    init();
    ioat_init();
    struct timeval t_start, t_end;
    gettimeofday(&t_start, NULL);
    //my_copy_task(MALLOC_MEM, 1024 * 1024 * 1024, 2);
    if (!strcmp(argvs[1], "mem"))
        my_copy_task(MALLOC_MEM, BUFFER_SIZE, 8);
    else if (!strcmp(argvs[1], "dax"))
        my_copy_task(DAXFS, BUFFER_SIZE, 8);
    ioat_exit();
    gettimeofday(&t_end, NULL);
    printf("program running time: %lu ms\n", td(&t_start, &t_end) / 1000);
    return 0;
}
