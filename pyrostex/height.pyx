# cython: infer_types=True, boundscheck=False, wraparound=True, nonecheck=False, language_level=3, initializedcheck=False

import numpy as np
cimport numpy as np
cimport cython

from cython.parallel cimport prange, parallel
from libc.math cimport fabs, sqrt
from libc.stdlib cimport malloc, free

from .map cimport GreyCubeMap, a_t, av
from .noise.noise cimport PyFastNoise
from .includes.cmathutils cimport vec2, vec3, vec4, vec3Normalize, vec2Zero

include "flags.pxi"
include "iq_noise.pxi"

IF DEBUG:
    from time import time

DEF THREADS = 2  # todo: dynamically set


cdef class WarpGenerator:
    """
    Generator of 3-value noise values, produced from 3d position input.
    Intended to be used as input to other noise functions, to warp
    the output.
    """
    cdef int seed
    cdef PyFastNoise x_noise, y_noise, z_noise

    def __init__(self, int seed, double frq, double octaves):
        self.seed = seed
        self.x_noise = PyFastNoise()
        self.y_noise = PyFastNoise()
        self.z_noise = PyFastNoise()

        for i, n in enumerate((self.x_noise, self.y_noise, self.z_noise)):
            n.seed = seed + i * 100
            n.frq = frq
            n.fractal_octaves = octaves

    cdef vec3 get_warp(self, vec3 p) nogil:
        """
        Gets vec3 noise value from vec3 p
        :param p: vec3
        :return vec3
        """
        return vec3New(
            self.x_noise.get_simplex_fractal_3d_(p),
            self.y_noise.get_simplex_fractal_3d_(p),
            self.z_noise.get_simplex_fractal_3d_(p)
        )


cpdef void make_height_detail(grey_map_t height_map, object zone) except *:
    """
    Populates passed detail_map with height data from base_map.
    """

    cdef GreyCubeMap tectonic_map = zone.tectonic_map
    cdef double radius =    zone.radius
    cdef int seed =         zone.seed

    build_h0_map(height_map, tectonic_map, radius, seed)


@cython.cdivision(True)
cdef void build_h0_map(
        grey_map_t  h_map, 
        GreyCubeMap base_height_map,
        double      radius,
        int         seed
        ) except *:
    """
    Creates the first layer of the height map.
    """
    cdef int h_width = h_map.width
    cdef int h_height = h_map.height
    cdef int x, y
    cdef int *int_xy_pos
    cdef vec2 xy_pos
    cdef vec3 pos_v, sample_pos_v, iq_sample_pos, pos_warp_v
    cdef double iq_frq_mod, warp_amp,
    cdef double rng_scaling, base_scaling, scale_reduce, scaling
    cdef double erosion_level, eroded_iq
    cdef float iq_result
    cdef float h, base_v, base_multiplicand, base_addend
    cdef float b  # bump value

    cdef WarpGenerator warp_gen      = WarpGenerator(seed, radius / 800e3, 3)
    cdef PyFastNoise amp_noise       = PyFastNoise()
    cdef PyFastNoise bump_noise      = PyFastNoise()

    # set up amp_noise
    amp_noise.seed = seed + 10
    amp_noise.frq = radius / 3.2e6  # ~50km base wavelength
    amp_noise.fractal_octaves = 2
    amp_noise.lacunarity = 4
    amp_noise.fractal_gain = 0.25

    # set up bump noise
    bump_noise.seed = seed + 50
    bump_noise.frq = radius / 100   # 100m base wavelength
    bump_noise.fractal_octaves = 4
    bump_noise.lacunarity = 4
    bump_noise.fractal_gain = 0.25

    IF DEBUG:
        t0 = time()
        print('generating h0 map')

    with nogil, parallel(num_threads=THREADS):
        # if not explicitly initialized here, threads will all attempt to
        # use the same position struct. That would work poorly.
        xy_pos = vec2Zero()
        int_xy_pos = <int *>malloc(sizeof(int) * 2)

        for y in prange(h_height, schedule='dynamic', chunksize=8):
            int_xy_pos[1] = y
            xy_pos.y = y
            for x in range(h_width):
                int_xy_pos[0] = x
                xy_pos.x = x

                # get vector identifying position to be sampled
                pos_v = vec3Normalize(h_map.vector_from_xy_(xy_pos))

                # create mountain / hill noise map --------------------

                iq_frq_mod = radius / 0.125e6
                warp_amp = 1.6
                pos_warp_v = vec3Multiply(warp_gen.get_warp(pos_v), warp_amp)
                sample_pos_v = vec3New(
                    pos_v.x,
                    pos_v.y,
                    pos_v.z * 0.75  # reduce north-south frequency
                )
                sample_pos_v = vec3Add(sample_pos_v, pos_warp_v)
                iq_sample_pos = vec3Multiply(sample_pos_v, iq_frq_mod)

                iq_result = fbm(iq_sample_pos)  # should be *1/3 base el.


                # find base value -------------------------------------

                base_v = base_height_map.v_from_vector_(pos_v) / 300

                # scale hill value ------------------------------------

                rng_scaling = \
                    amp_noise.get_simplex_fractal_3d_(sample_pos_v) / 2 + 0.5
                base_scaling = base_v / 1e4
                if base_scaling > 1:
                    base_scaling = 1
                scale_reduce = 1 - sqrt(fabs(base_v / 1e4))
                if scale_reduce > 0:
                    rng_scaling = reduce(rng_scaling, scale_reduce)
                scaling = rng_scaling / 2 + base_scaling / 2

                # create pseudo-erosion -------------------------------

                erosion_level = scaling / 3
                eroded_iq = erode(iq_result, erosion_level)

                # create final height ---------------------------------

                h = eroded_iq * scaling * 7500 + base_v - scaling / 2

                # store result via pointer-fu
                h_map.set_xy_(int_xy_pos, h)

        free(int_xy_pos)

    IF DEBUG:
        tf = time()
        print('height layer 0 generation time: {}'.format(tf - t0))
        print('writing height layer 0')
        print('done writing')


cpdef void make_tectonic_cube(
        GreyCubeMap tec_map,
        GreyLatLonMap raw_tec_map,
        object zone) except *:
    """
    Creates tectonic cube map from raw tectonic lat-lon map.
    Warp is applied to introduce curvature of ridges in resulting map.
    """
    cdef:
        WarpGenerator warp_gen = WarpGenerator(zone.seed, 0.5, 2)
        int[2] int_xy_pos
        vec2 xy_pos

    for y in range(tec_map.height):
        int_xy_pos[1] = y
        xy_pos.y = y
        for x in range(tec_map.width):
            int_xy_pos[0] = x
            xy_pos.x = x

            pos_v = tec_map.vector_from_xy_(xy_pos)
            warp = vec3Multiply(warp_gen.get_warp(pos_v), 0.2)
            warped_v = vec3Add(pos_v, warp)
            tec_map.set_xy_(int_xy_pos, raw_tec_map.v_from_vector_(warped_v))


@cython.cdivision(True)
cdef double reduce(double v, double level) nogil:
    """
    Given a height value between 0 and 1, returns a reduced
    value that smoothly slopes to the passed level.
    Effect will be greatest on values at or below the passed level.
    """
    if level == 1:
        return 1
    return v ** (1 / (1 - level)) * (1 - level)

@cython.cdivision(True)
cdef double erode(double v, double level) nogil:
    """
    Given a height value between 0 and 1, returns an eroded value.
    At level 0, no erosion, at level 1, terrain is flat.
    """
    if level == 1:
        return 1
    return v ** (1 / (1 - level)) * (1 - level) + level * 2 / 3
