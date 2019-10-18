#!/bin/bash

FIO_BIN=/home/zjc/bin/fio/bin/fio

$FIO_BIN pvsync_lat.fio
$FIO_BIN pvsync_lat_wr.fio
$FIO_BIN pvsync.fio
$FIO_BIN pvsync_wr.fio
$FIO_BIN pvsync_bw.fio
$FIO_BIN pvsync_bw_wr.fio
