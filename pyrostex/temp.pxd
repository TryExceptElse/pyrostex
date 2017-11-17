from .map cimport CubeMap
from .height cimport HeightCubeMap


cdef class TMap(CubeMap):

    cpdef float t_from_lat_lon(self, pos)
    cdef float t_from_lat_lon_(self, double[2] pos)
    cpdef float t_from_xy(self, pos)
    cdef float t_from_xy_(self, double[2] pos)
    cpdef float t_from_vector(self, vector)
    cdef float t_from_vector_(self, double[3] vector)

    cpdef void set_xy_t(self, pos, float v)
    cdef void set_xy_t_(self, int[2] pos, float v)


cpdef TMap make_warming_map(
        HeightCubeMap height_map,
        float rel_res,  # relative resolution
        float mean_temp,
        float base_atm,
        float atm_warming,
        float base_gravity,
        float radius)
