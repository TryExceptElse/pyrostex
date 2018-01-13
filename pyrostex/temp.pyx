# cython: infer_types=True, boundscheck=False, nonecheck=False, language_level=3

"""
Handles generation of temperature map from height map
"""

# imports from packages
from libc.math cimport exp, cos, log2, ceil

import png

cimport cython

# imports from within project
from .map cimport GreyCubeMap, lat_lon_from_vector_

include "flags.pxi"


DEF ATM_M = 0.029  # molar mass of atmosphere
DEF R = 8.3144598  # gas constant

DEF MAX_T = 8192  # for sanity-checking

DEF MEAN_CS = 0.866  # average cross section
DEF BASE_H_VAL = 32767


cpdef GreyCubeMap make_warming_map(
        GreyCubeMap height_map,
        float rel_res,  # relative resolution
        float mean_temp,
        float base_atm,
        float atm_warming,
        float base_gravity,
        float radius):
    """
    Creates warming map from height map.
    This map approximates the amount of heat imparted to the atmosphere
    at any given position.
    """
    cdef int x, y
    cdef vec2 xy_pos
    cdef vec2 src_xy
    cdef latlon lat_lon
    cdef int[2] xy_int_pos
    cdef float t

    cdef int width = int(height_map.width * rel_res)
    cdef int height = int(height_map.height * rel_res)
    cdef GreyCubeMap warming_map = GreyCubeMap(
        width=width,
        height=height)

    no_atm_temp = mean_temp - atm_warming # temp at mean lat in w/o atmosphere
    if not 0 <= no_atm_temp <= MAX_T:
        assert False, no_atm_temp  # sanity check
    for x in range(width):
        xy_pos.x = x
        xy_int_pos[0] = x
        src_xy.x = xy_pos.x / width * height_map.width
        for y in range(height):
            # get lat of position
            xy_pos.y = y
            xy_int_pos[1] = y
            src_xy.y = xy_pos.y / height * height_map.height

            h = height_map.v_from_xy_(src_xy) - BASE_H_VAL
            lat_lon = height_map.lat_lon_from_xy_(src_xy)
            # calculate temperature for position as it would be without atm
            t = find_cs_ratio(lat_lon.lat) * no_atm_temp
            if not 0 <= t <= MAX_T:
                assert False, t  # sanity check
            # apply effects of elevation
            # if base_atm > 0:
            #     p = find_pressure(h, base_atm, t, base_gravity)
            #     t += ((p / base_atm) * 2 - 1) * atm_warming
            if not 0 <= t <= MAX_T:
                assert False, (t, base_atm)  # sanity check
            warming_map.set_xy_(xy_int_pos, t)

    return warming_map

cdef inline float find_pressure(float h, float pb, float tb, float g):
    """
    Calculates pressure at a given point
    :param h: elevation above base (~sea level)
    :param pb: pressure at base elevation
    :param tb: temperature at base elevation
    :param g: gravities at surface
    """
    return pb * exp((-g * ATM_M * h) / (R * tb))


@cython.cdivision(True)
cdef inline float find_cs_ratio(double lat):
    """
    Finds relative cross section compared to mean latitude (30 deg)
    :param lat: double; latitude in radians
    """
    return cos(lat) / MEAN_CS  # get ratio relative to average cs
