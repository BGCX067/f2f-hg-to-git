/*********************************************************************
* Copyright (c) 2003-2006, Impulse Accelerated Technologies, Inc.
* All Rights Reserved.
*
* co_stream.c: Stream functions.
*
* $Id: co_stream.c,v 1.1 2009/02/02 22:51:33 mei.xu Exp $
*
*********************************************************************/

/* note: the io_addr field is used to store the first "register" that's
 *         part of a given stream.
 * this only supports 4 streams right now.
 * there's some bs in the polling loops to deal with xilinx-gcc bugs.
 */

#include "co.h"

#include <malloc.h>
#include <string.h>

#define CLOSE_CASE(base,saddr) \
  case base:\
    do {stvewx(saddr, &status, 0);} while (!(status));\
    lvewx(saddr, &status, 0);\
    break

#define READ_CASE(base,saddr,st,xfersize) \
  case base:\
    do {stvewx(saddr, &status, 0);} while (!(status));\
    __asm__ __volatile__(st " " #base ",%0,%1\n" : : "b" (buffer), "r" (0));\
    if ((status&2)!=0) return(co_err_eos);\
    while (size>xfersize) {\
      buffer = (char *)buffer + xfersize;\
      size-=xfersize;\
      __asm__ __volatile__(st " " #base ",%0,%1\n" : : "b" (buffer), "r" (0));\
    }\
    break

#define WRITE_CASE(base,saddr,ld,xfersize) \
  case base:\
    do {stvewx(saddr, &status, 0);} while (!(status));\
    __asm__ __volatile__(ld " " #base ",%0,%1\n" : : "b" (buffer), "r" (0));\
    while (size>xfersize) {\
      buffer = (char *)buffer + xfersize;\
      size-=xfersize;\
      __asm__ __volatile__(ld " " #base ",%0,%1\n" : : "b" (buffer), "r" (0));\
    }\
    break


co_stream co_stream_create(char * name, co_type datatype, int buffer_depth)
{
  co_stream stream = (co_stream) malloc(sizeof(co_stream_t));
  if ( stream != NULL ) {
    stream->name = strdup(name);
    stream->datatype = datatype;
    stream->buffer_depth = buffer_depth;
    stream->direction = CO_NO_DIRECTION;
    stream->io_addr = 0;
  } else printf("Malloc failed!");
  return(stream);
}

void co_stream_attach(co_stream stream, int io_addr, co_stream_direction dir)
{
  stream->io_addr=io_addr;
  stream->direction=dir;
}

/* this is almost identical to co_stream_write - it just writes to a different place */
int co_stream_close(co_stream stream)
{
  volatile uint32 status;

  if (stream->direction==HW_OUTPUT) return 0;
  /* wait for the ready signal and write something (doesn't matter what) */
  switch (stream->io_addr) {
#ifdef GENERATE_STREAM_CLOSE2
    CLOSE_CASE(0,2);
#endif
#ifdef GENERATE_STREAM_CLOSE6
    CLOSE_CASE(4,6);
#endif
#ifdef GENERATE_STREAM_CLOSE10
    CLOSE_CASE(8,10);
#endif
#ifdef GENERATE_STREAM_CLOSE14
    CLOSE_CASE(12,14);
#endif
#ifdef GENERATE_STREAM_CLOSE18
    CLOSE_CASE(16,18);
#endif
#ifdef GENERATE_STREAM_CLOSE22
    CLOSE_CASE(20,22);
#endif
#ifdef GENERATE_STREAM_CLOSE26
    CLOSE_CASE(24,26);
#endif
#ifdef GENERATE_STREAM_CLOSE30
    CLOSE_CASE(28,30);
#endif
  }
  return(0);
}

int co_stream_read(co_stream stream, void *buffer, int size)
{
  volatile uint32 status;
  switch (stream->io_addr) {
#ifdef GENERATE_STREAM_READ0
    READ_CASE(0,2,GENERATE_STREAM_INSTR0,GENERATE_STREAM_READ0);
#endif
#ifdef GENERATE_STREAM_READ4
    READ_CASE(4,6,GENERATE_STREAM_INSTR4,GENERATE_STREAM_READ4);
#endif
#ifdef GENERATE_STREAM_READ8
    READ_CASE(8,10,GENERATE_STREAM_INSTR8,GENERATE_STREAM_READ8);
#endif
#ifdef GENERATE_STREAM_READ12
    READ_CASE(12,14,GENERATE_STREAM_INSTR12,GENERATE_STREAM_READ12);
#endif
#ifdef GENERATE_STREAM_READ16
    READ_CASE(16,18,GENERATE_STREAM_INSTR16,GENERATE_STREAM_READ16);
#endif
#ifdef GENERATE_STREAM_READ20
    READ_CASE(20,22,GENERATE_STREAM_INSTR20,GENERATE_STREAM_READ20);
#endif
#ifdef GENERATE_STREAM_READ24
    READ_CASE(24,26,GENERATE_STREAM_INSTR24,GENERATE_STREAM_READ24);
#endif
#ifdef GENERATE_STREAM_READ28
    READ_CASE(28,30,GENERATE_STREAM_INSTR28,GENERATE_STREAM_READ28);
#endif
  }
  return 0;
} /* co_stream_read */

int co_stream_write(co_stream stream, const void *buffer, int size)
{
  volatile uint32 status;
  switch (stream->io_addr) {
#ifdef GENERATE_STREAM_WRITE0
    WRITE_CASE(0,2,GENERATE_STREAM_INSTR0,GENERATE_STREAM_WRITE0);
#endif
#ifdef GENERATE_STREAM_WRITE4
    WRITE_CASE(4,6,GENERATE_STREAM_INSTR4,GENERATE_STREAM_WRITE4);
#endif
#ifdef GENERATE_STREAM_WRITE8
    WRITE_CASE(8,10,GENERATE_STREAM_INSTR8,GENERATE_STREAM_WRITE8);
#endif
#ifdef GENERATE_STREAM_WRITE12
    WRITE_CASE(12,14,GENERATE_STREAM_INSTR12,GENERATE_STREAM_WRITE12);
#endif
#ifdef GENERATE_STREAM_WRITE16
    WRITE_CASE(16,18,GENERATE_STREAM_INSTR16,GENERATE_STREAM_WRITE16);
#endif
#ifdef GENERATE_STREAM_WRITE20
    WRITE_CASE(20,22,GENERATE_STREAM_INSTR20,GENERATE_STREAM_WRITE20);
#endif
#ifdef GENERATE_STREAM_WRITE24
    WRITE_CASE(24,26,GENERATE_STREAM_INSTR24,GENERATE_STREAM_WRITE24);
#endif
#ifdef GENERATE_STREAM_WRITE28
    WRITE_CASE(28,30,GENERATE_STREAM_INSTR28,GENERATE_STREAM_WRITE28);
#endif
  }
  return 0;
} /* co_stream_write */
