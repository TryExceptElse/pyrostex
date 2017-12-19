import numpy as np

cimport numpy as np

from .includes.cmathutils cimport vec2, vec3, mat3x3
from .includes.structs cimport latlon

cdef class TextureMap:

    cdef:
        np.ndarray _arr
        public int width, height
        public int max_value

    cdef void clone(self, TextureMap p, int width, int height) except *
    cpdef np.ndarray make_arr(self, width, height, data_type=?)
    cpdef np.ndarray load_arr(self, unicode path)
    cpdef void save(self, unicode path)
    cpdef void set_arr(self, arr)

    cpdef int v_from_lat_lon(self, pos) except? -1
    cdef int v_from_lat_lon_(self, latlon pos) except? -1
    cpdef int v_from_xy(self, pos) except? -1
    cdef int v_from_xy_(self, vec2 pos) except? -1
    cpdef int v_from_rel_xy(self, tuple pos) except? -1
    cdef int v_from_rel_xy_(self, vec2 pos) except? -1
    cdef int v_from_xy_indices_(self, int[2] pos) except? -1
    cpdef int v_from_vector(self, vector) except? -1
    cdef int v_from_vector_(self, vec3 vector) except? -1

    cpdef object gradient_from_xy(self, tuple[double] pos)
    cdef vec2 gradient_from_xy_(self, vec2 pos) except *
    cdef inline void _sample_pos(
            self,
            int[2] p0,
            int[2] p1,
            int[2] p2,
            int[2] p3,
            vec2 origin)

    cdef inline void r_px_(self, int[2] new_pos, int[2] old_pos)
    cdef inline void u_px_(self, int[2] new_pos, int[2] old_pos)
    cdef inline void ur_px_(self, int[2] new_pos, int[2] old_pos)

    cdef double gauss_smooth_xy_(
            self, vec2 pos, double radius, int samples) except -1.

    cpdef object vector_from_xy(self, pos)
    cdef vec3 vector_from_xy_(self, vec2 pos) except *
    cpdef tuple lat_lon_from_xy(self, tuple pos)
    cdef latlon lat_lon_from_xy_(self, vec2 xy_pos) except *
    cpdef void set_xy(self, pos, int v)
    cdef void set_xy_(self, int[2] pos, int v)
    cpdef void write_png(self, unicode out)


cdef class CubeMap(TextureMap):
    """
    A cube map is a more efficient way to store data about a sphere,
    that also involves less stretching than a LatLonMap
    """

    cdef list tile_maps
    cdef public int tile_width, tile_height, two_thirds_width
    
    # not identical; can be passed a tile to which xy is relative
    cpdef int v_from_xy(self, pos, tile=?) except? -1
    cpdef CubeSide get_tile(self, int index)
    cpdef CubeSide tile_from_lat_lon(self, pos)
    cdef CubeSide tile_from_lat_lon_(self, latlon pos)
    cpdef CubeSide tile_from_xy(self, pos)
    cdef CubeSide tile_from_xy_(self, vec2 pos)
    cpdef CubeSide tile_from_vector(self, vector)
    cdef CubeSide tile_from_vector_(self, vec3 vector)
    cdef int tile_index_from_vector_(self, vec3 vector)
    cpdef short tile_index_from_xy(self, pos)
    cdef short tile_index_from_xy_(self, vec2 pos)
    cdef vec3 vector_from_tile_xy_(self, int tile_index, vec2 pos) except *
    cpdef get_reference_position(self, tile_index)
    cdef vec2 reference_position_(self, int tile_index) except *


cdef class LatLonMap(TextureMap):
    """
    Stores a latitude-longitude texture map
    """
    cpdef lat_lon_to_xy(self, lat_lon)
    cdef vec2 lat_lon_to_xy_(self, latlon lat_lon)
    cpdef xy_to_lat_lon(self, pos)


cdef class TileMap(TextureMap):
    """
    Stores a square texture map that is mapped to a portion of a sphere.
    """

    cdef:
        tuple p1, p2
        TileMap parent  # super-tile that contains this sub-tile
        CubeMap cube  # cube that Tile is a member of (if any)
        public short cube_face

    cpdef get_sub_tile(self, p1, p2)


cdef class CubeSide(TileMap):
    pass


cpdef vector_from_lat_lon(pos)
cpdef lat_lon_from_vector(vector)
cdef latlon lat_lon_from_vector_(vec3 vector)
cdef int sample(np.ndarray arr, vec2 pos) except? -1