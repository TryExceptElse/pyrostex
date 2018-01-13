# THIS FILE GENERATED BY CYMACRO.
# CHANGES MADE HERE WILL NOT BE PRESERVED.

include "flags.pxi"

from cymacro import macro  # dummy function for defining macros

from includes.cmathutils cimport vec2, vec3, mat3x3
from includes.structs cimport latlon

ctypedef float a_t  # array type
ctypedef struct av:  # array vector
    a_t x, y

ctypedef fused grey_map_t:
    GreyCubeMap
    GreyLatLonMap
    GreyTileMap
    GreyCubeSide

ctypedef fused vec_map_t:
    VecCubeMap
    VecLatLonMap
    VecTileMap
    VecCubeSide

ctypedef fused map_t:
    GreyCubeMap
    GreyLatLonMap
    GreyTileMap
    GreyCubeSide
    VecCubeMap
    VecLatLonMap
    VecTileMap
    VecCubeSide

#######################################################################
# DECLARATION MACROS
#######################################################################

# grey-scale map declarations
GREY_DATA_DECLARATIONS = ''  # Macro placeholder

# vector map declarations
VECTOR_DATA_DECLARATIONS = ''  # Macro placeholder


#######################################################################
# ABSTRACT MAPS
#######################################################################


cdef class AbstractMap:
    """
    Abstract map type storing fields and methods not specific to
    any one data type or arrangement (Cube, LatLon, Tile, etc)
    """

    cdef:
        void *_arr
        bint has_original_array
        public int width, height
        public char *data_type
        vec2 _ref_pos

    # array handling methods
    cdef void _allocate_arr(self) except *
    cdef void clone(self, AbstractMap p) except *
    cpdef void load_arr(self, unicode path) except *
    cpdef void save(self, unicode path) except *
    cdef void set_arr(self, void *arr)
    cdef void *get_arr(self)
    cdef void _view_arr(self, AbstractMap m) except *

    # position conversion methods
    cpdef tuple xy_from_lat_lon(self, pos)
    cdef vec2 xy_from_lat_lon_(self, latlon pos) except *
    cpdef tuple xy_from_rel_xy(self, pos)
    cdef vec2 xy_from_rel_xy_(self, vec2 pos) except *
    cpdef tuple xy_from_vector(self, vector)
    cdef vec2 xy_from_vector_(self, vec3 vector) except *

    # other conversion methods
    cpdef object vector_from_xy(self, pos)
    cdef vec3 vector_from_xy_(self, vec2 pos) except *
    cpdef tuple lat_lon_from_xy(self, tuple pos)
    cdef latlon lat_lon_from_xy_(self, vec2 xy_pos) except *

    # out
    cpdef void write_png(self, unicode out) except *


cdef class CubeMap(AbstractMap):
    """
    A cube map is a more efficient way to store data about a sphere,
    that also involves less stretching than a LatLonMap
    """

    cdef list tile_maps
    cdef public int tile_width, tile_height, two_thirds_width

    # position conversion helper methods specific to CubeMap
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


cdef class LatLonMap(AbstractMap):
    """
    Stores a latitude-longitude texture map
    """


cdef class TileMap(AbstractMap):
    """
    Stores a square texture map that is mapped to a portion of a sphere.
    """

    cdef:
        vec2 p1, p2
        TileMap parent  # super-tile that contains this sub-tile
        CubeMap cube  # cube that Tile is a member of (if any)
        public short cube_face

    cpdef get_sub_tile(self, p1, p2)


cdef class CubeSide(TileMap):

    cdef vec2 _find_reference_position(self)


#######################################################################
# TEXTURE MAPS  (Floating Point Maps)
#######################################################################

cdef class GreyCubeMap(CubeMap):
    
    
    cdef void clone_(self, grey_map_t p) except *
    
    # value retrieval methods
    cpdef a_t v_from_lat_lon(self, pos) except? -1.
    cdef a_t v_from_lat_lon_(self, latlon pos) except? -1.
    cpdef a_t v_from_xy(self, pos) except? -1.
    cdef a_t v_from_xy_(self, vec2 pos) except? -1.
    cpdef a_t v_from_rel_xy(self, tuple pos) except? -1.
    cdef a_t v_from_rel_xy_(self, vec2 pos) except? -1.
    cdef a_t v_from_xy_indices_(self, int[2] pos) except? -1.
    cpdef a_t v_from_vector(self, vector) except? -1.
    cdef a_t v_from_vector_(self, vec3 vector) except? -1.
    
    # value setters
    cpdef void set_xy(self, pos, v) except *
    cdef void set_xy_(self, int[2] pos, a_t v) except *
    
    # TextureMap specific methods
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
    
    cdef a_t sample(self, vec2 pos) except? -1.
    
    cdef double gauss_smooth_xy_(
            self, vec2 pos, double radius, int samples) except -1.
    
    

cdef class GreyLatLonMap(LatLonMap):
    
    
    cdef void clone_(self, grey_map_t p) except *
    
    # value retrieval methods
    cpdef a_t v_from_lat_lon(self, pos) except? -1.
    cdef a_t v_from_lat_lon_(self, latlon pos) except? -1.
    cpdef a_t v_from_xy(self, pos) except? -1.
    cdef a_t v_from_xy_(self, vec2 pos) except? -1.
    cpdef a_t v_from_rel_xy(self, tuple pos) except? -1.
    cdef a_t v_from_rel_xy_(self, vec2 pos) except? -1.
    cdef a_t v_from_xy_indices_(self, int[2] pos) except? -1.
    cpdef a_t v_from_vector(self, vector) except? -1.
    cdef a_t v_from_vector_(self, vec3 vector) except? -1.
    
    # value setters
    cpdef void set_xy(self, pos, v) except *
    cdef void set_xy_(self, int[2] pos, a_t v) except *
    
    # TextureMap specific methods
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
    
    cdef a_t sample(self, vec2 pos) except? -1.
    
    cdef double gauss_smooth_xy_(
            self, vec2 pos, double radius, int samples) except -1.
    
    

cdef class GreyTileMap(TileMap):
    
    
    cdef void clone_(self, grey_map_t p) except *
    
    # value retrieval methods
    cpdef a_t v_from_lat_lon(self, pos) except? -1.
    cdef a_t v_from_lat_lon_(self, latlon pos) except? -1.
    cpdef a_t v_from_xy(self, pos) except? -1.
    cdef a_t v_from_xy_(self, vec2 pos) except? -1.
    cpdef a_t v_from_rel_xy(self, tuple pos) except? -1.
    cdef a_t v_from_rel_xy_(self, vec2 pos) except? -1.
    cdef a_t v_from_xy_indices_(self, int[2] pos) except? -1.
    cpdef a_t v_from_vector(self, vector) except? -1.
    cdef a_t v_from_vector_(self, vec3 vector) except? -1.
    
    # value setters
    cpdef void set_xy(self, pos, v) except *
    cdef void set_xy_(self, int[2] pos, a_t v) except *
    
    # TextureMap specific methods
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
    
    cdef a_t sample(self, vec2 pos) except? -1.
    
    cdef double gauss_smooth_xy_(
            self, vec2 pos, double radius, int samples) except -1.
    
    

cdef class GreyCubeSide(CubeSide):
    
    
    cdef void clone_(self, grey_map_t p) except *
    
    # value retrieval methods
    cpdef a_t v_from_lat_lon(self, pos) except? -1.
    cdef a_t v_from_lat_lon_(self, latlon pos) except? -1.
    cpdef a_t v_from_xy(self, pos) except? -1.
    cdef a_t v_from_xy_(self, vec2 pos) except? -1.
    cpdef a_t v_from_rel_xy(self, tuple pos) except? -1.
    cdef a_t v_from_rel_xy_(self, vec2 pos) except? -1.
    cdef a_t v_from_xy_indices_(self, int[2] pos) except? -1.
    cpdef a_t v_from_vector(self, vector) except? -1.
    cdef a_t v_from_vector_(self, vec3 vector) except? -1.
    
    # value setters
    cpdef void set_xy(self, pos, v) except *
    cdef void set_xy_(self, int[2] pos, a_t v) except *
    
    # TextureMap specific methods
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
    
    cdef a_t sample(self, vec2 pos) except? -1.
    
    cdef double gauss_smooth_xy_(
            self, vec2 pos, double radius, int samples) except -1.
    
    

#######################################################################
# VECTOR MAPS
#######################################################################

cdef class VecCubeMap(CubeMap):
    
    
    cdef void clone_(self, vec_map_t p) except *
    
    # value retrieval methods
    cpdef av v_from_lat_lon(self, pos) except *
    cdef av v_from_lat_lon_(self, latlon pos) except *
    cpdef av v_from_xy(self, pos) except *
    cdef av v_from_xy_(self, vec2 pos) except *
    cpdef av v_from_rel_xy(self, tuple pos) except *
    cdef av v_from_rel_xy_(self, vec2 pos) except *
    cdef av v_from_xy_indices_(self, int[2] pos) except *
    cpdef av v_from_vector(self, vector) except *
    cdef av v_from_vector_(self, vec3 vector) except *
    
    # setters
    cpdef void set_xy(self, pos, vec) except *
    cdef void set_xy_(self, int[2] pos, av vec) except *
    
    

cdef class VecLatLonMap(LatLonMap):
    
    
    cdef void clone_(self, vec_map_t p) except *
    
    # value retrieval methods
    cpdef av v_from_lat_lon(self, pos) except *
    cdef av v_from_lat_lon_(self, latlon pos) except *
    cpdef av v_from_xy(self, pos) except *
    cdef av v_from_xy_(self, vec2 pos) except *
    cpdef av v_from_rel_xy(self, tuple pos) except *
    cdef av v_from_rel_xy_(self, vec2 pos) except *
    cdef av v_from_xy_indices_(self, int[2] pos) except *
    cpdef av v_from_vector(self, vector) except *
    cdef av v_from_vector_(self, vec3 vector) except *
    
    # setters
    cpdef void set_xy(self, pos, vec) except *
    cdef void set_xy_(self, int[2] pos, av vec) except *
    
    

cdef class VecTileMap(TileMap):
    
    
    cdef void clone_(self, vec_map_t p) except *
    
    # value retrieval methods
    cpdef av v_from_lat_lon(self, pos) except *
    cdef av v_from_lat_lon_(self, latlon pos) except *
    cpdef av v_from_xy(self, pos) except *
    cdef av v_from_xy_(self, vec2 pos) except *
    cpdef av v_from_rel_xy(self, tuple pos) except *
    cdef av v_from_rel_xy_(self, vec2 pos) except *
    cdef av v_from_xy_indices_(self, int[2] pos) except *
    cpdef av v_from_vector(self, vector) except *
    cdef av v_from_vector_(self, vec3 vector) except *
    
    # setters
    cpdef void set_xy(self, pos, vec) except *
    cdef void set_xy_(self, int[2] pos, av vec) except *
    
    

cdef class VecCubeSide(CubeSide):
    
    
    cdef void clone_(self, vec_map_t p) except *
    
    # value retrieval methods
    cpdef av v_from_lat_lon(self, pos) except *
    cdef av v_from_lat_lon_(self, latlon pos) except *
    cpdef av v_from_xy(self, pos) except *
    cdef av v_from_xy_(self, vec2 pos) except *
    cpdef av v_from_rel_xy(self, tuple pos) except *
    cdef av v_from_rel_xy_(self, vec2 pos) except *
    cdef av v_from_xy_indices_(self, int[2] pos) except *
    cpdef av v_from_vector(self, vector) except *
    cdef av v_from_vector_(self, vec3 vector) except *
    
    # setters
    cpdef void set_xy(self, pos, vec) except *
    cdef void set_xy_(self, int[2] pos, av vec) except *
    
    

#######################################################################
# FUNCTIONS
#######################################################################


cpdef vector_from_lat_lon(pos)
cpdef lat_lon_from_vector(vector)
IF ASSERTS:
    cdef latlon lat_lon_from_vector_(vec3 vector) except *
    cdef vec3 vector_from_lat_lon_(latlon lat_lon) except *
ELSE:
    cdef latlon lat_lon_from_vector_(vec3 vector)
    cdef vec3 vector_from_lat_lon_(latlon lat_lon)
