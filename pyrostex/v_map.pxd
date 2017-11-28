
from .map cimport CubeMap

cdef class VectorMap(CubeMap):
    cdef void vec_from_xy_(self, int[2] vec, double[2] pos)
    cdef set_xy_vec_(self, int[2] pos, int[2] vec)

    cdef inline void _v_to_2d(self, int[2] vector, int v)
    cdef inline int _2d_to_v(self, int[2] vector)
    cdef inline void _weighted_avg(
        self, int[2] r, int[2] v0, int[2] v1, float mod)
