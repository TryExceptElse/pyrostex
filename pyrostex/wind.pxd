from .v_map cimport VectorMap
from .temp cimport TMap
from .includes.cmathutils cimport vec2, vec3

cdef class WindMap(VectorMap):
    cdef void set_xy_wind_(self, int[2] pos, vec2 wind_vec)
    cdef void wind_from_xy_(self, vec2 wind_vec, vec2 pos)

    cdef inline void _wind_to_int_vec(self, int[2] int_vec, vec2 wind_vec)
    cdef inline void _int_vec_to_wind(self, vec2 wind_vec, int[2] int_vec)


cpdef WindMap make_wind_map(
        TMap warming_map,
        int seed,
        float mass,
        float radius,
        float atm_pressure)
