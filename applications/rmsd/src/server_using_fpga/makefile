CC=gcc
CFLAGS=-Wall -pedantic -ansi -Wextra -ggdb3 -std=c99
CFLAGS+=--static -maltivec
OBJS=../shared/arithmetic.o ../shared/socketTool.o ../shared/endianTool.o
LIB_DIR=libImpulse
INC_DIR=-I../../include -IlibImpulse
CFLAGS=-DLINUX --static -maltivec
LIB=libImpulseC.a

todo: server

server:
	$(CC) $(CFLAGS) FPGA_sw.c co_init.c rmsdCalc.c server.c $(OBJS) $(INC_DIR) -lm -L$(LIB_DIR) -lImpulseC -o server

#server: server.o
#	$(CC) $(OBJS) server.o -lm -o server

#server.o: server.c
#	$(CC) -c $(CFLAGS) server.c

clean:
	rm -f *.o
	rm server
