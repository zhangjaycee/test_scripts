#!/bin/bash


SYSBENCH_PATH=sysbench

REPORT_INTERVAL=5
MAX_TIME=50
FILE_TOTAL_SIZE=16
FILE_NUM=4

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

function run_full_throughput {
    THREAD_NUM=4
    FILE_BLOCK_SIZE=8192
    echo "full throughput"
    echo "block_size: ${FILE_BLOCK_SIZE}kB thread_num: $THREAD_NUM"
    $SYSBENCH_PATH --test=fileio --max-time=$MAX_TIME --report-interval=$REPORT_INTERVAL --max-requests=1000000 \
    --num-threads=$THREAD_NUM --file-total-size=${FILE_TOTAL_SIZE}G --file-num=$FILE_NUM --file-block-size=${FILE_BLOCK_SIZE}k \
    --file-extra-flags=direct --file-test-mode=rndrd run
}

function run_full_cpu {
    THREAD_NUM=64
    FILE_BLOCK_SIZE=4
    echo "full CPU"
    echo "block_size: ${FILE_BLOCK_SIZE}kB thread_num: $THREAD_NUM"
    $SYSBENCH_PATH --test=fileio --max-time=$MAX_TIME --report-interval=$REPORT_INTERVAL --max-requests=1000000 \
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
elif [ $2 = "full_throughput" ]
then
    run_full_throughput
elif [ $2 = "full_cpu" ]
then
    run_full_cpu
else
    echo $2 is an illegal parameter
fi

echo done....
