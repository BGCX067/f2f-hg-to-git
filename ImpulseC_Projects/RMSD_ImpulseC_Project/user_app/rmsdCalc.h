/*
rmsdCalc.h:
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

#ifndef RMSD_CALC_H_
#define RMSD_CALC_H_

#include "arithmetic.h"
#include "types.h"

/**** DEFINED BY USER ************************/
#define MAX_COORDS            (100)
#define NUMBER_ITERATIONS     (3)
/*********************************************/

/**** ERRORS ***********************/
#ifndef MAX_COORDS
#error MAX COORDS not defined
#endif

#ifndef NUMBER_ITERATIONS
#error NUMBER_ITERATIONS not defined
#endif
/*********************************************/

/**** LOGIC ***********************/
#define rotate(a, i, j, k, l, tau, s)\
{\
    const DoubleType g = a[i][j];\
    const DoubleType h = a[k][l];\
\
    a[i][j] = sub(g, multiply(s, (add(h, multiply(g, tau)))));\
    a[k][l] = add(h, multiply(s, (sub(g, multiply(h, tau)))));\
}\

#define clear_mat(a)\
{\
    a[0][0] = a[0][1] = a[0][2] = constant_f_0_0;\
    a[1][0] = a[1][1] = a[1][2] = constant_f_0_0;\
    a[2][0] = a[2][1] = a[2][2] = constant_f_0_0;\
}\

#define Coord3D2rvec(coord3d, rv)\
{\
    rv[0] = (coord3d)->x;\
    rv[1] = (coord3d)->y;\
    rv[2] = (coord3d)->z;\
}\

#define rvec2Coord3D(rv, coord3d)\
{\
    (coord3d)->x = rv[0];\
    (coord3d)->y = rv[1];\
    (coord3d)->z = rv[2];\
}\

#define oprod(a, b, c)\
{\
    c[0] = sub(multiply(a[1], b[2]), multiply(a[2], b[1]));\
    c[1] = sub(multiply(a[2], b[0]), multiply(a[0], b[2]));\
    c[2] = sub(multiply(a[0], b[1]), multiply(a[1], b[0]));\
}\

#define structure2rvec_arr(coord3d, num_elements, ret)\
{\
    size_t i;\
    for (i = 0; i < num_elements; ++i)\
        Coord3D2rvec(&coord3d[i], ret[i]);\
}\
/*********************************************/


#define jacobi(a, d, v)\
{\
    DoubleType b [JACOBI_DIM];\
    DoubleType z [JACOBI_DIM];\
    size_t ip;\
    size_t i;\
\
    for (ip = 0; ip < JACOBI_DIM; ++ip)\
    {\
        size_t iq;\
        for (iq = 0; iq < JACOBI_DIM; ++iq)\
            v[ip][iq] = constant_d_0_0;\
\
        v[ip][ip] = constant_d_1_0;\
    }\
\
    for (ip = 0; ip < JACOBI_DIM; ++ip)\
    {\
        b[ip] = d[ip] = a[ip][ip];\
        z[ip] = constant_d_0_0;\
    }\
\
    for (i = 1; i <= NUMBER_ITERATIONS; ++i)\
    {\
        DoubleType sm = constant_d_0_0;\
        size_t ip;\
        DoubleType tresh;\
\
        for (ip = 0; ip < JACOBI_DIM - 1; ++ip)\
        {\
            size_t iq;\
            for (iq = ip + 1; iq < JACOBI_DIM; ++iq)\
                assign_add(sm, absolute(a[ip][iq]));\
        }\
\
        if (sm == constant_d_0_0)\
            return;\
\
        if (i < 4)\
            tresh = divide(multiply(constant_d_0_2, sm), square(constant_jacobi_dim));\
        else\
            tresh = constant_d_0_0;\
\
        for (ip = 0; ip < JACOBI_DIM - 1; ++ip)\
        {\
            size_t iq;\
\
            for (iq = ip + 1; iq < JACOBI_DIM; ++iq)\
            {\
                DoubleType g;\
                DoubleType abs_d_ip;\
                DoubleType abs_d_iq;\
\
                g = multiply(constant_d_100_0, absolute(a[ip][iq]));\
                abs_d_ip = abs(d[ip]);\
                abs_d_iq = abs(d[iq]);\
\
                if (i > 4 && add(abs_d_ip, g) == abs_d_ip && add(abs_d_iq, g) == abs_d_iq)\
                    a[ip][iq] = constant_d_0_0;\
                else if (absolute(a[ip][iq]) > tresh)\
                {\
                    DoubleType h;\
                    DoubleType t;\
                    DoubleType abs_h;\
                    DoubleType c;\
                    DoubleType s;\
                    DoubleType tau;\
                    size_t j;\
\
                    h = sub(d[iq], d[ip]);\
                    abs_h = absolute(h);\
\
                    if (add(abs_h, g) == abs_h)\
                        t = divide(a[ip][iq], h);\
                    else\
                    {\
                        const DoubleType theta = divide(multiply(constant_d_0_5, h), a[ip][iq]);\
\
                        t = divide(constant_d_1_0, add(absolute(theta), square_root(add(constant_d_1_0, square(theta)))));\
\
                        if (theta < constant_d_0_0)\
                            t = -t;\
                    }\
\
                    c = divide(constant_d_1_0, square_root(add(constant_d_1_0, square(t))));\
                    s = multiply(t, c);\
                    tau = divide(s, add(constant_d_1_0, c));\
\
                    h = multiply(t, a[ip][iq]);\
\
                    assign_sub(z[ip], h);\
                    assign_add(z[iq], h);\
                    assign_sub(d[ip], h);\
                    assign_add(d[iq], h);\
\
                    a[ip][iq] = constant_d_0_0;\
\
                    for (j = 0; j < ip; ++j)\
                        rotate(a, j, ip, j, iq, tau, s);\
\
                    for (j = ip + 1; j < iq; ++j)\
                        rotate(a, ip, j, j, iq, tau, s);\
\
                    for (j = iq + 1; j < JACOBI_DIM; ++j)\
                        rotate(a, ip, j, iq, j, tau, s);\
\
                    for (j = 0; j < JACOBI_DIM; ++j)\
                        rotate(v, j, ip, j, iq, tau, s);\
                }\
            }\
        }\
\
        for (ip = 0; ip < JACOBI_DIM; ++ip)\
        {\
            assign_add(b[ip], z[ip]);\
            d[ip] =  b[ip];\
            z[ip] =  constant_d_0_0;\
        }\
    }\
}\

#define calc_fit_R(num_coords, w_rls, xp, x, R)\
{\
    size_t DIM_DOUBLE;\
    DoubleType d[2 * DIM];\
    matrix vh, vk, u;\
    DoubleType omega[2 * DIM][2 * DIM];\
    DoubleType om[2 * DIM][2 * DIM];\
    size_t i;\
    size_t n;\
    size_t r;\
    size_t index;\
    size_t j;\
\
    DIM_DOUBLE = 2 * DIM;\
\
    for (i = 0; i < DIM_DOUBLE; ++i)\
    {\
        size_t j;\
\
        d[i] = constant_d_0_0;\
\
        for (j = 0; j < DIM_DOUBLE; ++j)\
        {\
            omega[i][j] = constant_d_0_0;\
            om[i][j] = constant_d_0_0;\
        }\
    }\
\
    /* Calculate the matrix U */\
    clear_mat(u);\
\
    for (n = 0; n < num_coords; ++n)\
    {\
        const FloatType mn = w_rls[n];\
\
        if (mn != constant_f_0_0)\
        {\
            size_t c;\
            for (c = 0; c < DIM; ++c)\
            {\
                size_t r;\
                for (r = 0; r < DIM; ++r)\
                    assign_add(u[c][r], multiply3(mn, x[n][r], xp[n][c]));\
            }\
        }\
    }\
\
    /* Construct omega */\
    for (r = 0; r < DIM_DOUBLE; ++r)\
    {\
        size_t c;\
        for (c = 0; c <= r; ++c)\
        {\
            if (r >= DIM && c < DIM)\
            {\
                omega[r][c] = u[r - DIM][c];\
                omega[c][r] = u[r - DIM][c];\
            }\
            else\
            {\
                omega[r][c] = constant_d_0_0;\
                omega[c][r] = constant_d_0_0;\
            }\
        }\
    }\
\
    /* Determine h and k */\
    jacobi(omega, d, om);\
\
    /* Copy only the first two eigenvectors */\
    for (j = 0; j < 2; ++j)\
    {\
        size_t i;\
\
        index = 0;\
\
        for (i = 1; i < DIM_DOUBLE; ++i)\
            if ( d[index] < d[i] )\
                index = i;\
\
        d[index] = constant_d_n10000_0;\
\
        for (i = 0; i < DIM; ++i)\
        {\
            vh[j][i] = multiply(constant_sqrt2, om[i][index]);\
            vk[j][i] = multiply(constant_sqrt2, om[i + DIM][index]);\
        }\
    }\
\
    /* Calculate the last eigenvector as the outer-product of the first two. */\
    oprod(vh[0], vh[1], vh[2]);\
    oprod(vk[0], vk[1], vk[2]);\
\
    /* Determine R */\
    for (r = 0; r < DIM; ++r)\
    {\
        size_t c;\
        for (c = 0; c < DIM; ++c)\
            R[r][c] = add3(multiply(vk[0][r], vh[0][c]),\
                           multiply(vk[1][r], vh[1][c]),\
                           multiply(vk[2][r], vh[2][c]));\
    }\
}\

#define do_fit(num_coords, w_rls, xp, x)\
{\
    matrix R;\
    size_t j;\
\
    /* Calculate the rotation matrix R */\
    calc_fit_R(num_coords, w_rls, xp, x, R);\
\
    /* Rotate X */\
    for (j = 0; j < num_coords; ++j)\
    {\
        rvec x_old;\
        size_t m;\
        size_t r;\
\
        for (m = 0; m < DIM; ++m)\
            x_old[m] = x[j][m];\
\
        for (r = 0; r < DIM; ++r)\
        {\
            size_t c;\
\
            x[j][r] = constant_f_0_0;\
\
            for (c = 0; c < DIM; ++c)\
                assign_add(x[j][r], multiply(R[r][c], x_old[c]));\
        }\
    }\
}\

#define rotalign_to(first, second, num_coords)\
{\
    rvec vt[MAX_COORDS];\
    rvec vr[MAX_COORDS];\
    FloatType rls[MAX_COORDS];\
    size_t i;\
\
    structure2rvec_arr(first, num_coords, vt);\
    structure2rvec_arr(second, num_coords, vr);\
\
    for (i = 0; i < num_coords; ++i)\
        rls[i] = constant_f_1_0;\
\
    do_fit(num_coords, rls, vr, vt);\
\
    for (i = 0; i < num_coords; ++i)\
        rvec2Coord3D(vt[i], &first[i]);\
}\

#define rmsd_to(first, second, num_coords)\
{\
    size_t i;\
\
    ret = constant_f_0_0;\
\
    rotalign_to(first, second, num_coords);\
\
    for (i = 0; i < num_coords; ++i)\
        assign_add(ret, add3(square(sub(first[i].x, second[i].x)),\
                             square(sub(first[i].y, second[i].y)),\
                             square(sub(first[i].z, second[i].z))));\
\
    ret = square_root(divide(ret, to_current(num_coords)));\
}\
/*********************************************/

#endif /* RMSD_CALC_H_ */

