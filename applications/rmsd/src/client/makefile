CC=gcc
CFLAGS=-Wall -pedantic -ansi -Wextra -ggdb3 -std=c99
CFLAGS+=-I../../include

todo: client

client: client.o
	$(CC) client.o -o client

client.o: client.c
	$(CC) -c $(CFLAGS) client.c

clean:
	rm client.o
	rm client