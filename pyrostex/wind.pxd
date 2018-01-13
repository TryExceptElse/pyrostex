from .map cimport GreyCubeMap, VecCubeMap
from .includes.cmathutils cimport vec2, vec3


cpdef VecCubeMap make_wind_map(
        GreyCubeMap warming_map,
        int seed,
        float mass,
        float radius,
        float atm_pressure)
