#!/bin/bash

fio pvsync.fio
fio pvsync_wr.fio
fio pvsync_bw.fio
fio pvsync_bw_wr.fio
