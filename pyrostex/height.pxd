from .map cimport grey_map_t, GreyCubeMap, GreyLatLonMap

cpdef void make_height_detail(grey_map_t height_map, object zone) except *
cpdef void make_tectonic_cube(
    GreyCubeMap tec_map,
    GreyLatLonMap raw_tec_map,
    object zone) except *
