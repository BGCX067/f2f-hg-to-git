/*
endianTool.c:
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


#include "endianTool.h"


static void convert(void* num, const enum mode_conv mode)
{
    uint32_t* p = num;

    if (mode == hostToNetwork)
    {
        *p = htonl(*p);
    }
    else //networkToHost
    {
        *p = ntohl(*p);
    }
}


static void convert_data(FloatType* data, const uint32_t lenght, const enum mode_conv mode)
{
    CONVERT_DATA(data, lenght);
}


void endian_buffer_client(BufferClient* buffer, const enum mode_conv mode)
{
    uint32_t test_needed = 1;
    convert(&test_needed, mode);

    if (test_needed != 1)
    {
        convert(&(buffer->numberOfCoords), mode);
        convert(&(buffer->numberOfStructs), mode);
        convert_data((FloatType*)buffer->data, LENGHT_DATA_CLIENT, mode);
    }
}


void endian_buffer_server(BufferServer* buffer, const enum mode_conv mode)
{
    uint32_t test_needed = 1;
    convert(&test_needed, mode);

    if (test_needed != 1)
    {
        convert(&(buffer->numberOfResults), mode);
        convert_data((FloatType*)buffer->data, LENGHT_DATA_SERVER, mode);
    }
}
