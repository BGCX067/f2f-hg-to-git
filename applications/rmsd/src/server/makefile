CC=gcc
CFLAGS=-Wall -pedantic -ansi -Wextra -ggdb3 -std=c99
CFLAGS+=-I../../include
OBJS=../shared/arithmetic.o ../shared/socketTool.o ../shared/endianTool.o

todo: server

server:
	$(CC) $(CFLAGS) rmsdCalc.c server.c $(OBJS) -lm -o server

#server: server.o
#	$(CC) $(OBJS) server.o -lm -o server

#server.o: server.c
#	$(CC) -c $(CFLAGS) server.c

clean:
	rm -f *.o
	rm server