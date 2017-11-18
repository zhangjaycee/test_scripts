#!/bin/bash


SYSBENCH_PATH=/home/zjc/bin/sysbench-1.0/bin/sysbench

REPORT_INTERVAL=5
MAX_TIME=50
FILE_TOTAL_SIZE=20
FILE_NUM=1

function prepare {
    echo PREPRAE start....
    $SYSBENCH_PATH --test=fileio cleanup
    $SYSBENCH_PATH --test=fileio --file-num=$FILE_NUM --file-total-size=${FILE_TOTAL_SIZE}G prepare
    echo PREPRAE done....
}

function run_thread {
    FILE_BLOCK_SIZE=16
    for THREAD_NUM in 1 2 4 8 16 32 64
    do
        echo thread_num: $THREAD_NUM
        $SYSBENCH_PATH --test=fileio --max-time=$MAX_TIME --report-interval=$REPORT_INTERVAL --max-requests=1000000 \
        --num-threads=$THREAD_NUM --file-total-size=${FILE_TOTAL_SIZE}G --file-num=$FILE_NUM --file-block-size=${FILE_BLOCK_SIZE}k \
        --file-extra-flags=direct --file-test-mode=rndrd run
    done
}

function run_block {
    THREAD_NUM=4
    for FILE_BLOCK_SIZE in 1 2 4 8 16 32 64 128 256 512 1024 2048 4096 8192
    do
        echo block_size: ${FILE_BLOCK_SIZE}kB
        $SYSBENCH_PATH --test=fileio --max-time=$MAX_TIME --report-interval=$REPORT_INTERVAL --max-requests=1000000 \
        --num-threads=$THREAD_NUM --file-total-size=${FILE_TOTAL_SIZE}G --file-num=$FILE_NUM --file-block-size=${FILE_BLOCK_SIZE}k \
        --file-extra-flags=direct --file-test-mode=rndrd run
    done
}

function run_bandwidth {
    THREAD_NUM=16
    FILE_BLOCK_SIZE=64
    echo "full throughput"
    echo "block_size: ${FILE_BLOCK_SIZE}kB thread_num: $THREAD_NUM"
    $SYSBENCH_PATH --test=fileio --max-time=$MAX_TIME --report-interval=$REPORT_INTERVAL --max-requests=1000000000 \
    --num-threads=$THREAD_NUM --file-total-size=${FILE_TOTAL_SIZE}G --file-num=$FILE_NUM --file-block-size=${FILE_BLOCK_SIZE}k \
    --file-extra-flags=direct --file-test-mode=seqrd run
}

function run_bandwidth_write {
    THREAD_NUM=4
    FILE_BLOCK_SIZE=8192
    echo "full throughput"
    echo "block_size: ${FILE_BLOCK_SIZE}kB thread_num: $THREAD_NUM"
    $SYSBENCH_PATH --test=fileio --max-time=$MAX_TIME --report-interval=$REPORT_INTERVAL --max-requests=1000000000 \
    --num-threads=$THREAD_NUM --file-total-size=${FILE_TOTAL_SIZE}G --file-num=$FILE_NUM --file-block-size=${FILE_BLOCK_SIZE}k \
    --file-extra-flags=direct --file-test-mode=seqwr run
}

function run_iops {
    THREAD_NUM=64
    FILE_BLOCK_SIZE=4
    echo "full CPU"
    echo "block_size: ${FILE_BLOCK_SIZE}kB thread_num: $THREAD_NUM"
    $SYSBENCH_PATH --test=fileio --max-time=$MAX_TIME --report-interval=$REPORT_INTERVAL --max-requests=1000000000 \
    --num-threads=$THREAD_NUM --file-total-size=${FILE_TOTAL_SIZE}G --file-num=$FILE_NUM --file-block-size=${FILE_BLOCK_SIZE}k \
    --file-extra-flags=direct --file-test-mode=rndrd run
}

function run_latency_sensitive {
    THREAD_NUM=1
    FILE_BLOCK_SIZE=4
    echo "full CPU"
    echo "block_size: ${FILE_BLOCK_SIZE}kB thread_num: $THREAD_NUM"
    $SYSBENCH_PATH --test=fileio --max-time=$MAX_TIME --report-interval=$REPORT_INTERVAL --max-requests=1000000000 \
    --num-threads=$THREAD_NUM --file-total-size=${FILE_TOTAL_SIZE}G --file-num=$FILE_NUM --file-block-size=${FILE_BLOCK_SIZE}k \
    --file-extra-flags=direct --file-test-mode=rndrd run
}

if [ $# -eq 1 ] && [ $1 = "prepare" ]
then
    prepare
    exit 0
elif [ $# -ne 2 ]
then
    echo Usage: $0 [prepare/run/all] [thread/block/...]
    exit -1
fi


if [ $1 = "all" ]
then
    prepare
fi


if [ $2 = "thread" ]
then
    run_thread
elif [ $2 = "block" ]
then
    run_block
elif [ $2 = "bw" ]
then
    run_bandwidth
elif [ $2 = "bw_wr" ]
then
    run_bandwidth_write
elif [ $2 = "iops" ]
then
    run_iops
elif [ $2 = "lat" ]
then
    run_latency_sensitive
else
    echo $2 is an illegal parameter
fi

echo done....
