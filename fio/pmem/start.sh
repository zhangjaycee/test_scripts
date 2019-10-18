#!/bin/bash

FIO_BIN=/home/zjc/bin/fio/bin/fio

echo "==============mmap==========="
$FIO_BIN mmap_lat.fio
$FIO_BIN mmap_lat_wr.fio
$FIO_BIN mmap.fio
$FIO_BIN mmap_wr.fio
$FIO_BIN mmap_bw.fio
$FIO_BIN mmap_bw_wr.fio

echo "==============pvsync==========="
$FIO_BIN pvsync_lat.fio
$FIO_BIN pvsync_lat_wr.fio
$FIO_BIN pvsync.fio
$FIO_BIN pvsync_wr.fio
$FIO_BIN pvsync_bw.fio
$FIO_BIN pvsync_bw_wr.fio
