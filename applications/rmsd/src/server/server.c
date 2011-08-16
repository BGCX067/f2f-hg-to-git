/*
server.c: Molecular Biology ++ Implementation file.
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


#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <stdlib.h>


/**** OWN HEADERS ****************************/
#include "arithmetic.h"
#include "communication.h"
#include "types.h"
/*********************************************/


/**** TYPEDEFS *******************************/
typedef FloatType       rvec[DIM];
typedef DoubleType      dvec[DIM];
typedef FloatType       matrix[DIM][DIM];
/*********************************************/


/**** AUXILIAR METHODS ***********************/
void rotate(DoubleType a[][6], size_t i, size_t j, size_t k, size_t l, DoubleType tau, DoubleType s)
{
    const DoubleType g = a[i][j];
    const DoubleType h = a[k][l];

    a[i][j] = sub(g, multiply(s, (add(h, multiply(g, tau)))));
    a[k][l] = add(h, multiply(s, (sub(g, multiply(h, tau)))));
}

void clear_mat(matrix a)
{
    a[0][0] = a[0][1] = a[0][2] = constant_f_0_0;
    a[1][0] = a[1][1] = a[1][2] = constant_f_0_0;
    a[2][0] = a[2][1] = a[2][2] = constant_f_0_0;
}

void oprod(const rvec a, const rvec b, rvec c)
{
    c[0] = sub(multiply(a[1], b[2]), multiply(a[2], b[1]));
    c[1] = sub(multiply(a[2], b[0]), multiply(a[0], b[2]));
    c[2] = sub(multiply(a[0], b[1]), multiply(a[1], b[0]));
}

void Coord3D2rvec(const Coord3d* coord3d, rvec rv)
{
    rv[0] = coord3d->x;
    rv[1] = coord3d->y;
    rv[2] = coord3d->z;
}

void rvec2Coord3D(const rvec rv, Coord3d* coord3d)
{
    coord3d->x = rv[0];
    coord3d->y = rv[1];
    coord3d->z = rv[2];
}

void structure2rvec_arr(const Coord3d* coord3d, const size_t num_elements, rvec* ret)
{
    size_t i;
    for (i = 0; i < num_elements; ++i)
        Coord3D2rvec(&coord3d[i], ret[i]);
}
/*********************************************/



/**** MAIN METHODS ***************************/
void jacobi(DoubleType a[][JACOBI_DIM], DoubleType d[], DoubleType v[][JACOBI_DIM])
{
    DoubleType b [JACOBI_DIM];
    DoubleType z [JACOBI_DIM];

    size_t ip;
    for (ip = 0; ip < JACOBI_DIM; ++ip)
    {
        size_t iq;
        for (iq = 0; iq < JACOBI_DIM; ++iq)
            v[ip][iq] = constant_d_0_0;

        v[ip][ip] = constant_d_1_0;
    }

    for (ip = 0; ip < JACOBI_DIM; ++ip)
    {
        b[ip] = d[ip] = a[ip][ip];
        z[ip] = constant_d_0_0;
    }

    size_t i;
    for (i = 1; i <= NUMBER_ITERATIONS; ++i)
    {
        DoubleType sm = constant_d_0_0;

        size_t ip;
        for (ip = 0; ip < JACOBI_DIM - 1; ++ip)
        {
            size_t iq;
            for (iq = ip + 1; iq < JACOBI_DIM; ++iq)
                assign_add(sm, abs(a[ip][iq]));
        }

        if (sm == constant_d_0_0)
            return;

        DoubleType tresh;

        if (i < 4)
            tresh = divide(multiply(constant_d_0_2, sm), square(constant_jacobi_dim));
        else
            tresh = constant_d_0_0;

        for (ip = 0; ip < JACOBI_DIM - 1; ++ip)
        {
            size_t iq;
            for (iq = ip + 1; iq < JACOBI_DIM; ++iq)
            {
                const DoubleType g = multiply(constant_d_100_0, abs(a[ip][iq]));

                const DoubleType abs_d_ip = abs(d[ip]);
                const DoubleType abs_d_iq = abs(d[iq]);

                if (i > 4 && add(abs_d_ip, g) == abs_d_ip && add(abs_d_iq, g) == abs_d_iq)
                    a[ip][iq] = constant_d_0_0;
                else if (abs(a[ip][iq]) > tresh)
                {
                    DoubleType h = sub(d[iq], d[ip]);

                    DoubleType t;
                    const DoubleType abs_h = abs(h);

                    if (add(abs_h, g) == abs_h)
                        t = divide(a[ip][iq], h);
                    else
                    {
                        const DoubleType theta = divide(multiply(constant_d_0_5, h), a[ip][iq]);

                        t = divide(constant_d_1_0, add(abs(theta), square_root(add(constant_d_1_0, square(theta)))));

                        if (theta < constant_d_0_0)
                            t = -t;
                    }

                    const DoubleType c = divide(constant_d_1_0, square_root(add(constant_d_1_0, square(t))));
                    const DoubleType s = multiply(t, c);
                    const DoubleType tau = divide(s, add(constant_d_1_0, c));

                    h = multiply(t, a[ip][iq]);

                    assign_sub(z[ip], h);
                    assign_add(z[iq], h);
                    assign_sub(d[ip], h);
                    assign_add(d[iq], h);

                    a[ip][iq] = constant_d_0_0;

                    size_t j;
                    for (j = 0; j < ip; ++j)
                        rotate(a, j, ip, j, iq, tau, s);

                    for (j = ip + 1; j < iq; ++j)
                        rotate(a, ip, j, j, iq, tau, s);

                    for (j = iq + 1; j < JACOBI_DIM; ++j)
                        rotate(a, ip, j, iq, j, tau, s);

                    for (j = 0; j < JACOBI_DIM; ++j)
                        rotate(v, j, ip, j, iq, tau, s);
                }
            }
        }

        for (ip = 0; ip < JACOBI_DIM; ++ip)
        {
            assign_add(b[ip], z[ip]);
            d[ip] =  b[ip];
            z[ip] =  constant_d_0_0;
        }
    }
}

void calc_fit_R(const size_t num_coords, FloatType *w_rls, rvec *xp, rvec *x, matrix R)
{
    const size_t DIM_DOUBLE = 2 * DIM;

    DoubleType d[2 * DIM];
    matrix vh, vk, u;

    DoubleType omega[2 * DIM][2 * DIM];
    DoubleType om[2 * DIM][2 * DIM];

    size_t i;
    for (i = 0; i < DIM_DOUBLE; ++i)
    {
        d[i] = constant_d_0_0;

        size_t j;
        for (j = 0; j < DIM_DOUBLE; ++j)
        {
            omega[i][j] = constant_d_0_0;
            om[i][j] = constant_d_0_0;
        }
    }

    /* Calculate the matrix U */
    clear_mat(u);

    size_t n;
    for (n = 0; n < num_coords; ++n)
    {
        const FloatType mn = w_rls[n];

        if (mn != constant_f_0_0)
        {
            size_t c;
            for (c = 0; c < DIM; ++c)
            {
                size_t r;
                for (r = 0; r < DIM; ++r)
                    assign_add(u[c][r], multiply3(mn, x[n][r], xp[n][c]));
            }
        }
    }

    /* Construct omega */
    size_t r;
    for (r = 0; r < DIM_DOUBLE; ++r)
    {
        size_t c;
        for (c = 0; c <= r; ++c)
        {
            if (r >= DIM && c < DIM)
            {
                omega[r][c] = u[r - DIM][c];
                omega[c][r] = u[r - DIM][c];
            }
            else
            {
                omega[r][c] = constant_d_0_0;
                omega[c][r] = constant_d_0_0;
            }
        }
    }

    /* Determine h and k */
    jacobi(omega, d, om);

    /* Copy only the first two eigenvectors */
    size_t index;
    size_t j;
    for (j = 0; j < 2; ++j)
    {
        index = 0;

        size_t i;
        for (i = 1; i < DIM_DOUBLE; ++i)
            if ( d[index] < d[i] )
                index = i;

        d[index] = constant_d_n10000_0;

        for (i = 0; i < DIM; ++i)
        {
            vh[j][i] = multiply(constant_sqrt2, om[i][index]);
            vk[j][i] = multiply(constant_sqrt2, om[i + DIM][index]);
        }
    }

    /* Calculate the last eigenvector as the outer-product of the first two. */
    oprod(vh[0], vh[1], vh[2]);
    oprod(vk[0], vk[1], vk[2]);

    /* Determine R */
    for (r = 0; r < DIM; ++r)
    {
        size_t c;
        for (c = 0; c < DIM; ++c)
            R[r][c] = add3(multiply(vk[0][r], vh[0][c]),
                           multiply(vk[1][r], vh[1][c]),
                           multiply(vk[2][r], vh[2][c]));
    }
}

void do_fit(const size_t num_coords, FloatType *w_rls, rvec *xp, rvec *x)
{
    matrix R;

    /* Calculate the rotation matrix R */
    calc_fit_R(num_coords, w_rls, xp, x, R);

    /* Rotate X */
    size_t j;
    for (j = 0; j < num_coords; ++j)
    {
        rvec x_old;

        size_t m;
        for (m = 0; m < DIM; ++m)
            x_old[m] = x[j][m];

        size_t r;
        for (r = 0; r < DIM; ++r)
        {
            x[j][r] = constant_f_0_0;

            size_t c;
            for (c = 0; c < DIM; ++c)
                assign_add(x[j][r], multiply(R[r][c], x_old[c]));
        }
    }
}

void rotalign_to(Coord3d* first, const Coord3d* second, const size_t num_coords)
{
    rvec vt[MAX_COORDS];
    rvec vr[MAX_COORDS];

    structure2rvec_arr(first, num_coords, vt);
    structure2rvec_arr(second, num_coords, vr);

    FloatType rls[MAX_COORDS];

    size_t i;
    for (i = 0; i < num_coords; ++i)
        rls[i] = constant_f_1_0;

    do_fit(num_coords, rls, vr, vt);

    for (i = 0; i < num_coords; ++i)
        rvec2Coord3D(vt[i], &first[i]);
}

FloatType rmsd_to(Coord3d* first, const Coord3d* second, const size_t num_coords)
{
    FloatType ret = constant_f_0_0;

    rotalign_to(first, second, num_coords);

    size_t i;
    for (i = 0; i < num_coords; ++i)
        assign_add(ret, add3(square(sub(first[i].x, second[i].x)),
                             square(sub(first[i].y, second[i].y)),
                             square(sub(first[i].z, second[i].z))));

    ret = square_root(divide(ret, to_current(num_coords)));

    return ret;
}
/*********************************************/


void process_packet(BufferClient* inpacket, BufferServer* outpacket)
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
    const int sock = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (sock < 0)
    {
        printf ("Error creating socket");
        exit(EXIT_FAILURE);
    }

    struct sockaddr_in sa;
    sa.sin_family = AF_INET;
    sa.sin_addr.s_addr = INADDR_ANY;
    sa.sin_port = htons(PORT);
    socklen_t address_len = sizeof(sa);

    const int b = bind(sock, (struct sockaddr*)&sa, sizeof(sa));
    if (b < 0)
    {
        printf("Error bind failed");
        close(sock);
        exit(EXIT_FAILURE);
    }

    BufferClient buffer_in;
    BufferServer buffer_out;

    while (1)
    {
        printf ("Testing....\n");

        /* WAIT TO RECEIVE A PACKET */
        const ssize_t bytes_rec = recvfrom(sock, &buffer_in, LENGHT_BUFFER, 0, (struct sockaddr*)&sa, &address_len);
        if (bytes_rec < 0)
        {
            printf("Error receiving packet\n");
        }
        /****************************/

        /* PROCESS THE PACKET */
        process_packet(&buffer_in, &buffer_out);
        /**********************/

        /* SEND RESULTS */
        const ssize_t bytes_sent = sendto(sock, &buffer_out, LENGHT_BUFFER, 0, (struct sockaddr*)&sa, sizeof(sa));
        if (bytes_sent < 0)
        {
            printf("Error sending packet\n");
        }
        /****************/
    }

    return EXIT_SUCCESS;
}
