#!/bin/bash

FIO_BIN=fio

${FIO_BIN} latency.fio
${FIO_BIN} latency_seq.fio
${FIO_BIN} latency_wr.fio
${FIO_BIN} latency_wr_seq.fio
