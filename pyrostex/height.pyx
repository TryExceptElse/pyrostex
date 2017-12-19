# cython: infer_types=True, boundscheck=False, nonecheck=False, language_level=3

"""
Stores height cube map class and associated functions
"""

include "macro.pxi"

from .map cimport CubeMap


DEF MIN_HEIGHT = -1.2e7  # mirrors constant in procede.py
DEF MAX_HEIGHT = 1.2e7
DEF HEIGHT_RANGE = MAX_HEIGHT - MIN_HEIGHT

DEF MAX_STORED_V = 65535
DEF CENTER_STORED_V = 32767


cdef class HeightCubeMap(CubeMap):
    cpdef float h_from_lat_lon(self, lat_lon):
        cdef latlon lat_lon_ = cp2ll(lat_lon)
        return h_from_stored_v(self.v_from_lat_lon_(lat_lon_))

    cdef float h_from_lat_lon_(self, latlon lat_lon):
        stored_v = self.v_from_lat_lon_(lat_lon)
        return h_from_stored_v(stored_v)

    cpdef float h_from_xy(self, pos):
        """
        Gets pixel value at passed position on this map.
        :param pos: pos
        :return:
        """
        stored_v = self.v_from_xy_(cp2v_2d(pos))
        return h_from_stored_v(stored_v)

    cdef float h_from_xy_(self, vec2 pos):
        stored_v = self.v_from_xy_(pos)
        return h_from_stored_v(stored_v)

    cpdef float h_from_rel_xy(self, tuple pos):
        stored_v = self.v_from_rel_xy_(cp2v_2d(pos))
        return h_from_stored_v(stored_v)

    cdef float h_from_rel_xy_(self, vec2 pos):
        cdef vec2 abs_pos
        abs_pos.x = pos.x * self.width
        abs_pos.y = pos.y * self.height
        stored_v = self.v_from_xy_(abs_pos)
        return h_from_stored_v(stored_v)

    cpdef float h_from_vector(self, vector):
        """
        Gets pixel value identified by vector.
        :param vector:
        :return:
        """
        stored_v = self.v_from_vector_(cp2v_3d(vector))
        return h_from_stored_v(stored_v)

    cdef float h_from_vector_(self, vec3 vector):
        stored_v = self.v_from_vector_(vector)
        return h_from_stored_v(stored_v)

    cpdef void set_xy_h(self, pos, float h):
        cdef int[2] pos_
        pos_[0] = pos[0]
        pos_[1] = pos[1]
        stored_v = stored_v_from_h(h)
        self.set_xy_(pos_, stored_v)

    cdef void set_xy_h_(self, int[2] pos, float h):
        self.set_xy_(pos, stored_v_from_h(h))

        
cdef inline float h_from_stored_v(int stored_v):
    return (float(stored_v) / MAX_STORED_V - 0.5) * HEIGHT_RANGE

cdef inline int stored_v_from_h(float h):
    return int(h / HEIGHT_RANGE + 0.5 * MAX_STORED_V)
