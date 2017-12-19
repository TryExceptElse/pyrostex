# cython: infer_types=True, boundscheck=False, nonecheck=False, language_level=3,

"""
Module containing a cube map that stores 2d surface vectors
"""

include "flags.pxi"

import numpy as np
cimport numpy as np

cimport cython

from .map cimport CubeMap


DEF HALF_UINT16 = 32768


cdef class VectorMap(CubeMap):
    def __init__(self, **kwargs):
        # check that data type is usable
        data_type = kwargs.get('data_type', None)
        if data_type is None:
            kwargs['data_type'] = np.uint32
        elif data_type != np.uint32:
            raise ValueError('Vector map must store values of uint32.'
                             'Got: {}'.format(kwargs['data_type']))
        super(VectorMap, self).__init__(**kwargs)

    cdef int v_from_xy_(self, double[2] pos) except? -1:
        cdef int[2] vec
        self.vec_from_xy_(vec, pos)
        return self._2d_to_v(vec)

    @cython.wraparound(False)
    cdef void vec_from_xy_(self, int[2] vec, double[2] pos):
        """
        Gets pixel value at passed position on this map.
        :param pos: pos
        :return: int
        """
        cdef int a0, a1, b0, b1, vf
        cdef int[2] v0, v1, v2, v3
        cdef float a_mod, b_mod

        a = pos[0]
        b = pos[1]
        if not 0 <= a <= self.width - 1:
            raise ValueError(
                '{} outside width range 0 - {}'.format(a, self.width - 1))
        if not 0 <= b <= self.height - 1:
            raise ValueError(
                '{} outside height range 0 - {}'.format(b, self.height - 1))
        a_mod = a % 1
        b_mod = b % 1
        if a_mod == 0.:
            a0 = int(a)
            a1 = -1
        else:
            a0 = int(a)
            a1 = int(a) + 1
            IF ASSERTS:
                assert a1 < self.width
        if b_mod == 0.:
            b0 = int(b)
            b1 = -1
        else:
            b0 = int(b)
            b1 = int(b) + 1
            IF ASSERTS:
                assert b1 < self.height
        IF ASSERTS:
            assert a0 < self.width
            assert b0 < self.height

        if b1 == -1 and a1 == -1:
            # if both passed values are whole numbers, just get the
            # corresponding value
            self._v_to_2d(vec, int(self._arr[b0][a0]))
        elif a1 == -1 and b1:
            # if only one column
            self._v_to_2d(v0, self._arr[b0][a0])
            self._v_to_2d(v1, self._arr[b1][a0])
            # collapse values into v0
            self._weighted_avg(vec, v0, v1, b_mod)
        elif b1 == -1 and a1:
            # if only one row
            self._v_to_2d(v0, self._arr[b1][a0])
            self._v_to_2d(v1, self._arr[b0][a0])
            # collapse values into v0
            self._weighted_avg(vec, v0, v1, a_mod)
        else:
            # if all 4 pixels are to be used
            v2 = self._arr[b0][a0]
            v1 = self._arr[b1][a0]
            v3 = self._arr[b0][a1]
            v0 = self._arr[b1][a1]
            # collapse left values into v2
            self._weighted_avg(v2, v2, v1, b_mod)
            # collapse right values into v3
            self._weighted_avg(v3, v3, v0, b_mod)
            # collapse left and right values into v0
            self._weighted_avg(vec, v2, v3, a_mod)
        # no return value, result stored in passed vec memory view.

    cdef set_xy_vec_(self, int[2] pos, int[2] vec):
        cdef int v = self._2d_to_v(vec)
        self.set_xy_(pos, v)

    @cython.wraparound(False)
    cdef inline void _v_to_2d(self, int[2] vector, int v):
        """
        Converts passed integer value into a 2d vector and
        stores it within the passed memory view.
        Passed integers must be smaller than 2^16 (65,536).
        """
        vector[0] = (v >> 16) & 0xffff - HALF_UINT16  # (65,536)
        vector[1] = v & 0xffff - HALF_UINT16  # (65,536)

    @cython.wraparound(False)
    cdef inline int _2d_to_v(self, int[2] vector):
        """
        Converts passed vector containing int16 (signed)
        to a uint32 for storage.
        """
        return (
            ((vector[0] + HALF_UINT16 & 0xffff) << 16) |
            (vector[1] + HALF_UINT16 & 0xffff)
        )

    @cython.wraparound(False)
    cdef inline void _weighted_avg(
            self, int[2] r, int[2] v0, int[2] v1, float mod):
        r[0] = int(float(v1[0]) * mod + float(v0[0]) * (1 - mod))
        r[1] = int(float(v1[1]) * mod + float(v0[1]) * (1 - mod))
