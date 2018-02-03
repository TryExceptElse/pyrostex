# cython: infer_types=True, boundscheck=False, wraparound=False, nonecheck=False, language_level=3, initializedcheck=False

import numpy as np
cimport numpy as np
cimport cython
cimport openmp

from cython.parallel cimport prange, parallel, threadid
from libc.math cimport fabs, sqrt, isnan
from libc.stdlib cimport malloc, free
from libc.stdio cimport fprintf, stderr, printf

from .map cimport GreyCubeMap, a_t, av
from .noise.noise cimport PyFastNoise
from .noise.simdnoise cimport PyFastNoiseSIMD, FastNoiseVectorSet
from .includes.cmathutils cimport vec2, vec3, vec4, vec3Normalize, vec2Zero, \
    vec3New, vec3Multiply, vec3Add

include "flags.pxi"

IF DEBUG:
    from time import time

IF ASSERTS:
    DEF THREADS = 1
ELSE:
    DEF THREADS = 4  # todo: dynamically set


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


cdef class WarpGenSIMD:
    """
    Generator of 3-value noise values, produced from 3d position input.
    Intended to be used as input to other noise functions, to warp
    the output.
    """
    cdef int seed
    cdef PyFastNoiseSIMD x_noise, y_noise, z_noise

    def __init__(self, int seed, double frq, double octaves):
        self.seed = seed
        self.x_noise = PyFastNoiseSIMD()
        self.y_noise = PyFastNoiseSIMD()
        self.z_noise = PyFastNoiseSIMD()

        for i, n in enumerate((self.x_noise, self.y_noise, self.z_noise)):
            n.seed = seed + i * 100
            n.frq = frq
            n.fractal_octaves = octaves

    cdef vec3 fill_warp(
            self, float *x_warp_set, float *y_warp_set, float *z_warp_set,
            FastNoiseVectorSet *v_set) nogil:
        """
        Gets vec3 noise value from vec3 p
        :param p: vec3
        :return vec3
        """
        self.x_noise.fill_simplex_fractal_set(x_warp_set, v_set)
        self.y_noise.fill_simplex_fractal_set(y_warp_set, v_set)
        self.z_noise.fill_simplex_fractal_set(z_warp_set, v_set)


cpdef bint make_height_detail(grey_map_t height_map, object zone) except False:
    """
    Populates passed detail_map with height data from base_map.
    """

    cdef GreyCubeMap tectonic_map = zone.tectonic_map
    cdef double radius =    zone.radius
    cdef int seed =         zone.seed

    build_h0_map(height_map, tectonic_map, radius, seed)
    return 1


@cython.cdivision(True)
cdef bint build_h0_map(
        grey_map_t  h_map,
        GreyCubeMap base_height_map,
        double      radius,
        int         seed
        ) except False:
    """
    Creates the first layer of the height map.
    """
    cdef int h_width        = h_map.width
    cdef int h_height       = h_map.height
    cdef double iq_scale    = 1e4
    cdef double warp_amp    = 1.6

    cdef int x, y
    cdef int *int_xy_pos
    cdef int thread_id
    cdef vec2 xy_pos
    cdef vec3 pos_v, sample_pos_v, pos_warp_v
    cdef FastNoiseVectorSet *pos_v_set
    cdef FastNoiseVectorSet *warp_v_set
    cdef float *pos_x_set  # arrays of noise sample positions
    cdef float *pos_y_set
    cdef float *pos_z_set
    cdef float *warp_x_set
    cdef float *warp_y_set
    cdef float *warp_z_set
    cdef float *rm_result_set  # arrays storing noise results
    cdef float *rng_scale_set
    cdef double rng_scaling
    cdef double h, base_v, rm_result, base_scaling, scale_reduce, scaling
    cdef double erosion_level, eroded_iq
    cdef double b  # bump value

    cdef WarpGenSIMD warp_gen        = WarpGenSIMD(seed, radius / 800e3, 3)
    cdef PyFastNoiseSIMD amp_noise   = PyFastNoiseSIMD()
    cdef PyFastNoiseSIMD bump_noise  = PyFastNoiseSIMD()
    cdef PyFastNoiseSIMD rm_noise    = PyFastNoiseSIMD()

    # set up rm_noise
    rm_noise.seed = seed + 60
    rm_noise.frq = radius / 0.25e6
    rm_noise.fractal_octaves = 8
    rm_noise.lacunarity = 2
    rm_noise.fractal_gain = 0.5
    rm_noise.fractal_type = 'RigidMulti'

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
        thread_id   = threadid()
        xy_pos      = vec2Zero()
        int_xy_pos  = <int *>malloc(sizeof(int) * 2)
        pos_v_set   = <FastNoiseVectorSet *>malloc(sizeof(FastNoiseVectorSet))
        pos_x_set   = <float *>malloc(sizeof(float) * h_width)
        pos_y_set   = <float *>malloc(sizeof(float) * h_width)
        pos_z_set   = <float *>malloc(sizeof(float) * h_width)
        warp_v_set  = <FastNoiseVectorSet *>malloc(sizeof(FastNoiseVectorSet))
        warp_x_set  = <float *>malloc(sizeof(float) * h_width)
        warp_y_set  = <float *>malloc(sizeof(float) * h_width)
        warp_z_set  = <float *>malloc(sizeof(float) * h_width)
        rm_result_set   = <float *>malloc(sizeof(float) * h_width)
        rng_scale_set   = <float *>malloc(sizeof(float) * h_width)

        pos_v_set.size = h_width
        pos_v_set.xSet = pos_x_set
        pos_v_set.ySet = pos_y_set
        pos_v_set.zSet = pos_z_set

        warp_v_set.size = h_width
        warp_v_set.xSet = warp_x_set
        warp_v_set.ySet = warp_y_set
        warp_v_set.zSet = warp_z_set

        for y in prange(h_height, schedule='static'):
            int_xy_pos[1] = y
            xy_pos.y = y

            """
            for x in range(h_width):
                int_xy_pos[0] = x
                xy_pos.x = x

                # get vector identifying position to be sampled
                pos_v = vec3Normalize(h_map.vector_from_xy_(xy_pos))

                # create mountain / hill noise map --------------------

                # get vector with which to warp sample position
                pos_warp_v = vec3Multiply(warp_gen.get_warp(pos_v), warp_amp)
                # get position at which to sample noise
                sample_pos_v = vec3New(
                    pos_v.x + pos_warp_v.x,
                    pos_v.y + pos_warp_v.y,
                    (pos_v.z + pos_warp_v.z) * 0.75  # reduce north-south frq
                )

                rm_result = \
                    rm_noise.get_simplex_fractal_3d_(sample_pos_v) / 2 + 0.5

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

                erosion_level = scaling / 2
                eroded_iq = erode(rm_result, erosion_level)

                # create final height ---------------------------------

                h = eroded_iq * scaling * iq_scale + base_v - \
                    scaling / 2 / iq_scale

                # store final result
                h_map.set_xy_(int_xy_pos, h)
            """
            # get position vectors in this row
            for x in range(h_width):
                xy_pos.x = x
                pos_v = vec3Normalize(h_map.vector_from_xy_(xy_pos))
                pos_x_set[x] = pos_v.x
                pos_y_set[x] = pos_v.y
                pos_z_set[x] = pos_v.z

            # get vectors with which to warp sample positions
            warp_gen.fill_warp(warp_x_set, warp_y_set, warp_z_set, pos_v_set)

            # add warp to unmodified position to create sample_pos
            for x in range(h_width):
                warp_x_set[x] += pos_x_set[x]
                warp_y_set[x] += pos_y_set[x]
                warp_z_set[x] = (warp_z_set[x] + pos_z_set[x]) * 0.75

            # create mountain / hill noise map --------------------

            # populate rm results array
            rm_noise.fill_simplex_fractal_set(rm_result_set, warp_v_set)

            # scale hill value ------------------------------------

            amp_noise.fill_simplex_fractal_set(rng_scale_set, warp_v_set)

            # find base value -------------------------------------

            for x in range(h_width):
                pos_v = vec3New(pos_x_set[x], pos_y_set[x], pos_z_set[x])
                base_v = base_height_map.v_from_vector_(pos_v) / 300

                # scale hill value ------------------------------------

                rng_scaling = rng_scale_set[x] / 2 + 0.5
                base_scaling = fabs(base_v / 1e4)
                if base_scaling > 1:
                    base_scaling = 1
                scale_reduce = 1 - sqrt(base_scaling)
                if scale_reduce > 0:
                    rng_scaling = reduce(rng_scaling, scale_reduce)
                scaling = rng_scaling / 2 + base_scaling / 2

                # create pseudo-erosion -------------------------------

                rm_result = -rm_result_set[x] / 2 + 0.5
                erosion_level = scaling / 2
                eroded_iq = erode(rm_result, erosion_level)

                # create final height ---------------------------------

                h = eroded_iq * scaling * iq_scale + base_v - \
                    scaling / 2 / iq_scale

                # store final result
                int_xy_pos[0] = x
                h_map.set_xy_(int_xy_pos, h)

            # """

        free(int_xy_pos)
        free(pos_v_set)
        free(pos_x_set)
        free(pos_y_set)
        free(pos_z_set)
        free(warp_v_set)
        free(warp_x_set)
        free(warp_y_set)
        free(warp_z_set)
        free(rm_result_set)
        free(rng_scale_set)

    IF DEBUG:
        tf = time()
        print('height layer 0 generation time: {}'.format(tf - t0))
    return 1


cpdef bint make_tectonic_cube(
        GreyCubeMap tec_map,
        GreyLatLonMap raw_tec_map,
        object zone) except False:
    """
    Creates tectonic cube map from raw tectonic lat-lon map.
    Warp is applied to introduce curvature of ridges in resulting map.
    """
    cdef:
        WarpGenerator warp_gen = WarpGenerator(zone.seed, 0.5, 2)
        int t_width     = tec_map.width
        int t_height    = tec_map.height

        int x, y
        int *int_xy_pos
        vec2 xy_pos
        vec3 pos_v, warped_v, warp
        float h

    IF DEBUG:
        t0 = time()
        print('generating tectonic map from raw')

    with nogil, parallel(num_threads=THREADS):
        xy_pos = vec2Zero()
        int_xy_pos = <int *>malloc(sizeof(int) * 2)

        for y in prange(t_height):
            int_xy_pos[1] = y
            xy_pos.y = y
            for x in range(t_width):
                int_xy_pos[0] = x
                xy_pos.x = x

                pos_v = tec_map.vector_from_xy_(xy_pos)
                warp = vec3Multiply(warp_gen.get_warp(pos_v), 0.2)
                warped_v = vec3Add(pos_v, warp)
                h = raw_tec_map.v_from_vector_(warped_v)
                tec_map.set_xy_(int_xy_pos, h)
        free(int_xy_pos)

    IF DEBUG:
        tf = time()
        print('Tectonic CubeMap generation time: {}'.format(tf - t0))
    return 1


@cython.cdivision(True)
cdef double reduce(double v, double level) nogil:
    """
    Given a height value between 0 and 1, returns a reduced
    value that smoothly slopes to the passed level.
    Effect will be greatest on values at or below the passed level.
    """
    if level == 1:
        return 0
    return v ** (1 / (1 - level)) * (1 - level)

@cython.cdivision(True)
cdef double erode(double v, double level) nogil:
    """
    Given a height value between 0 and 1, returns an eroded value.
    At level 0, no erosion, at level 1, terrain is flat.
    """
    if level == 1:
        return 2. / 3.
    return v ** (1 / (1 - level)) * (1 - level) + level * 2 / 3
