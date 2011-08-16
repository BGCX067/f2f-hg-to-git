/*
communication.h: Molecular Biology ++ Header file.
    Copyright (C) 2011 Martin Ramiro Gioiosa, FuDePAN

    This file is part of Biopp.

    Biopp is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Biopp is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Biopp.  If not, see <http://www.gnu.org/licenses/>.

    NOTE: This file is in prototype stage, and is under active development.
*/

#ifndef COMMUNICATION_H_
#define COMMUNICATION_H_


#define SERVER_IP             "127.0.0.1"
#define PORT                  7654

#define LENGHT_BUFFER         1490

typedef struct
{
    size_t numberOfCoords;
    size_t numberOfStructs;
    char data[LENGHT_BUFFER - 2 * sizeof(size_t)];
} BufferClient;

typedef struct
{
    size_t numberOfResults;
    char data[LENGHT_BUFFER - sizeof(size_t)];
} BufferServer;


#endif /* COMMUNICATION_H_ */
