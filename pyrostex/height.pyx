# cython: infer_types=True, boundscheck=False, nonecheck=False, language_level=3, initializedcheck=False

import numpy as np
cimport numpy as np
from libc.math cimport fabs

from .map cimport GreyCubeMap, a_t, av
from .noise.noise cimport PyFastNoise
from .includes.cmathutils cimport vec2, vec3, vec4, vec3Normalize

include "flags.pxi"
include "iq_noise.pxi"

IF DEBUG:
    from settings import ROOT_PATH  # used for output
    from time import time


cpdef void make_height_detail(grey_map_t height_map, object zone) except *:
    """
    Populates passed detail_map with height data from base_map.
    """

    cdef GreyCubeMap tectonic_map = zone.tectonic_map
    cdef double radius =    zone.radius
    cdef int seed =         zone.seed

    build_h0_map(height_map, tectonic_map, radius, seed)


cdef void build_h0_map(
        grey_map_t  h_map, 
        GreyCubeMap base_height_map,
        double      radius,
        int         seed
        ) except *:
    """
    Creates the first layer of the height map.
    """
    cdef int[2] int_xy_pos
    cdef vec2 xy_pos
    cdef vec3 pos_vector
    cdef vec4 iq_result
    cdef float h, base_v, base_multiplicand, base_addend
    cdef float amp
    cdef float r0, r1, r2  # ridge values
    cdef float b  # bump value

    cdef PyFastNoise amp_noise       = PyFastNoise()
    cdef PyFastNoise ridge_noise0    = PyFastNoise()
    cdef PyFastNoise ridge_noise1    = PyFastNoise()
    cdef PyFastNoise ridge_noise2    = PyFastNoise()
    cdef PyFastNoise bump_noise      = PyFastNoise()
    
    # set up amp_noise
    amp_noise.seed = seed + 10
    amp_noise.frq = radius / 5e4  # 50km base wavelength
    amp_noise.fractal_octaves = 4
    amp_noise.lacunarity = 2
    amp_noise.fractal_gain = 0.5

    # set up ridge noise layers
    ridge_noise0.seed   = seed + 20
    ridge_noise1.seed   = seed + 30
    ridge_noise2.seed   = seed + 40
    ridge_noise0.frq    = radius / 40e3     # 40km wavelength
    ridge_noise1.frq    = radius / 4e3      # 4km wavelength
    ridge_noise2.frq    = radius / 500      # 500m wavelength
    ridge_noise0.fractal_octaves = \
        ridge_noise1.fractal_octaves = \
        ridge_noise2.fractal_octaves = 3

    # set up bump noise
    bump_noise.seed = seed + 50
    bump_noise.frq = radius / 100   # 100m base wavelength
    bump_noise.fractal_octaves = 4
    amp_noise.lacunarity = 4
    amp_noise.fractal_gain = 0.25
    
    IF DEBUG:
        t0 = time()
        print('generating h0 map')

    # """
    for y in range(h_map.height):
        int_xy_pos[1] = y
        xy_pos.y = y
        for x in range(h_map.width):
            int_xy_pos[0] = x
            xy_pos.x = x

            # get vector identifying position to be sampled
            pos_v = vec3Normalize(h_map.vector_from_xy_(xy_pos))

            amp = amp_noise.get_simplex_fractal_3d_(pos_v)
            r0  = (1 - fabs(ridge_noise0.get_simplex_fractal_3d_(pos_v)))
            r1  = (1 - fabs(ridge_noise1.get_simplex_fractal_3d_(pos_v))) * 0.3
            r2  = (1 - fabs(ridge_noise2.get_simplex_fractal_3d_(pos_v))) * 0.1
            b   = bump_noise.get_simplex_fractal_3d_(pos_v) * 0.0001
            h   = (r0 + r1 + r2 + b)  # * amp
            base_v = base_height_map.v_from_vector_(pos_v)
            base_multiplicand = base_v * 0.5
            h = h * 3000  # base_multiplicand + base_v

            # store result
            h_map.set_xy_(int_xy_pos, h)
    """

    for y in range(h_map.height):
        int_xy_pos[1] = y
        xy_pos.y = y
        for x in range(h_map.width):
            int_xy_pos[0] = x
            xy_pos.x = x

            # get vector identifying position to be sampled
            pos_v = vec3Normalize(h_map.vector_from_xy_(xy_pos))

            iq_result = fbmd(vec3Multiply(pos_v, 2))
            base_v = base_height_map.v_from_vector_(pos_v)
            base_multiplicand = base_v * 0.5
            h = iq_result.x * base_multiplicand + base_v

            # store result
            h_map.set_xy_(int_xy_pos, iq_result.x * 3000)
    """

    IF DEBUG:
        tf = time()
        print('height layer 0 generation time: {}'.format(tf - t0))
        print('writing height layer 0')
        # h_map.write_png(
        #     ROOT_PATH + '/test/resources/out/test_spheroid/h0_map.png')
        print('done writing iq map')
