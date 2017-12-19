from .map cimport CubeMap
from .height cimport HeightCubeMap

from .includes.cmathutils cimport vec2, vec3
from .includes.structs cimport latlon


cdef class TMap(CubeMap):

    cpdef   float   t_from_lat_lon    (self, pos)                except? -1
    cdef    float   t_from_lat_lon_   (self, latlon pos)         except? -1
    cpdef   float   t_from_xy         (self, pos)                except? -1
    cdef    float   t_from_xy_        (self, vec2 pos)           except? -1
    cpdef   float   t_from_vector     (self, vector)             except? -1
    cdef    float   t_from_vector_    (self, vec3 vector)        except? -1

    cpdef   void    set_xy_t          (self, pos, float v)
    cdef    void    set_xy_t_         (self, int[2] pos, float v)


cpdef TMap make_warming_map(
        HeightCubeMap height_map,
        float rel_res,  # relative resolution
        float mean_temp,
        float base_atm,
        float atm_warming,
        float base_gravity,
        float radius)
