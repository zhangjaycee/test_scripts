#ifndef IOAT_CHANNEL_H
#define IOAT_CHANNEL_H

#include "spdk/stdinc.h"

#include "spdk/ioat.h"
#include "spdk/env.h"
#include "spdk/queue.h"
#include "spdk/string.h"

//extern TAILQ_HEAD(, ioat_device) g_devices;
//extern int g_ioat_chan_num = 0;

struct user_config {
    int xfer_size_bytes;
    int queue_depth;
    int time_in_sec;
    bool verify;
    char *core_mask;
    int ioat_chan_num;
};

int init(void);
int ioat_init(void);
void ioat_exit(void);
struct spdk_ioat_chan *get_next_chan(void);
void dump_user_config(struct user_config *self);
#endif
