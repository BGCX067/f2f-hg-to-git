CC=gcc
CFLAGS=-Wall -pedantic -ansi -Wextra -ggdb3 -std=c99
CFLAGS+=-I../../include
OBJS=../shared/arithmetic.o ../shared/socketTool.o ../shared/endianTool.o

todo: client

client:
	$(CC) $(CFLAGS) client.c $(OBJS) -o client

#client: client.o
#	$(CC) $(OBJS) client.o -o client

#client.o: client.c
#	$(CC) -c $(CFLAGS) client.c

clean:
	rm -f *.o
	rm client