/*
communication.h:
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


#ifndef COMMUNICATION_H_
#define COMMUNICATION_H_


#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <arpa/inet.h>



/**** COMMUNICATION **************************/
#define SERVER_IP             "127.0.0.1"
//#define SERVER_IP               "192.168.0.91"

#define PORT                  7654
/*********************************************/


/**** BUFFERS ********************************/
#define LENGHT_BUFFER         1496
// Lenght of buffer must be fixed here

#define LENGHT_DATA_CLIENT    LENGHT_BUFFER - 2 * sizeof(uint32_t)
#define LENGHT_DATA_SERVER    LENGHT_BUFFER - sizeof(uint32_t)

typedef struct
{
    uint32_t numberOfCoords;
    uint32_t numberOfStructs;
    char data[LENGHT_DATA_CLIENT];
} BufferClient;

typedef struct
{
    uint32_t numberOfResults;
    char data[LENGHT_DATA_SERVER];
} BufferServer;
/*********************************************/


#endif /* COMMUNICATION_H_ */
