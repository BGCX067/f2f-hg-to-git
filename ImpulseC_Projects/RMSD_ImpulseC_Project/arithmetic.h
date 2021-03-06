/*
arithmetic.h:
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


#ifndef ARITHMETIC_H_
#define ARITHMETIC_H_


/**** DEFINED BY USER ************************/
#define USE_FIXED_POINT
/*********************************************/


/**** CONSTANTS ******************************/
#define DIM                   (3)
#define JACOBI_DIM            (2 * DIM)
/*********************************************/


/**** FLOATING POINT *************************/
#ifdef USE_FLOATS
#include <math.h>

typedef float FloatType;
typedef double DoubleType;

#define to_current(x)         (x)
#define float_to_current(x)   (x)
#define double_to_current(x)  (x)
#define current_to_float(x)   (x)

#define square_root(x)        (sqrt(x))
#define absolute(x)           (fabs(x))
#define multiply(a, b)        ((a) * (b))
#define divide(a, b)          ((a) / (b))

//--> CONSTANTS
#define constant_f_0_0        (0.0f)
#define constant_f_1_0        (1.0f)

#define constant_d_0_0        (0.0)
#define constant_d_1_0        (1.0)
#define constant_d_0_2        (0.2)
#define constant_d_100_0      (100.0)
#define constant_d_0_5        (0.5)
#define constant_d_n10000_0   (-10000.0)

#define constant_sqrt2        (1.41421356237309504880)
#define constant_jacobi_dim   (JACOBI_DIM)
/*********************************************/


/**** FIXED POINT ****************************/
#elif defined(USE_FIXED_POINT)

#define FloatType int32
#define DoubleType int32

#define FRACBITS 8

#define to_current(x)         ((FloatType)(x) << FRACBITS)

#define float_to_current(x)   ((FloatType)((x) * (1 << FRACBITS)))
#define double_to_current(x)  ((DoubleType)((x) * (1 << FRACBITS)))
#define current_to_float(x)   ((float)(x) / (1 << FRACBITS))
#define current_to_double(x)  ((double)(x) / (1 << FRACBITS))

#define square_root(x)        (fp_square_root(x))
#define absolute(x)           ((x) < 0 ? (-x) : (x))
#define multiply(a, b)        (((a) * (b)) >> FRACBITS)
#define divide(a, b)          (((a) << FRACBITS) / (b))

//--> CONSTANTS
#define constant_f_0_0        (0)
#define constant_f_1_0        (to_current(1))

#define constant_d_0_0        (0)
#define constant_d_1_0        (to_current(1))
#define constant_d_0_2        (divide(to_current(1), to_current(5)))
#define constant_d_100_0      (to_current(100))
#define constant_d_0_5        (divide(to_current(1), to_current(2)))
#define constant_d_n10000_0   (to_current(-10000))

// TODO ...
//#define constant_sqrt2      ((FloatType)815238614083298944 >> (sizeof(FloatType) * 8 - 1 - 4 - FRACBITS))
// Reference:
// if FRACBITS = 8 --> 362
// if FRACBITS = 16 --> 92681

#define constant_jacobi_dim   (to_current(JACOBI_DIM))
/*********************************************/


/**** BINARY SCALING *************************/
#elif defined(USE_BINARY_SCALING)
#error Not yet implemented
/*********************************************/


/**** ERROR ARITHMETIC ***********************/
#else
#error Arithmetic implementation not specified
#endif
/*********************************************/


/**** GENERAL ARITHMETIC *************************/
#define add(a, b)             ((a) + (b))
#define add3(a, b, c)         (add(a, add(b, c)))
#define sub(a, b)             ((a) - (b))
#define multiply3(a, b, c)    (multiply(multiply((a), (b)), (c)))
#define assign_add(v, x)      (v += (x))
#define assign_sub(v, x)      (v -= (x))
#define square(x)             (multiply(x, x))
/*********************************************/


#endif /* ARITHMETIC_H_ */
