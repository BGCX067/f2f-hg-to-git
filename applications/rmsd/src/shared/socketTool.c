/*
socketTool.c:
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


#include "socketTool.h"


int read_socket(const int sock, char* data, const int lenght)
{
    int ret = -1;

    if (data != NULL && lenght > 0)
    {
        int acum = 0;
        int result;

        do
        {
            result = read(sock, data + acum, lenght - acum);
            if (result > 0)
            {
                acum += result;
            }
        }
        while (result > 0);

        if (result == 0)
        {
            ret = acum;
        }
    }

    return ret;
}


int write_socket(const int sock, const char* data, const int lenght)
{
    int ret = -1;

    if (data != NULL && lenght > 0)
    {
        int acum = 0;
        int result;

        do
        {
            result = write(sock, data + acum, lenght - acum);
            if (result > 0)
            {
                acum += result;
            }
        }
        while (result > 0);

        if (result == 0)
        {
            ret = acum;
        }
    }

    return ret;
}
