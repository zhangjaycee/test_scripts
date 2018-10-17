#!/usr/bin/env python

'''
by jaycee 20181017
Draw flame graph of cl_searching

Usage:
    ./flame.py <seconds> <identifer>
For example, the command
    ./flame.py 100 nbluene-HDD
will generate "cpu-flame-nblucene-HDD-100secs.svg" and "io-flame-nblucene-HDD-100secs.svg"
'''

TEST_CPU = True
TEST_IO = False

DROPCACHE_INTERVAL = 5

import sys
import os
import time
import threading
from subprocess import check_output

def th_dropcache():
    with open('/proc/sys/vm/drop_caches', 'w') as stream:
        stream.write("1\n");
    time.sleep(DROPCACHE_INTERVAL)

def th_shell(cmds, identifer):
    for cmd in cmds:
        print identifer, cmd
        os.system(cmd)
    
print "hello"

if os.geteuid() != 0:
    print "This program must be run as root. Aborting."
    sys.exit(1)

if len(sys.argv) != 3:
    print "Wrong parameter number:"
    print "\tusage:", sys.argv[0], "<seconds> <identifer>"
    sys.exit(1)

test_time = sys.argv[1]
identifer = sys.argv[2]
pid = check_output(["pidof","cl_searching"]).split()[0]

# on-CPU flame graph commands:
cmd1 = "perf record -F 99 -g -p " + pid + " sleep " + test_time
cmd2 = "perf script | ./stackcollapse-perf.pl > out.perf-folded"
cmd3 = "./flamegraph.pl --width 1400 out.perf-folded > cpu-flame-" + identifer + "-" + test_time +"secs" + ".svg"
cmd_cpu = [cmd1, cmd2, cmd3]
cpu_th = threading.Thread(target = th_shell, args = (cmd_cpu, "<CPU> ", ))

# off-CPU flame graph commands:
cmd1 = "./fileiostacks.py -f " + test_time + " > out.stacks"
cmd2 = "grep cl_searching out.stacks | ./flamegraph.pl --width 1400 --color=io --title=\"File I/O Time Flame Graph\" --countname=us > io-flame-" + identifer + "-" + test_time +"secs" + ".svg"
cmd_io = [cmd1, cmd2]
io_th = threading.Thread(target = th_shell, args = (cmd_io, "<IO>  ", ))

# drop page cache first
with open('/proc/sys/vm/drop_caches', 'w') as stream:
    stream.write("1\n");

dropcache_th = threading.Thread(target = th_dropcache)

# start testing
dropcache_th.start()
if TEST_CPU:
    cpu_th.start()
if TEST_IO:
    io_th.start()
print "thread started"
if TEST_CPU:
    cpu_th.join()
if TEST_IO:
    io_th.join()
print "thread done"
