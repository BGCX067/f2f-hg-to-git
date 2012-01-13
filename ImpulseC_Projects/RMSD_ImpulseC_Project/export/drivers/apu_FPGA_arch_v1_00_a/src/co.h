/*********************************************************************
* Copyright (c) 2003-2006, Impulse Accelerated Technologies, Inc.
* All Rights Reserved.
*
* co.h: Impulse C interface for the Xilinx PowerPC/APU platform.
*
*********************************************************************/

#ifndef CO_H
#define CO_H

#define IMPULSE_C_TARGET POWERPC
#define IMPULSE_C_BUS APU
#define REGISTER_WIDTH 32

#include "co_if_sim.h"
#include "co_types.h"

#include "apu_if.h"

extern co_process co_process_create(char * name, co_function run, int argc, ...);
extern void co_execute(co_architecture arch);
#define cosim_architecture_config(arch, attribute, value)

extern co_type co_type_create(co_sort sort, unsigned int width);

#define LINUX
#define INT_TYPE(width)		co_type_create(co_int_sort,width)
#define UINT_TYPE(width) 	co_type_create(co_uint_sort,width)
#define CHAR_TYPE			co_type_create(co_int_sort,8)
#define FLOAT_TYPE			co_type_create(co_float_sort,32)
#define DOUBLE_TYPE			co_type_create(co_float_sort,64)

#define co_bit_extract(value, start_bit, num_bits) (int32)(((value) >> (start_bit)) & (~(0xffffffffU << (num_bits))))
#define co_bit_extract_u(value, start_bit, num_bits) (uint32)((start_bit) >= 32 ? 0 : ((value) >> (start_bit)) & (~(0xffffffffU << (num_bits))))
#define co_bit_insert(destination, dest_start_bit, num_bits, source) \
	(int32)( \
	    ( (destination) & ( 0xffffffffU << ( (dest_start_bit) + (num_bits) ) ) ) | \
        ( ( (source) << (dest_start_bit) ) & ~( ( 0xffffffffU << ( (dest_start_bit) + (num_bits) ) ) | ~( 0xffffffffU << (dest_start_bit) ) ) ) | \
        ( (destination) & ~( 0xffffffffU << (dest_start_bit) ) ) \
	)
#define co_bit_insert_u(destination, dest_start_bit, num_bits, source) (uint32)co_bit_insert((int32)(destination), (dest_start_bit), (num_bits), (int32)(source))

// important offsets from the base of a stream
#define STREAM_STATUS_OFFSET 8 // read status info from here for both types of stream
#define STREAM_EOS_OFFSET    8 // write anything here to close a HW_INPUT stream
// layout of the status word.
#define STATUS_RDY 1	// ready
#define STATUS_EOS 2	// end-of-stream
#define STATUS_ERR 8    // error.
extern co_stream co_stream_create(char * name, co_type datatype, int bufferdepth);
extern void co_stream_attach(co_stream stream, int io_addr, co_stream_direction dir);
extern int co_stream_free(co_stream stream);
extern int co_stream_close(co_stream stream);
extern int co_stream_read(co_stream stream, void *buffer, int buffersize);
extern int co_stream_read_nb(co_stream stream, void *buffer, int buffersize);
extern int co_stream_write(co_stream stream, const void *buffer, int buffersize);
extern int co_stream_write_nb(co_stream stream, const void *buffer, int buffersize);

#define co_stream_open(stream,mode,type)
#define co_stream_eos(stream) ((XIo_In32((stream)->io_addr+8)&2)!=0)

/* apu stream access macros */
#define GET_STATUS(proc,stream,var) \
__asm__ __volatile__("nop\n");\
__asm__ __volatile__("nop\n");\
  __asm__ __volatile__(\
    "stvewx " p_ ## proc ## _ ## stream ## _status() ",%0,%1\n"\
    : : "b" (&var), "r" (0))

#define PUT_STATUS(proc,stream,var) \
  __asm__ __volatile__(\
    "lvewx " p_ ## proc ## _ ## stream ## _status() ",%0,%1\n"\
    : : "b" (&var), "r" (0))

#define GET_DATA(proc,stream,var) \
__asm__ __volatile__("nop\n");\
__asm__ __volatile__("nop\n");\
  __asm__ __volatile__(\
    "stvewx " p_ ## proc ## _ ## stream ## _data() ",%0,%1\n"\
    : : "b" (&var), "r" (0))

#define PUT_DATA(proc,stream,var) \
  __asm__ __volatile__(\
    "lvewx " p_ ## proc ## _ ## stream ## _data() ",%0,%1\n"\
    : : "b" (&var), "r" (0))

#define GET_WORD(proc,stream,varp) \
__asm__ __volatile__("nop\n");\
__asm__ __volatile__("nop\n");\
  __asm__ __volatile__(\
    "stvewx " p_ ## proc ## _ ## stream ## _data() ",%0,%1\n"\
    : : "b" (varp), "r" (0))

#define PUT_WORD(proc,stream,varp) \
  __asm__ __volatile__(\
    "lvewx " p_ ## proc ## _ ## stream ## _data() ",%0,%1\n"\
    : : "b" (varp), "r" (0))

#define GET_DWORD(proc,stream,varp) \
__asm__ __volatile__("nop\n");\
__asm__ __volatile__("nop\n");\
  __asm__ __volatile__(\
    "stvewx " p_ ## proc ## _ ## stream ## _data() ",%0,%1\n"\
    : : "b" (varp), "r" (0))

#define PUT_DWORD(proc,stream,varp) \
  __asm__ __volatile__(\
    "lvewx " p_ ## proc ## _ ## stream ## _data() ",%0,%1\n"\
    : : "b" (varp), "r" (0))

#define GET_QWORD(proc,stream,varp) \
__asm__ __volatile__("nop\n");\
__asm__ __volatile__("nop\n");\
  __asm__ __volatile__(\
    "stvewx " p_ ## proc ## _ ## stream ## _data() ",%0,%1\n"\
    : : "b" (varp), "r" (0))

#define PUT_QWORD(proc,stream,varp) \
  __asm__ __volatile__(\
    "lvewx " p_ ## proc ## _ ## stream ## _data() ",%0,%1\n"\
    : : "b" (varp), "r" (0))

#define HW_STREAM_OPEN(proc,stream,mode,type)

#define HW_STREAM_READ(proc,stream,var,evar) HW_STREAM_READ_4(proc,stream,&(var),evar)
#define HW_STREAM_READ_4(proc,stream,varp,evar) \
  { volatile unsigned int s;\
    do { GET_STATUS(proc,stream,s); } while (!s);\
    GET_WORD(proc,stream,varp);\
    evar=(s&STATUS_EOS)!=0;\
  }

#define HW_STREAM_READ_NB(proc,stream,var,evar) \
  { volatile unsigned int s;\
    GET_STATUS(proc,stream,s);\
    if ((s&STATUS_EOS)==0 && (s&STATUS_RDY)) {GET_DATA(proc,stream,var);}\
    evar=(s&STATUS_EOS)!=0 || (s&STATUS_RDY)==0;\
  }

#define HW_STREAM_READ_8(proc,stream,varp,evar) \
  { volatile unsigned int s;\
    do { GET_STATUS(proc,stream,s); } while (!s);\
    GET_DWORD(proc,stream,varp);\
    evar=(s&STATUS_EOS)!=0;\
  }

#define HW_STREAM_READ_16(proc,stream,varp,evar) \
  { volatile unsigned int s;\
    do { GET_STATUS(proc,stream,s); } while (!s);\
    GET_QWORD(proc,stream,varp);\
    evar=(s&STATUS_EOS)!=0;\
  }

#define HW_STREAM_WRITE(proc,stream,var) HW_STREAM_WRITE_4(proc,stream,&(var))
#define HW_STREAM_WRITE_4(proc,stream,varp) \
  { volatile unsigned int s;\
    do { GET_STATUS(proc,stream,s); } while (!s);\
    PUT_WORD(proc,stream,varp);\
  }

#define HW_STREAM_WRITE_8(proc,stream,varp) \
  { volatile unsigned int s;\
    do { GET_STATUS(proc,stream,s); } while (!s);\
    PUT_DWORD(proc,stream,varp);\
  }

#define HW_STREAM_WRITE_16(proc,stream,varp) \
  { volatile unsigned int s;\
    do { GET_STATUS(proc,stream,s); } while (!s);\
    PUT_QWORD(proc,stream,varp);\
  }

#define HW_STREAM_CLOSE(proc,stream) \
  if (stream->direction==HW_INPUT) {\
     volatile unsigned int s;\
    do { GET_STATUS(proc,stream,s); } while (!s);\
    PUT_STATUS(proc,stream,s);\
  }


#if 0 // not yet supported over apu
extern co_signal co_signal_create(char * name);
extern void co_signal_attach(co_signal signal, int io_addr, co_stream_direction dir);
extern co_error co_signal_post(co_signal signal, int32 value);
extern co_error co_signal_wait(co_signal signal, int32 *vp);

extern co_register co_register_create(const char * name, co_type type);
extern void co_register_attach(co_register reg, int io_addr, co_stream_direction dir);
extern int32 co_register_get(co_register reg);
extern void co_register_put(co_register reg, int32 value);
extern co_error co_register_read(co_register reg, void *buffer, unsigned int size);
extern co_error co_register_write(co_register reg, const void *buffer, unsigned int size);

extern co_memory co_memory_create(char *name, char *loc, unsigned int size, void *(*alloc)());
extern co_error co_memory_writeblock(co_memory mem, unsigned int offset, void *buf, unsigned int buffersize);
extern co_error co_memory_readblock(co_memory mem, unsigned int offset, void *buf, unsigned int buffersize);
extern void *co_memory_ptr(co_memory mem);
#endif // 0

#ifndef IMPULSE_C_SYNTHESIS
#define co_par_break()
#endif

#include "co_math.h"

/* assembly mnemonics for apu instructions */
#ifndef lvewx
#define lvewx(rn, base, adr)    __asm__ __volatile__(\
                           "lvewx " #rn ",%0,%1\n"\
                           : : "b" (base), "r" (adr)\
                         )

#define stvewx(rn, base, adr)    __asm__ __volatile__(\
                                   "stvewx " #rn ",%0,%1\n"\
                                   : : "b" (base), "r" (adr)\
                                 )
#endif // lvewx

#endif  /* CO_H */

