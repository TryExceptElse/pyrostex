"""
Stores utility functions for use with height map
"""

from .map cimport CubeMap


cdef class HeightCubeMap(CubeMap):
    cpdef float h_from_lat_lon(self, pos)
    cdef float h_from_lat_lon_(self, double[2] pos)
    cpdef float h_from_xy(self, pos)
    cdef float h_from_xy_(self, double[2] pos)
    cpdef float h_from_rel_xy(self, tuple pos)
    cdef float h_from_rel_xy_(self, double[2] pos)
    cpdef float h_from_vector(self, vector)
    cdef float h_from_vector_(self, double[3] vector)

    cpdef void set_xy_h(self, pos, float v)
    cdef void set_xy_h_(self, int[2] pos, float v)

cdef float h_from_stored_v(int stored_v)
cdef int stored_v_from_h(float h)