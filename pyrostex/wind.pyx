# cython: infer_types=True, boundscheck=False, wraparound=True, nonecheck=False, language_level=3,

"""
Handles generation of wind current map
"""

include "flags.pxi"  # debug, assert, etc flags

cimport cython

from .noise.noise cimport PyFastNoise
from .includes.cmathutils cimport vec3Normalize

from libc.math cimport sqrt

IF DEBUG:
    from settings import ROOT_PATH  # used for output
    from time import time

DEF PRESSURE_COEF = 1.
DEF BANDING_COEF = 1.
DEF SIMPLEX_COEF = 1.

DEF BASE_RADIUS = 6.356e6

DEF MAP_NOISE_BASE_FRQ = 1.
DEF MAP_NOISE_OCT = 8
DEF NOISE_SCALE = 32767
DEF MEAN_NOISE_V = 32767
DEF LACUNARITY = 2
DEF GAIN = 0.5


# generate simplex noise map
# generate pressure gradient map
# for point on map:
#     get starting value from pressure gradient
#     get modifier value from noise map gradient, rotated 90 deg.
#     get banding modifier sin(lat / MAX_LAT * 2 * n_bands)
#     sum
#     add to map


cpdef VecCubeMap make_wind_map(
        GreyCubeMap warming_map,
        int seed,
        float mass,
        float radius,
        float atm_pressure):
    """
    Generates wind vector map, containing 2d vectors indicating the x, y
    velocity of wind at each given position on the cube map.
    """
    cdef int width = warming_map.width, height = warming_map.height

    # create map to store wind vectors within
    cdef VecCubeMap wind_map = VecCubeMap(
        width=width,
        height=height)

    # create noise map that will be used to create approximated
    # high / low pressure systems
    cdef GreyCubeMap noise_map = \
        _make_noise_map(seed, width, height, radius, 3)

    # cdef GreyCubeMap smoothed_pressure = _make_pressure_map(warming_map)


cdef GreyCubeMap _make_noise_map(
        int seed, int width, int height, float radius, int hemi_bands):

    cdef GreyCubeMap noise_map = \
        GreyCubeMap(width=width, height=height)

    cdef PyFastNoise n = PyFastNoise()
    n.seed = seed
    n.frq = MAP_NOISE_BASE_FRQ * sqrt(radius / BASE_RADIUS) * hemi_bands / 2
    n.fractal_octaves = MAP_NOISE_OCT
    n.lacunarity = LACUNARITY
    n.fractal_gain = GAIN

    IF DEBUG:
        print('generating wind noise map')
        print('frq: ' + str(n.frq))
        print('oct: ' + str(n.fractal_octaves))
        t0 = time()

    cdef int[2] pos
    cdef vec2 dbl_pos
    cdef vec3 vec
    cdef int v
    for x in range(width):
        pos[0] = x
        dbl_pos.x = x
        for y in range(height):
            pos[1] = y
            dbl_pos.y = y
            vec = vec3Normalize(noise_map.vector_from_xy_(dbl_pos))
            v = int(n.get_simplex_fractal_3d_(vec) *
                    NOISE_SCALE + MEAN_NOISE_V)
            noise_map.set_xy_(pos, v)

    IF DEBUG:
        tf = time()
        print('noise map generation time: {}'.format(tf - t0))
        print('writing noise map')
        noise_map.write_png(
            ROOT_PATH + '/test/resources/out/test_spheroid/wind_noise.png')
        print('done writing noise map')


DEF GAUSS_SAMPLES = 8  # for both x and y; total of n^2 samples taken
DEF GAUSS_RADIUS = 32.


cdef GreyCubeMap _make_pressure_map(GreyCubeMap warming_map):
    """
    Generates a smoothed pressure map from the passed warming map
    The generated map stores arbitrary relative pressure, not absolute values.
    The pressure should only be used for calculating wind vector.
    """
    cdef int width = warming_map.width, height = warming_map.height
    cdef int x, y  # iterated x and y values
    cdef int[2] int_pos  # stores x, y position indices
    cdef vec2 dbl_pos  # stores position as dbl (prevents repeated casts)
    cdef double v  # stores retrieved, smoothed value

    IF DEBUG:
        t0 = time()
        print('generating pressure map')

    cdef GreyCubeMap p_map = GreyCubeMap(width=width, height=height)

    for x in range(width):
        int_pos[0] = x
        dbl_pos.x = x
        for y in range(height):
            int_pos[1] = y
            dbl_pos.y = y

            # get smoothed value from warming_map
            v = warming_map.gauss_smooth_xy_(
                dbl_pos, GAUSS_RADIUS, GAUSS_SAMPLES)
            IF ASSERTS:
                assert v > 0.
            p_map.set_xy_(int_pos, int(v))

    IF DEBUG:
        tf = time()
        print('pressure map generation time: {}'.format(tf - t0))
        print('writing pressure map')
        p_map.write_png(
            ROOT_PATH + '/test/resources/out/test_spheroid/p_map.png')
        print('done writing pressure map')

    return p_map
