/*
endianTool.h:
    Copyright (C) 2011 Martin Ramiro Gioiosa, FuDePAN

    This file is part of the F2F project.

    F2F is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    F2F is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with F2F.  If not, see <http://www.gnu.org/licenses/>.

    NOTE: This file is in prototype stage, and is under active development.
*/


#ifndef ENDIAN_TOOL_H_
#define ENDIAN_TOOL_H_


#include "arithmetic.h"
#include "communication.h"
#include <stdint.h>


enum mode_conv
{
    hostToNetwork,
    networkToHost,
};


void endian_buffer_client(BufferClient* buffer, const enum mode_conv mode);
void endian_buffer_server(BufferServer* buffer, const enum mode_conv mode);


#ifdef USE_FLOATS
#define convert_data()\
    do\
    {\
        const FloatType* end = data + lenght / sizeof(FloatType);\
        \
        while (data < end)\
        {\
            convert(data, mode);\
            ++data;\
        }\
    }\
    while (0)
#elif defined(USE_FIXED_POINT)
#define convert_data()\
    do\
    {\
        const FloatType* end = data + lenght / sizeof(FloatType);\
        \
        while (data < end)\
        {\
            uint32_t* data_low = (uint32_t*)data;\
            uint32_t* data_high = (uint32_t*)data + 1;\
        \
            uint32_t low_32 = *data_low;\
            uint32_t high_32 = *data_high;\
        \
            convert(&low_32, mode);\
            convert(&high_32, mode);\
        \
            *data_low = high_32;\
            *data_high = low_32;\
        \
            ++data;\
        }\
    }\
    while (0)
#endif


#endif /* ENDIAN_TOOL_H_ */
