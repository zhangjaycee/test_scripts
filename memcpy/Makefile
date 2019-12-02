SPDK_ROOT_DIR := /home/zjc/srcs/spdk

include $(SPDK_ROOT_DIR)/mk/spdk.common.mk

APP = copy

C_SRCS := copy.c ioat_channel.c

SPDK_LIB_LIST = ioat thread util log

include $(SPDK_ROOT_DIR)/mk/spdk.app.mk

all:
	#gcc copy.c -lpthread -g --std=c99 -o copy
	sed "s:BINPATH:$(PWD)/copy:g" copy.bpftrace_template > copy.bpftrace
clean:
	rm *.o
	rm *.d
	rm copy
	rm copy.bpftrace
