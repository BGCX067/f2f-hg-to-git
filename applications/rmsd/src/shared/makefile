CC=gcc
CFLAGS=-Wall -pedantic -ansi -Wextra -ggdb3 -std=c99
CFLAGS+=-I../../include

todo: endianTool socketTool arithmetic

endianTool:
	$(CC) -c $(CFLAGS) endianTool.c
	
socketTool:
	$(CC) -c $(CFLAGS) socketTool.c
	
arithmetic:
	$(CC) -c $(CFLAGS) arithmetic.c

clean:
	rm *.o
