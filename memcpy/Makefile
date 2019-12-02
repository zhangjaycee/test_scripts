all:
	gcc copy.c -lpthread -g --std=c99 -o copy
	sed "s:BINPATH:$(PWD)/copy:g" copy.d_tmplate > copy.d
clean:
	rm copy
	rm copy.d
