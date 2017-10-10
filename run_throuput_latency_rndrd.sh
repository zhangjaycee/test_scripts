#! /bin/bash

./sysbench_fileio.sh all thread | tee thread_report.txt
./sysbench_fileio.sh run block | tee block_report.txt
