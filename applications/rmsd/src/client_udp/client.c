/*
client.c:
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
#include <netinet/in.h>
#include <unistd.h>
#include <stdlib.h>
#include <arpa/inet.h>


/**** OWN HEADERS ****************************/
#include "arithmetic.h"
#include "communication.h"
#include "types.h"
/*********************************************/

int validate_lenght_data(const size_t* numberOfCoords, const size_t* numberOfStructs)
{
    int isValid = 1;

    const size_t sizeOfStructures = (*numberOfCoords) * 3 * sizeof(FloatType);
    const size_t dataLenghtRequired = sizeOfStructures * (*numberOfStructs);

    /* VALIDATING MAX LENGHT DATA */
    if (dataLenghtRequired > sizeof(((BufferClient*)0)->data))
        isValid = 0;

    return isValid;
}

void load_process(BufferClient* buffer_out, const size_t* numberOfCoords, const size_t* numberOfStructs)
{
    const size_t sizeOfStructures = (*numberOfCoords) * 3 * sizeof(FloatType);

    buffer_out->numberOfCoords = *numberOfCoords;
    buffer_out->numberOfStructs = *numberOfStructs;

    Coord3d* first = (Coord3d*)buffer_out->data;
    first[0].x = float_to_current(-0.296000f);
    first[0].y = float_to_current(-0.697000f);
    first[0].z = float_to_current(-0.359000f);
    first[1].x = float_to_current(-0.299000f);
    first[1].y = float_to_current(-0.613000f);
    first[1].z = float_to_current(-0.240000f);
    first[2].x = float_to_current(-0.169000f);
    first[2].y = float_to_current(-0.534000f);
    first[2].z = float_to_current(-0.230000f);
    first[3].x = float_to_current(-0.182000f);
    first[3].y = float_to_current(-0.404000f);
    first[3].z = float_to_current(-0.208000f);
    first[4].x = float_to_current(-0.068000f);
    first[4].y = float_to_current(-0.314000f);
    first[4].z = float_to_current(-0.204000f);
    first[5].x = float_to_current(-0.095000f);
    first[5].y = float_to_current(-0.193000f);
    first[5].z = float_to_current(-0.117000f);
    first[6].x = float_to_current(0.011000f);
    first[6].y = float_to_current(-0.122000f);
    first[6].z = float_to_current(-0.079000f);
    first[7].x = float_to_current(0.000000f);
    first[7].y = float_to_current(0.000000f);
    first[7].z = float_to_current(0.000000f);
    first[8].x = float_to_current(0.102000f);
    first[8].y = float_to_current(0.101000f);
    first[8].z = float_to_current(-0.052000f);
    first[9].x = float_to_current(0.074000f);
    first[9].y = float_to_current(0.229000f);
    first[9].z = float_to_current(-0.028000f);
    first[10].x = float_to_current(0.165000f);
    first[10].y = float_to_current(0.335000f);
    first[10].z = float_to_current(-0.071000f);
    first[11].x = float_to_current(0.204000f);
    first[11].y = float_to_current(0.422000f);
    first[11].z = float_to_current(0.048000f);
    first[12].x = float_to_current(0.329000f);
    first[12].y = float_to_current(0.465000f);
    first[12].z = float_to_current(0.051000f);
    first[13].x = float_to_current(0.377000f);
    first[13].y = float_to_current(0.551000f);
    first[13].z = float_to_current(0.159000f);
    first[14].x = float_to_current(0.515000f);
    first[14].y = float_to_current(0.603000f);
    first[14].z = float_to_current(0.122000f);
    Coord3d* second = (Coord3d*)(buffer_out->data + sizeOfStructures);
    second[0].x = float_to_current(0.187000f);
    second[0].y = float_to_current(-0.528000f);
    second[0].z = float_to_current(-0.120000f);
    second[1].x = float_to_current(0.052000f);
    second[1].y = float_to_current(-0.561000f);
    second[1].z = float_to_current(-0.073000f);
    second[2].x = float_to_current(-0.044000f);
    second[2].y = float_to_current(-0.443000f);
    second[2].z = float_to_current(-0.083000f);
    second[3].x = float_to_current(-0.053000f);
    second[3].y = float_to_current(-0.379000f);
    second[3].z = float_to_current(-0.199000f);
    second[4].x = float_to_current(-0.146000f);
    second[4].y = float_to_current(-0.272000f);
    second[4].z = float_to_current(-0.226000f);
    second[5].x = float_to_current(-0.138000f);
    second[5].y = float_to_current(-0.152000f);
    second[5].z = float_to_current(-0.133000f);
    second[6].x = float_to_current(-0.019000f);
    second[6].y = float_to_current(-0.117000f);
    second[6].z = float_to_current(-0.085000f);
    second[7].x = float_to_current(0.000000f);
    second[7].y = float_to_current(0.000000f);
    second[7].z = float_to_current(0.000000f);
    second[8].x = float_to_current(0.135000f);
    second[8].y = float_to_current(0.064000f);
    second[8].z = float_to_current(-0.032000f);
    second[9].x = float_to_current(0.144000f);
    second[9].y = float_to_current(0.194000f);
    second[9].z = float_to_current(-0.007000f);
    second[10].x = float_to_current(0.267000f);
    second[10].y = float_to_current(0.268000f);
    second[10].z = float_to_current(-0.030000f);
    second[11].x = float_to_current(0.325000f);
    second[11].y = float_to_current(0.306000f);
    second[11].z = float_to_current(0.107000f);
    second[12].x = float_to_current(0.456000f);
    second[12].y = float_to_current(0.296000f);
    second[12].z = float_to_current(0.121000f);
    second[13].x = float_to_current(0.518000f);
    second[13].y = float_to_current(0.332000f);
    second[13].z = float_to_current(0.249000f);
    second[14].x = float_to_current(0.638000f);
    second[14].y = float_to_current(0.423000f);
    second[14].z = float_to_current(0.223000f);
}

int main(void)
{
    const int sock = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (sock < 0)
    {
        printf("Error Creating Socket");
        exit(EXIT_FAILURE);
    }

    struct sockaddr_in sa;
    sa.sin_family = AF_INET;
    sa.sin_addr.s_addr = inet_addr(SERVER_IP);
    sa.sin_port = htons(PORT);

    BufferServer buffer_in;
    BufferClient buffer_out;

    /* VALIDATING LENGHT DATA */
    const size_t numberOfCoords = 15; //for this example
    const size_t numberOfStructs = 2; //for this example
    const int isValid = validate_lenght_data(&numberOfCoords, &numberOfStructs);
    if (isValid == 0)
    {
        printf("Error lenght data\n");
        exit(EXIT_FAILURE);
    }
    /***************/

    /* LOADING DATA */
    load_process(&buffer_out, &numberOfCoords, &numberOfStructs);
    /****************/

    /* SEND A PACKET */
    const ssize_t bytes_sent = sendto(sock, &buffer_out, LENGHT_BUFFER, 0, (struct sockaddr*)&sa, sizeof(struct sockaddr_in));
    if (bytes_sent < 0)
    {
        printf("Error sending packet\n");
    }
    /*****************/

    /* WAIT TO RECEIVE */
    socklen_t fromlen = sizeof(sa);
    const ssize_t bytes_rec = recvfrom(sock, &buffer_in, LENGHT_BUFFER, 0, (struct sockaddr*)&sa, &fromlen);
    if (bytes_rec < 0)
    {
        printf("Error receiving packet\n");
    }
    /*******************/

    /* SHOW RESULTS */
    size_t numberOfResults = buffer_in.numberOfResults;
    FloatType* pointer_results = (FloatType*)buffer_in.data;
    while (numberOfResults > 0)
    {
        const float result = current_to_float(*pointer_results);
        printf("RMSD: %.10f\n", result);
        --numberOfResults;
        ++pointer_results;
    }
    /****************/

    close(sock);

    return EXIT_SUCCESS;
}
