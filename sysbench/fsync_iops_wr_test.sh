#!/bin/bash

echo '==================CORE NUM: 1======================'
taskset 0x0001 ./sysbench_fileio.sh run iops_wr
echo '==================CORE NUM: 2======================'
taskset 0x0003 ./sysbench_fileio.sh run iops_wr
echo '==================CORE NUM: 3======================'
taskset 0x0007 ./sysbench_fileio.sh run iops_wr
echo '==================CORE NUM: 4======================'
taskset 0x000f ./sysbench_fileio.sh run iops_wr
echo '==================CORE NUM: 5======================'
taskset 0x001f ./sysbench_fileio.sh run iops_wr
echo '==================CORE NUM: 6======================'
taskset 0x003f ./sysbench_fileio.sh run iops_wr
echo '==================CORE NUM: 7======================'
taskset 0x007f ./sysbench_fileio.sh run iops_wr
echo '==================CORE NUM: 8======================'
taskset 0x00ff ./sysbench_fileio.sh run iops_wr
echo '==================CORE NUM: 10====================='
taskset 0x07ff ./sysbench_fileio.sh run iops_wr
echo '==================CORE NUM: 12====================='
taskset 0x0fff ./sysbench_fileio.sh run iops_wr
echo '==================CORE NUM: 14====================='
taskset 0x7fff ./sysbench_fileio.sh run iops_wr
echo '==================CORE NUM: 16====================='
taskset 0xffff ./sysbench_fileio.sh run iops_wr
