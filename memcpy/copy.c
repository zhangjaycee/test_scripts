#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <string.h>

#define MALLOC_MEM 0
#define DAXFS 1
#define N 10000


struct timeval t0, t1;
unsigned long long td( struct timeval *t1, struct timeval *t2 )
{
    unsigned long long dt = t2->tv_sec * 1000000 + t2->tv_usec;
    return dt - t1->tv_sec * 1000000 - t1->tv_usec;
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




int my_copy_task(int ram_device, size_t buffer_size, int thread_number)
{
    if (buffer_size % thread_number != 0) {
        printf("buffer_size should be multiple times of the thread_number!\n");
        return -1; 
    }

    void *buf_src;
    void *buf_dst; 
    if (ram_device == DAXFS) {
        // TODO
        printf("DAX mode not supported yet!\n");
        return -1; 
    } else {    
        buf_src = malloc(buffer_size * 20);
        buf_dst = malloc(buffer_size * 20);
    }
    
    for (int i = 0; i < N; i++) {
        memcpy_single(buf_dst, buf_src, buffer_size);
        //usleep(100);
    }
    for (int i = 0; i < N; i++){
        memcpy_mt(buf_dst, buf_src, buffer_size, thread_number);
        //usleep(1);
    }
    printf("done\n");
    //ioat_copy_st();
    //ioat_copy_mt();
    return 0;
}


int main()
{
    gettimeofday(&t0, NULL);
    //my_copy_task(MALLOC_MEM, 1024 * 1024 * 1024, 2);
    my_copy_task(MALLOC_MEM, 1024 * 1024 * 2, 2);
    gettimeofday(&t1, NULL);
    printf("program running time: %lu us\n", td(&t0, &t1));
    return 0;
}
