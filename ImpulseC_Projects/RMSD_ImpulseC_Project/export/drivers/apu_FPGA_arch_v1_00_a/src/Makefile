LIBNAME = libImpulseC.a
OBJS = co_stream.o co_process.o co_type.o
CC = ppc_4xx-gcc --static -maltivec -I/home/meixu/Xilinx/linux-2.6-xlnx/arch/powerpc/include/asm

all: $(OBJS) $(LIBNAME)
	
$(LIBNAME): $(OBJS) Makefile
	ar rcs $(LIBNAME) $(OBJS)
	rm *.o
	
clean:
	rm $(LIBNAME) *.o
