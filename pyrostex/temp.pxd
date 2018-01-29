from .map cimport GreyCubeMap

from .includes.cmathutils cimport vec2, vec3
from .includes.structs cimport latlon


cpdef GreyCubeMap make_warming_map(
        GreyCubeMap height_map,
        float rel_res,  # relative resolution
        float mean_temp,
        float base_atm,
        float atm_warming,
        float base_gravity,
        float radius)
