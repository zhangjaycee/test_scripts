#!/bin/bash


REPORT_INTERVAL=3
MAX_TIME=15
FILE_TOTAL_SIZE=2
FILE_NUM=4

function prepare {
    echo PREPRAE start....
    sysbench --test=fileio cleanup
    sysbench --test=fileio --file-num=$FILE_NUM --file-total-size=${FILE_TOTAL_SIZE}G prepare
    echo PREPRAE done....
}

############ different threads #############
function run_thread {
    
    for THREAD_NUM in 1 2 4 8 16 32
    do
        echo threads: $THREAD_NUM
        sysbench --test=fileio --max-time=$MAX_TIME --report-interval=$REPORT_INTERVAL --max-requests=1000000 \
        --num-threads=$THREAD_NUM --file-total-size=${FILE_TOTAL_SIZE}G --file-num=$FILE_NUM --file-block-size=16k \
        --file-extra-flags=direct --file-test-mode=rndrd run
    done
}




############ different block size #############
function run_block {
    THREAD_NUM=1
    for FILE_BLOCK_SIZE in 1 2 4 8 16 32
    do
        echo threads: $THREAD_NUM
        sysbench --test=fileio --max-time=$MAX_TIME --report-interval=$REPORT_INTERVAL --max-requests=1000000 \
        --num-threads=$THREAD_NUM --file-total-size=${FILE_TOTAL_SIZE}G --file-num=$FILE_NUM --file-block-size=${FILE_BLOCK_SIZE}k \
        --file-extra-flags=direct --file-test-mode=rndrd run
    done
}

if [ $# -eq 1 ] && [ $1 = "prepare" ] # re-prepare or not?
then
    prepare
elif [ $# -ne 2]
then
    echo Usage: $0 [prepare/run/all] [thread/block/...]
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
else
    echo $2 is an illegal parameter
fi




echo done....

