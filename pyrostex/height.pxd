from .map cimport grey_map_t, GreyCubeMap, GreyLatLonMap

cpdef bint make_height_detail(grey_map_t height_map, object zone) except False
cpdef bint make_tectonic_cube(
    GreyCubeMap tec_map,
    GreyLatLonMap raw_tec_map,
    object zone) except False
