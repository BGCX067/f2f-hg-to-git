/*
rmsd_calc.h:
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

#include <stddef.h>
#include "arithmetic.h"
#include "types.h"

FloatType rmsd_to(Coord3d* first, const Coord3d* second, const size_t num_coords);

#endif /* RMSD_CALC_H_ */
