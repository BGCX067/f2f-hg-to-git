CC=gcc
CFLAGS=-Wall -pedantic -ansi -Wextra -ggdb3 -std=c99
CFLAGS+=-I../../include

todo: server

server: server.o
	$(CC) server.o -lm -o server

server.o: server.c
	$(CC) -c $(CFLAGS) server.c

clean:
	rm server.o
	rm server