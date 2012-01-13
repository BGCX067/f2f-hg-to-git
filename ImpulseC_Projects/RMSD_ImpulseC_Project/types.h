/*
types.h:
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


#ifndef TYPES_H_
#define TYPES_H_

#include "arithmetic.h"

typedef struct
{
    FloatType x,y,z;
} Coord3d;

typedef FloatType rvec[DIM];
typedef DoubleType dvec[DIM];
typedef FloatType matrix[DIM][DIM];

#endif /* TYPES_H_ */
