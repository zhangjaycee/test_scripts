#!/bin/bash


SYSBENCH_PATH=sysbench

REPORT_INTERVAL=3
MAX_TIME=21
MAX_REQUEST_NUM=1000000
THREAD_NUM=4

DB_NAME=sbtest
DB_NAME_CMP=sbtest_cmp
TABLE_SIZE=575000 
TABLE_NUM=4          # 575000 * 4 is about 500MB

RAND_SPEC_PCT=1
RAND_SPEC_RES=75

SQL_PREFIX="/usr/local/mysql/bin/mysql -uroot -p1234 -e"
REPORT_FILE="report_multi_ssd.log"

TABLE_OPTION="" 

TABLE_OPTION_CMP="ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=8" 

function prepare_data {
    echo PREPRAE start....
    $SYSBENCH_PATH --test=oltp --max-time=$MAX_TIME --report-interval=$REPORT_INTERVAL --max-requests=$MAX_REQUEST_NUM --num-threads=$THREAD_NUM --rand-init=on \
    --mysql-socket=/tmp/mysql.sock --mysql-host=localhost --mysql-port=3306 --mysql-user=root --mysql-password=1234 --mysql-db=$DB_NAME \
    --oltp-table-size=$TABLE_SIZE --oltp-read-only=on --oltp-tables-count=$TABLE_NUM \
    --mysql-table-options="$TBALE_OPTION" cleanup

    $SYSBENCH_PATH --test=oltp --max-time=$MAX_TIME --report-interval=$REPORT_INTERVAL --max-requests=$MAX_REQUEST_NUM --num-threads=$THREAD_NUM --rand-init=on \
    --mysql-socket=/tmp/mysql.sock --mysql-host=localhost --mysql-port=3306 --mysql-user=root --mysql-password=1234 --mysql-db=$DB_NAME \
    --oltp-table-size=$TABLE_SIZE --oltp-read-only=on --oltp-tables-count=$TABLE_NUM \
    --mysql-table-options="$TBALE_OPTION" prepare
    echo "=======================nocom PREPRAE done....=========================="


    $SYSBENCH_PATH --test=oltp --max-time=$MAX_TIME --report-interval=$REPORT_INTERVAL --max-requests=$MAX_REQUEST_NUM --num-threads=$THREAD_NUM --rand-init=on \
    --mysql-socket=/tmp/mysql.sock --mysql-host=localhost --mysql-port=3306 --mysql-user=root --mysql-password=1234 --mysql-db=$DB_NAME_CMP \
    --oltp-table-size=$TABLE_SIZE --oltp-read-only=on --oltp-tables-count=$TABLE_NUM \
    --mysql-table-options="$TBALE_OPTION_CMP" cleanup

    $SYSBENCH_PATH --test=oltp --max-time=$MAX_TIME --report-interval=$REPORT_INTERVAL --max-requests=$MAX_REQUEST_NUM --num-threads=$THREAD_NUM --rand-init=on \
    --mysql-socket=/tmp/mysql.sock --mysql-host=localhost --mysql-port=3306 --mysql-user=root --mysql-password=1234 --mysql-db=$DB_NAME_CMP \
    --oltp-table-size=$TABLE_SIZE --oltp-read-only=on --oltp-tables-count=$TABLE_NUM \
    --mysql-table-options="$TABLE_OPTION_CMP" prepare
    echo "=======================comped data PREPRAE done....=========================="
}

function run_thread {
    for THREAD_NUM in 1 2 4 8 16 32 64
    do
        echo thread_num: $THREAD_NUM
        $SYSBENCH_PATH --test=oltp --max-time=$MAX_TIME --report-interval=$REPORT_INTERVAL --max-requests=$MAX_REQUEST_NUM --num-threads=$THREAD_NUM --rand-init=on \
        --mysql-socket=/tmp/mysql.sock --mysql-host=localhost --mysql-port=3306 --mysql-user=root --mysql-password=1234 --mysql-db=$DB_NAME \
        --oltp-table-size=$TABLE_SIZE --oltp-read-only=on --oltp-tables-count=$TABLE_NUM --oltp-dist-type=gaussian \
        --mysql-table-options="$TBALE_OPTION" run
    done
}
function run_nocom {
    THREAD_NUM=4
    echo thread_num: $THREAD_NUM
    $SYSBENCH_PATH --test=oltp --max-time=$MAX_TIME --report-interval=$REPORT_INTERVAL --max-requests=$MAX_REQUEST_NUM --num-threads=$THREAD_NUM --rand-init=on \
    --rand-type=$RAND_TYPE --rand-spec-pct=$RAND_SPEC_PCT --rand-spec-res=$RAND_SPEC_RES \
    --mysql-socket=/tmp/mysql.sock --mysql-host=localhost --mysql-port=3306 --mysql-user=root --mysql-password=1234 --mysql-db=$DB_NAME \
    --oltp-table-size=$TABLE_SIZE --oltp-read-only=on --oltp-tables-count=$TABLE_NUM \
    --mysql-table-options="$TBALE_OPTION" run
}

function run_com {
    THREAD_NUM=4
    echo thread_num: $THREAD_NUM
    $SYSBENCH_PATH --test=oltp --max-time=$MAX_TIME --report-interval=$REPORT_INTERVAL --max-requests=$MAX_REQUEST_NUM --num-threads=$THREAD_NUM --rand-init=on \
    --rand-type=$RAND_TYPE --rand-spec-pct=$RAND_SPEC_PCT --rand-spec-res=$RAND_SPEC_RES \
    --mysql-socket=/tmp/mysql.sock --mysql-host=localhost --mysql-port=3306 --mysql-user=root --mysql-password=1234 --mysql-db=$DB_NAME_CMP \
    --oltp-table-size=$TABLE_SIZE --oltp-read-only=on --oltp-tables-count=$TABLE_NUM \
    --mysql-table-options="$TBALE_OPTION_CMP" run
}

if [ $# -eq 1 ] && [ $1 = "prepare" ]
then
    prepare_data
    exit 0
elif [ $# -ne 3 ]
then
    echo Usage: $0 [prepare/run/all] [gauss/unif/pareto...] [nocom/com]
    exit -1
fi


if [ $1 = "all" ]
then
    prepare_data
fi


if [ $2 = gauss ]
then
    RAND_TYPE=gaussian
elif [ $2 = pareto ]
then
    RAND_TYPE=pareto
elif [ $2 = spec ]
then
    RAND_TYPE=special
elif [ $2 = unif ]
then
    RAND_TYPE=uniform
else
    echo $2 is an illegal parameter
    exit -1
fi

if [ $3 = nocom ]
then
    run_nocom
elif [ $3 = com ]
then
    run_com
else
    echo $3 is an illegal parameter
    exit -1
fi

echo done....
