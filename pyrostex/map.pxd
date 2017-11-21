import numpy as np

cimport numpy as np


cdef class TextureMap:

    cdef:
        np.ndarray _arr
        public int width, height
        public int max_value

    cdef void clone(self, TextureMap p, int width, int height)
    cpdef np.ndarray make_arr(self, width, height, data_type=?)
    cpdef np.ndarray load_arr(self, unicode path)
    cpdef void save(self, unicode path)
    cpdef void set_arr(self, arr)

    cpdef int v_from_lat_lon(self, pos)
    cdef int v_from_lat_lon_(self, double[2] pos)
    cpdef int v_from_xy(self, pos)
    cdef int v_from_xy_(self, double[2] pos)
    cpdef int v_from_rel_xy(self, tuple pos)
    cdef int v_from_rel_xy_(self, double[2] pos)
    cdef int v_from_xy_indices_(self, int[2] pos)
    cpdef int v_from_vector(self, vector)
    cdef int v_from_vector_(self, double[3] vector)

    cpdef object gradient_from_xy(self, tuple[double] pos)
    cdef void gradient_from_xy_(self, double[2] gr, double[2] pos)
    cdef inline void _sample_pos(
            self,
            int[2] p0,
            int[2] p1,
            int[2] p2,
            int[2] p3,
            double[2] origin)

    cdef void r_px_(self, int[2] new_pos, int[2] old_pos)
    cdef void u_px_(self, int[2] new_pos, int[2] old_pos)
    cdef void ur_px_(self, int[2] new_pos, int[2] old_pos)

    cdef double gauss_smooth_xy_(
            self, double[2] pos, double radius, int samples)

    cpdef object vector_from_xy(self, pos)
    cdef void vector_from_xy_(self, double[3] vector, double[2] pos)
    cpdef tuple lat_lon_from_xy(self, tuple pos)
    cdef void lat_lon_from_xy_(self, double[2] lat_lon, double[2] xy_pos)
    cpdef void set_xy(self, pos, int v)
    cdef void set_xy_(self, int[2] pos, int v)
    cpdef void write_png(self, out)


cdef class CubeMap(TextureMap):
    """
    A cube map is a more efficient way to store data about a sphere,
    that also involves less stretching than a LatLonMap
    """

    cdef list tile_maps
    cdef public int tile_width, tile_height, two_thirds_width
    
    # not identical; can be passed a tile to which xy is relative
    cpdef int v_from_xy(self, pos, tile=?)
    cpdef object get_tile(self, index)
    cpdef object tile_from_lat_lon(self, pos)
    cpdef object tile_from_xy(self, pos)
    cdef object _tile_from_xy(self, double[2] pos)
    cdef short tile_index_from_xy_(self, double[2] pos)
    cdef void vector_from_tile_xy_(
            self,
            double[3] vector,
            int tile_index,
            double[2] pos)
    cpdef get_reference_position(self, tile_index)
    cdef void reference_position_(self, double[2] ref_pos, int tile_index)


cdef class LatLonMap(TextureMap):
    """
    Stores a latitude-longitude texture map
    """
    cpdef lat_lon_to_xy(self, lat_lon)
    cdef void lat_lon_to_xy_(self, double[2] xy_pos, double[2] lat_lon)
    cpdef xy_to_lat_lon(self, pos)


cdef class TileMap(TextureMap):
    """
    Stores a square texture map that is mapped to a portion of a sphere.
    """

    cdef:
        tuple p1, p2
        object parent
        public short cube_face

    cpdef get_sub_tile(self, p1, p2)


cdef class CubeSide(TileMap):
    pass


cpdef vector_from_lat_lon(pos)
cpdef lat_lon_from_vector(vector)
cdef lat_lon_from_vector_(double[2] lat_lon, double[3] vector)