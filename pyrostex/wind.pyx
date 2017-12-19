# cython: infer_types=True, boundscheck=False, wraparound=True, nonecheck=False, language_level=3,

"""
Handles generation of wind current map
"""

include "flags.pxi"  # debug, assert, etc flags

import numpy as np
cimport numpy as np
cimport cython

from .map cimport CubeMap
from .v_map cimport VectorMap
from .temp cimport TMap
from .noise.noise cimport PyFastNoise

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

DEF WIND_TO_INT_CONVERSION = 8  # lets speeds up to ~4000m/s be stored


cdef class WindMap(VectorMap):

    cdef void set_xy_wind_(WindMap self, int[2] pos, float[2] wind_vec):
        cdef int[2] int_vec
        self._wind_to_int_vec(int_vec, wind_vec)
        self.set_xy_vec_(pos, int_vec)

    cdef void wind_from_xy_(self, float[2] wind_vec, double[2] pos):
        cdef int[2] int_vec
        self.vec_from_xy_(int_vec, pos)
        self._int_vec_to_wind(wind_vec, int_vec)

    cdef inline void _wind_to_int_vec(self, int[2] int_vec, float[2] wind_vec):
        int_vec[0] = int(wind_vec[0] * WIND_TO_INT_CONVERSION)
        int_vec[1] = int(wind_vec[1] * WIND_TO_INT_CONVERSION)

    @cython.cdivision(True)
    cdef inline void _int_vec_to_wind(self, float[2] wind_vec, int[2] int_vec):
        wind_vec[0] = int_vec[0] / WIND_TO_INT_CONVERSION
        wind_vec[1] = int_vec[1] / WIND_TO_INT_CONVERSION


cpdef WindMap make_wind_map(
        TMap warming_map,
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
    cdef WindMap wind_map = WindMap(
        width=width,
        height=height,
        data_type=np.uint32)

    # create noise map that will be used to create approximated
    # high / low pressure systems
    cdef CubeMap noise_map = _make_noise_map(seed, width, height, radius, 3)

    cdef CubeMap smoothed_pressure = _make_pressure_map(warming_map)


cdef CubeMap _make_noise_map(
        int seed, int width, int height, float radius, int hemi_bands):

    cdef CubeMap noise_map = \
        CubeMap(width=width, height=height, data_type=np.uint16)

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
    cdef double[2] dbl_pos
    cdef double[3] vec
    cdef int v
    for x in range(width):
        pos[0] = x
        dbl_pos[0] = x
        for y in range(height):
            pos[1] = y
            dbl_pos[1] = y
            noise_map.vector_from_xy_(vec, dbl_pos)
            v = int(n.get_simplex_fractal_3d(vec[0], vec[1], vec[2]) *
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


cdef CubeMap _make_pressure_map(TMap warming_map):
    """
    Generates a smoothed pressure map from the passed warming map
    The generated map stores arbitrary relative pressure, not absolute values.
    The pressure should only be used for calculating wind vector.
    """
    cdef int width = warming_map.width, height = warming_map.height
    cdef int x, y  # iterated x and y values
    cdef int[2] int_pos  # stores x, y position indices
    cdef double[2] dbl_pos  # stores position as dbl (prevents repeated casts)
    cdef double v  # stores retrieved, smoothed value

    IF DEBUG:
        t0 = time()
        print('generating pressure map')

    cdef CubeMap p_map = \
        CubeMap(width=width, height=height, data_type=np.uint16)

    for x in range(width):
        int_pos[0] = x
        dbl_pos[0] = x
        for y in range(height):
            int_pos[1] = y
            dbl_pos[1] = y

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
