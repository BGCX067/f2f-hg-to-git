GCC=ppc_4xx-gcc
LIB_DIR=libImpulse
INC_DIR=libImpulse
CFLAGS=-DLINUX --static -maltivec
LIB=libImpulseC.a

FPGA_arch:	FPGA_sw.c co_init.c $(LIB_DIR)/libimpulsec.a Makefile
	$(GCC) FPGA_sw.c co_init.c $(CFLAGS) -I$(INC_DIR) -L$(LIB_DIR) -lImpulseC -o FPGA_arch

clean:
	rm -rf *.o FPGA_arch
