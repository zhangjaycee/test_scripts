#!/bin/bash


REPORT_INTERVAL=3
MAX_TIME=15

#~/sb_iotest/prepare.sh
#### PREPARE #######




############ different threads #############
sysbench --max-time=$MAX_TIME --report-interval=$REPORT_INTERVAL --max-requests=1000000 --file-block-size=16k --test=fileio --num-threads=16 --file-extra-flags=direct --file-total-size=1G --file-test-mode=rndrd run
sysbench --max-time=$MAX_TIME --report-interval=$REPORT_INTERVAL --max-requests=1000000 --file-block-size=16k --test=fileio --num-threads=8 --file-extra-flags=direct --file-total-size=1G --file-test-mode=rndrd run
sysbench --max-time=$MAX_TIME --report-interval=$REPORT_INTERVAL --max-requests=1000000 --file-block-size=16k --test=fileio --num-threads=4 --file-extra-flags=direct --file-total-size=1G --file-test-mode=rndrd run
sysbench --max-time=$MAX_TIME --report-interval=$REPORT_INTERVAL --max-requests=1000000 --file-block-size=16k --test=fileio --num-threads=2 --file-extra-flags=direct --file-total-size=1G --file-test-mode=rndrd run
sysbench --max-time=$MAX_TIME --report-interval=$REPORT_INTERVAL --max-requests=1000000 --file-block-size=16k --test=fileio --num-threads=1 --file-extra-flags=direct --file-total-size=1G --file-test-mode=rndrd run
#sysbench --max-time=30 --max-requests=1000000 --file-block-size=16k --test=fileio --num-threads=16 --file-extra-flags=direct --file-total-size=1G --file-test-mode=rndwr run


#sysbench --max-time=30 --max-requests=1000000 --file-block-size=8k --test=fileio --num-threads=16 --file-extra-flags=direct --file-total-size=1G --file-test-mode=rndrd run
#sysbench --max-time=30 --max-requests=1000000 --file-block-size=8k --test=fileio --num-threads=16 --file-extra-flags=direct --file-total-size=1G --file-test-mode=rndwr run

