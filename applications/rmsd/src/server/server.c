/*
server.c:
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


#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <errno.h>
#include <netinet/in.h>
#include <unistd.h>
#include <stdlib.h>


/**** OWN HEADERS ****************************/
#include "arithmetic.h"
#include "communication.h"
#include "types.h"
#include "endianTool.h"
#include "socketTool.h"
#include "rmsdCalc.h"
/*********************************************/


static void process_packet(BufferClient* inpacket, BufferServer* outpacket)
{
    const size_t sizeOfStructures = inpacket->numberOfCoords * 3 * sizeof(FloatType);

    char* pointer_first_element = inpacket->data;
    char* pointer_last_element = inpacket->data + sizeOfStructures * (inpacket->numberOfStructs - 1);
    FloatType* pointer_results = (FloatType*)outpacket->data;

    size_t numberOfResults = 0;

    char* it1;
    for (it1 = pointer_first_element; it1 < pointer_last_element; it1 += sizeOfStructures)
    {
        char* it2;
        for (it2 = it1 + sizeOfStructures; it2 <= pointer_last_element; it2 += sizeOfStructures)
        {
            *pointer_results = rmsd_to((Coord3d*)it1, (Coord3d*)it2, inpacket->numberOfCoords);
            ++pointer_results;
            ++numberOfResults;
        }
    }

    outpacket->numberOfResults = numberOfResults;
}


int main(void)
{
    const int sock = socket(AF_INET, SOCK_STREAM, IPPROTO_IP);
    if (sock == -1)
    {
        printf ("Error creating socket\n");
        exit(EXIT_FAILURE);
    }

    struct sockaddr_in sa;
    sa.sin_family = AF_INET;
    sa.sin_addr.s_addr = INADDR_ANY;
    sa.sin_port = htons(PORT);
    socklen_t address_len = sizeof(sa);

    const int b = bind(sock, (struct sockaddr*)&sa, sizeof(sa));
    if (b == -1)
    {
        printf("Error bind failed\n");
        close(sock);
        exit(EXIT_FAILURE);
    }

    /* PREPARE FOR INCOMING CONNECTION */
    const int list = listen(sock, 1);
    if (list == -1)
    {
        printf("Error list failed\n");
        close(sock);
        exit(EXIT_FAILURE);
    }
    /***********************************/

    BufferClient buffer_in;
    BufferServer buffer_out;

    while (1)
    {
    	/* WAIT FOR CONNECT CLIENT */
        printf ("Waiting for client...\n");
        const int sock_client = accept(sock, (struct sockaddr*)&sa, &address_len);
        if (sock_client == -1)
        {
            printf("Error accepting client\n");
        }
        /***************************/

        /* WAIT TO RECEIVE A PACKET */
        const int read = read_socket(sock_client, (char*)&buffer_in, LENGHT_BUFFER);
        if (read == -1)
        {
            printf("Error receiving packet\n");
        }
        /****************************/

        /* CONVERT */
        endian_buffer_client(&buffer_in, networkToHost);
        /***********/

        /* PROCESS THE PACKET */
        process_packet(&buffer_in, &buffer_out);
        /**********************/

        /* CONVERT */
        endian_buffer_server(&buffer_out, hostToNetwork);
        /***********/

        /* SEND RESULTS */
        const int write = write_socket(sock_client, (char*)&buffer_out, LENGHT_BUFFER);
        if (write == -1)
        {
            printf("Error sending packet\n");
        }
        /****************/

        /* END OF COMMUNICATION */
        const int shutdn = shutdown(sock_client, SHUT_RDWR);
        if (shutdn == -1)
        {
            printf("Error shutting down\n");
        }
        /****************/
    }

    return EXIT_SUCCESS;
}
