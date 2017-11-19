# memory options:
#   --memory-block-size=SIZE    size of memory block for test [1K]
#   --memory-total-size=SIZE    total size of data to transfer [100G]
#   --memory-scope=STRING       memory access scope {global,local} [global]
#   --memory-hugetlb=[on|off]   allocate memory from HugeTLB pool [off]
#   --memory-oper=STRING        type of memory operations {read, write, none} [write]
#   --memory-access-mode=STRING memory access mode {seq,rnd} [seq]

#SYSBENCH_BIN=/home/zjc/bin/sysbench/bin/sysbench
SYSBENCH_BIN=/home/zjc/bin/sysbench-zjc/bin/sysbench


# Throughput
#${SYSBENCH_BIN} --threads=16 --time=30 --test=memory --memory-block-size=64K --memory-total-size=200G --memory-access-mode=rnd --memory-oper=read run

# Latency
${SYSBENCH_BIN} --threads=1 --time=30 --percentile=99 --test=memory --memory-block-size=4K --memory-total-size=20G --memory-access-mode=rnd --memory-oper=read run
${SYSBENCH_BIN} --threads=1 --time=30 --percentile=99 --test=memory --memory-block-size=4K --memory-total-size=20G --memory-access-mode=seq --memory-oper=read run
${SYSBENCH_BIN} --threads=1 --time=30 --percentile=99 --test=memory --memory-block-size=4K --memory-total-size=20G --memory-access-mode=rnd --memory-oper=write run
${SYSBENCH_BIN} --threads=1 --time=30 --percentile=99 --test=memory --memory-block-size=4K --memory-total-size=20G --memory-access-mode=seq --memory-oper=write run

