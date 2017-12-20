# cython: infer_types=True, boundscheck=False, nonecheck=False, language_level=3, initializedcheck=False

"""
Maps for storing data about a map for a sphere.
"""

# Note on method naming convention:
#   methods ending in underscore (ex: TextureMap.v_from_lat_lon_)
#   are methods that are meant to be called from c, and accept
#   c - specific arguments, such as memory views.

# todo:
#   refactor to use memory view of floats instead of np array
#   generate wind point_vector map from pressure map
#   remove redundant FastNoise wrapper class

# includes
include "flags.pxi"
include "macro.pxi"

# package imports
import numpy as np
import png
import itertools as itr

cimport numpy as np
cimport cython

from mathutils import Vector

from math import radians
from libc.math cimport cos, sin, atan2, sqrt, pow, fabs, ceil, log2, isnan

# project imports
from .includes cimport cmathutils as mu

DEF PI = 3.1415926535897932384626433832795028841971
DEF TAU = 6.2831853071795864769252867665590057683942
DEF QTR_PI = 0.785398163397448309615660845819875721049275

DEF MIN_LAT = -1.57079632679489661923132169163975144209855
DEF MAX_LAT = 1.57079632679489661923132169163975144209855
DEF LAT_RANGE = PI
DEF MIN_LON = -PI
DEF MAX_LON = PI
DEF LON_RANGE = TAU

DEF GAUSS_SAMPLES = 4


cdef class TextureMap:
    """
    Abstract map
    Extended by CubeMap, LatLonMap, and TileMap
    """

    def __init__(self, **kwargs):
        """
        Creates a LatLonMap either from a passed file path or
        passed parameters.
        :param kwargs: path, width, height
        """
        if sum([k in kwargs.keys() for k in ('path', 'arr', 'prototype')]) > 1:
            raise ValueError(
                "Only one of {'path', 'arr', 'prototype'} should be passed")
        if 'path' in kwargs:
            path = kwargs['path']
            self.set_arr(self.load_arr(path))
        elif 'arr' in kwargs:
            self.set_arr(kwargs['arr'])
        # get data from prototype if one was passed
        elif 'prototype' in kwargs:
            p = kwargs.get('prototype')
            width = kwargs.get('width', p.width)
            height = kwargs.get('height', p.height)
            self.clone(p, width, height)
        else:
            width = kwargs.get('width', 2048 * 3)
            height = kwargs.get('height', 2048 * 2)

            data_type = kwargs.get('data_type', np.uint8)
            self.set_arr(self.make_arr(width, height, data_type))

        if not self.width > 0:
            raise ValueError('Invalid width: {}'.format(self.width))
        if not self.height > 0:
            raise ValueError('Invalid height: {}'.format(self.height))

    cpdef np.ndarray load_arr(self, unicode path):
        """
        Loads and returns texture data from passed path.
        :param str path
        :return np.ndarray
        """
        return np.load(path, allow_pickle=False)

    cpdef void save(self, unicode path):
        """
        Saves TextureMap data to passed path.
        :param str path
        """
        np.save(path, self._arr, allow_pickle=False)

    cpdef np.ndarray make_arr(self, width, height, data_type=np.uint8):
        """
        Creates and returns a new array to store TextureMap data in
        :param width int
        :param height int
        :data_type np data type (ex: np.uint8, np.uint16, etc)
        :return np.ndarray
        """
        return np.ndarray((height, width), data_type or np.uint8)

    cpdef void set_arr(self, arr):
        """
        Sets TextureMap data array and updates properties appropriately
        :param arr np.ndarray
        """
        self._arr = arr
        self.height, self.width = arr.shape
        if arr.dtype == np.uint8:
            self.max_value = 255
        elif arr.dtype == np.uint16:
            self.max_value = 65535
        elif arr.dtype == np.uint32:
            self.max_value = 2 ** 32 - 1
        else:
            raise ValueError

    cdef void clone(self, TextureMap p, int width, int height) except *:
        """
        Clones array information from passed prototype, converting
        information to a new format (Cube from LatLon for example)
        if needed.
        :param p TextureMap to clone data from
        :param width int width of new data array
        :param height int height of new data array
        """
        self.set_arr(self.make_arr(width, height, p.data_type))
        IF ASSERTS:
            assert self.height == height, (self.height, height)
            assert self.width == width, (self.width, width)

        cdef vec2 pos
        cdef vec3 vector
        cdef int[2] map_pos
        cdef int v
        for x in range(width):
            for y in range(height):
                # get vector corresponding to position
                pos.x = x
                pos.y = y
                vector = self.vector_from_xy_(pos)
                v = p.v_from_vector_(vector)
                map_pos[0] = x
                map_pos[1] = y
                self.set_xy_(map_pos, v)

    cpdef int v_from_lat_lon(self, pos) except? -1:
        """
        Gets pixel value at passed latitude and longitude.
        :param pos: tuple(lat, lon)
        :return: pos
        """
        raise NotImplementedError(
            '{} does not have method \'v_from_lat_lon\''
            .format(self.__class__.__name__)
        )

    cdef int v_from_lat_lon_(self, latlon pos) except? -1:
        """
        Gets value stored for passed latitude, longitude
        :param pos lat, lon
        :return int
        """
        raise NotImplementedError(
            '{} does not have method \'v_from_lat_lon_\''
            .format(self.__class__.__name__)
        )

    cpdef int v_from_xy(self, pos) except? -1:
        """
        Gets pixel value at passed position on this map.
        :param pos: pos
        :return int
        """
        cdef vec2 pos_ = cp2v_2d(pos)
        if not 0 <= pos_.x < self.width:
            raise ValueError('x value: {} was greater than width: {}'
                             .format(pos_.x, self.width))
        if not 0 <= pos_.y < self.height:
            raise ValueError('y value: {} was greater than height: {}'
                             .format(pos_.y, self.height))
        return self.v_from_xy_(pos_)

    cdef int v_from_xy_(self, vec2 pos) except? -1:
        """
        Gets pixel value at passed position on this map.
        Given a position between indices, will return a weighted
        average of the pixels stored around the passed position.
        :param pos: pos
        :return: int
        """
        if not 0 <= pos.x <= self.width - 1:
            raise ValueError('x ({}) outside valid range'.format(pos.x))
        if not 0 <= pos.y <= self.height - 1:
            raise ValueError('y ({}) outside valid range'.format(pos.x))
        return sample(self._arr, pos)

    cpdef int v_from_rel_xy(self, tuple pos) except? -1:
        """
        Returns value stored for passed x, y position in TextureMap data.
        :param pos x, y int or float
        :return int
        """
        IF ASSERTS:
            assert 0 <= pos[0] < 1, pos[0]
            assert 0 <= pos[1] < 1, pos[1]
        cdef vec2 pos_ = cp2v_2d(pos)
        return self.v_from_rel_xy_(pos_)

    cdef int v_from_rel_xy_(self, vec2 pos) except? -1:
        """
        Gets value stored for passed x, y position in TextureMap data.
        :param pos x, y floats in range (0-1) inclusive
        :return int
        """
        IF ASSERTS:
            assert 0 <= pos.x <= 1, pos.x
            assert 0 <= pos.y <= 1, pos.y
        cdef vec2 abs_pos
        abs_pos.x = pos.x * (self.width - 1)
        abs_pos.y = pos.y * (self.height - 1)
        IF ASSERTS:
            assert 0 <= abs_pos.x <= self.width
            assert 0 <= abs_pos.y <= self.height
        return self.v_from_xy_(abs_pos)

    cdef int v_from_xy_indices_(self, int[2] pos) except? -1:
        """
        Gets value stored in data array at passed x, y indices.
        :param pos int x, int y
        """
        a = pos[0]
        b = pos[1]
        if not 0 <= a <= self.width - 1:
            raise ValueError(
                '{} outside width range 0 - {}'.format(a, self.width - 1))
        if not 0 <= b <= self.height - 1:
            raise ValueError(
                '{} outside height range 0 - {}'.format(b, self.height - 1))

        return self._arr[b][a]

    cpdef int v_from_vector(self, vector) except? -1:
        """
        Gets pixel value identified by vector.
        :param vector: vec3
        :return int
        """
        raise NotImplementedError(
            '{} does not have method \'v_from_vector\''
            .format(self.__class__.__name__)
            )

    cdef int v_from_vector_(self, vec3 vector) except? -1:
        """
        Gets pixel value identified by vector.
        :param vector: vec3
        :return int
        """
        raise NotImplementedError(
            '{} does not have method \'v_from_vector_\''
            .format(self.__class__.__name__)
            )

    cpdef object gradient_from_xy(self, tuple[double] pos):
        """
        Gets gradient of map as a vec2 at passed position.
        :param pos x, y int or floats
        :return mathutils.Vector
        """
        cdef vec2 gr
        cdef vec2 pos_ = cp2v_2d(pos)
        gr = self.gradient_from_xy_(pos_)
        return Vector((gr.x, gr.y))

    @cython.cdivision(True)
    cdef vec2 gradient_from_xy_(self, vec2 pos) except *:
        """
        Gets gradient of map as a vec2 at passed position.
        :param pos x, y doubles
        :return vec2
        """
        cdef int[2] p0, p1, p2, p3  # four sampled positions
        cdef int v0, v1, v2, v3  # four sampled values
        cdef vec2 gr  # gradient
        self._sample_pos(p0, p1, p2, p3, pos)
        if p0[0] == -1:
            # if no fourth quadrant exists for the passed position
            v1 = self.v_from_xy_indices_(p0)
            v2 = self.v_from_xy_indices_(p1)
            v3 = self.v_from_xy_indices_(p2)
            gr.x = float(v3 - v2)
            gr.y = float(v1 - v2)
        else:
            # otherwise, if four positions are available to be sampled..
            v0 = self.v_from_xy_indices_(p0)
            v1 = self.v_from_xy_indices_(p1)
            v2 = self.v_from_xy_indices_(p2)
            v3 = self.v_from_xy_indices_(p3)
            # find gradient
            gr.x = float((v0 + v3) - (v1 + v2)) / 2  # x v of gradient vector
            gr.y = float((v0 + v1) - (v2 + v3)) / 2  # y v of gradient vector
        return gr

    cdef inline void _sample_pos(
            self,
            int[2] p0,
            int[2] p1,
            int[2] p2,
            int[2] p3,
            vec2 pos):
        """
        Gets indices of map that contain information relevant to passed
        double position.
        p3 may be given a value of (-1, -1) indicating that it does not
        exist (for example; if passed position is located where
        geometry folds, such as a cube's corner)
        """
        p2[0] = int(pos.x)
        p2[1] = int(pos.y)
        self.r_px_(p3, p2)
        self.u_px_(p1, p2)
        self.ur_px_(p0, p2)

    cdef inline void r_px_(self, int[2] new_pos, int[2] old_pos):
        """
        Returns position 1 map pixel right of the passed position
        """
        new_pos[0] = old_pos[0] + 1
        new_pos[1] = old_pos[1]
        # no return value, result stored in new_pos mem_view

    cdef inline void u_px_(self, int[2] new_pos, int[2] old_pos):
        """
        Returns position 1 map pixel down of the passed position
        """
        new_pos[0] = old_pos[0]
        new_pos[1] = old_pos[1] + 1
        # no return value, result stored in new_pos mem_view

    cdef inline void ur_px_(self, int[2] new_pos, int[2] old_pos):
        new_pos[0] = old_pos[0] + 1
        new_pos[1] = old_pos[1] + 1
        # no return value, result stored in new_pos mem_view

    cdef double gauss_smooth_xy_(
            self, vec2 pos, double radius, int samples) except -1.:
        raise NotImplementedError(
            '{} does not have method \'gauss_smooth_xy_\''
            .format(self.__class__.__name__)
        )

    cpdef vector_from_xy(self, pos):
        raise NotImplementedError(
            '{} does not have method \'vector_from_xy\''
            .format(self.__class__.__name__)
        )

    cdef vec3 vector_from_xy_(self, vec2 pos) except *:
        """
        From a passed position, sets vector array to x, y, z of
        associated position
        """
        raise NotImplementedError(
            '{} does not have method \'vector_from_xy_\''
            .format(self.__class__.__name__)
        )

    cpdef tuple lat_lon_from_xy(self, tuple pos):
        cdef latlon lat_lon
        cdef vec2 xy_pos = cp2v_2d(pos)
        lat_lon = self.lat_lon_from_xy_(xy_pos)
        return lat_lon

    cdef latlon lat_lon_from_xy_(self, vec2 xy_pos) except *:
        cdef vec3 vector = self.vector_from_xy_(xy_pos)
        cdef latlon lat_lon= lat_lon_from_vector_(vector)
        return lat_lon

    cpdef void set_xy(self, pos, int v):
        cdef int x, y
        x = int(pos[0])
        y = int(pos[1])
        if not 0 <= x < self.width:
            raise ValueError('Width {} outside range 0 - {}'
                             .format(x, self.width))
        if not 0 <= y < self.height:
            raise ValueError('Height {} outside range 0 - {}'
                             .format(y, self.height))
        self._arr[y][x] = v

    cdef void set_xy_(self, int[2] pos, int v):
        self._arr[pos[1]][pos[0]] = v


    @cython.cdivision(True)
    @cython.wraparound(False)
    cpdef void write_png(self, unicode out):
        """
        Writes map as a png to the passed path.
        :param out: path String
        :return: None
        """
        cdef int max = 64
        cdef int x, y, v
        cdef np.ndarray row, out_arr
        if '.' not in out:
            out += '.png'  # adjust out path
        while True:
            # try to get array to print. if a value is outside range,
            # start over and increase max.
            # this lets us see a map that is scaled to fit the t range
            # of a planet.
            restart = False  # reset flag
            out_arr = np.empty_like(self._arr, np.uint8)
            for y in range(self.height):
                row = self._arr[y]
                for x in range(self.width):
                    v = row[x]
                    if v > max:
                        # increase max
                        max = 2 ** int(ceil(log2(v)))
                        # awkwardly use flag to break nested loop
                        restart = True
                        break
                    out_arr[y][x] = v * 255 / max
                if restart:
                    break
            if not restart:
                break

        with open(out, 'wb') as f:
            height = len(out_arr)
            width = len(out_arr[0])
            w = png.Writer(width, height, greyscale=True)
            w.write(f, out_arr)


    @property
    def data_type(self):
        return self._arr.dtype


cdef class CubeMap(TextureMap):
    """
    A cube map is a more efficient way to store data about a sphere,
    that also involves less stretching than a LatLonMap
    """

    def __init__(self, **kwargs):
        self.tile_maps = []
        super().__init__(**kwargs)

    cpdef np.ndarray make_arr(self, width, height, data_type=np.uint8):
        arr = super(CubeMap, self).make_arr(width, height, data_type)

        # create tiles
        for i in range(6):
            tile = CubeSide(i, arr)
            tile.cube = self
            # uppermost tile has no parent.
            self.tile_maps.append(tile)

        return arr

    cpdef void set_arr(self, arr):
        super(CubeMap, self).set_arr(arr)
        self.tile_height = int(self.height / 2)
        self.tile_width = int(self.width / 3)
        self.two_thirds_width = self.tile_width * 2  # used in some methods

    cpdef int v_from_lat_lon(self, pos) except? -1:
        """
        Gets pixel value at passed latitude and longitude.
        :param pos: tuple(lat, lon)
        :return: pos
        """
        tile = self.tile_from_lat_lon(pos)
        IF ASSERTS:
            assert isinstance(tile, TileMap)
        v = tile.v_from_lat_lon(pos)
        return v

    cpdef int v_from_vector(self, vector) except? -1:
        """
        Gets pixel value at passed position on this map.
        :param vector: Vector (x, y, z)
        :return:
        """
        return self.v_from_vector_(cp2v_3d(vector))

    cdef int v_from_vector_(self, vec3 vector) except? -1:
        cdef latlon lat_lon = lat_lon_from_vector_(vector)
        cdef TileMap tile = self.tile_from_lat_lon_(lat_lon)
        return tile.v_from_vector_(vector)

    cpdef int v_from_xy(self, pos, tile=None) except? -1:
        """
        Gets pixel value identified by vector.
        :param pos: map x, y
        :param tile: tile index
        :return: value
        """
        if tile is not None:
            return self.tile_maps[tile].v_from_xy(pos)
        else:
            x, y = pos
            return self.v_from_xy(pos)

    cpdef CubeSide get_tile(self, int index):
        """
        gets the tile of the passed index
        :param index: int
        :return: TileMap
        """
        return self.tile_maps[index]

    cpdef CubeSide tile_from_vector(self, vector):
        """
        Gets the tile on which the value identified by the passed vector
        is located.
        :param pos tuple(latitude, longitude)
        :return integer in range 0, 6
        """
        return self.tile_from_vector_(cp2v_3d(vector))

    cdef CubeSide tile_from_vector_(self, vec3 vector):
        return self.get_tile(self.tile_index_from_vector_(vector))

    cdef int tile_index_from_vector_(self, vec3 vector):
        # prevent repeated calls to fabs and vector
        cdef double x, y, z, abs_x, abs_y, abs_z
        x = vector.x
        y = vector.y
        z = vector.z
        abs_x = fabs(x)  # get absolute from float
        abs_y = fabs(y)
        abs_z = fabs(z)

        # see if vector can be quickly placed in one tile
        if abs_x >= abs_y and abs_x >= abs_z:
            if x > 0:
                return 0
            else:
                return 2
        elif abs_y >= abs_x and abs_y >= abs_z:
            if y > 0:
                return 3
            else:
                return 1
        elif abs_z >= abs_x and abs_z >= abs_y:
            if z > 0:
                return 4
            else:
                return 5

    cpdef CubeSide tile_from_lat_lon(self, lat_lon):
        """
        Gets the tile on which the passed lat, lon value is located.
        :param pos tuple(latitude, longitude)
        :return integer in range 0, 6
        """
        cdef latlon lat_lon_ = cp2ll(lat_lon)
        if not MIN_LAT <= lat_lon_.lat <= MAX_LAT:
            raise ValueError('latitude outside range: {}'.format(lat_lon_.lat))
        if not MIN_LON <= lat_lon_.lon <= MAX_LON:
            raise ValueError('longitude outside range: {}'
                             .format(lat_lon_.lon))
        return self.tile_from_lat_lon_(lat_lon_)

    cdef CubeSide tile_from_lat_lon_(self, latlon lat_lon):
        IF ASSERTS:
            assert MIN_LAT <= lat_lon.lat <= MAX_LAT, lat_lon
            assert MIN_LON <= lat_lon.lon <= MAX_LON, lat_lon
        cdef vec3 vector = vector_from_lat_lon_(lat_lon)
        return self.tile_from_vector_(vector)

    cpdef CubeSide tile_from_xy(self, pos):
        return self.tile_from_xy_(cp2v_2d(pos))

    cdef CubeSide tile_from_xy_(self, vec2 pos):
        return self.tile_maps[self.tile_index_from_xy_(pos)]

    cpdef short tile_index_from_xy(self, pos):
        return self.tile_index_from_xy_(cp2v_2d(pos))

    @cython.cdivision(True)
    cdef short tile_index_from_xy_(self, vec2 pos):
        """
        Private method for finding the index corresponding to
        a passed position.
        """
        if not 0 <= pos.x < self.width:
            raise ValueError(
                'x {} outside range: 0-{}'.format(pos.x, self.width))
        if not 0 <= pos.y < self.height:
            raise ValueError(
                'y {} outside range: 0-{}'.format(pos.y, self.height))
        if pos.x < self.tile_width:
            i = 0
        elif pos.x < self.two_thirds_width:
            i = 1
        else:
            i = 2
        if pos.y >= self.height / 2:
            i += 3
        return i

    @cython.cdivision(True)
    cdef double gauss_smooth_xy_(
            self, vec2 pos, double radius, int samples) except -1.:
        # Should never return a negative normally.
        """
        Gets the gaussian smoothed value for the passed position,
        using the passed radius and number of sample positions
        Passed radius is in pixels
        """
        cdef vec3 pos_vector  # vector identifying passed position
        cdef vec3 point_vector  # vector identifying sampled point
        cdef vec3 polar_vector = mu.vec3New(0, 0, 1)
        cdef mat3x3 rotation  # rotation matrix
        if samples < 1:
            raise ValueError('Samples must be >= 1. Got: {}'.format(samples))
        pos_vector = self.vector_from_xy_(pos)
        mu.rotation_difference(rotation, polar_vector, pos_vector)
        cdef double sum = 0.
        cdef double v
        cdef latlon ll
        for i in range(samples):
            ll.lon = i / samples * TAU - PI
            IF ASSERTS:
                assert MIN_LON <= ll.lon <= MAX_LON, ll.lon
            for j in range(samples):
                ll.lat = MAX_LAT - MAX_LAT / self.height / samples * radius * j
                IF ASSERTS:
                    assert MIN_LAT <= ll.lat <= MAX_LAT, ll.lat
                point_vector = vector_from_lat_lon_(ll)
                point_vector = mu.mat3x3MultiplyVector(rotation, point_vector)
                IF ASSERTS:
                     # check that values have been set
                    assert point_vector.x != 0 or \
                        point_vector.y != 0 or \
                        point_vector.z != 0, \
                        'v: {}, ll: {}'.format(point_vector, ll)
                v = self.v_from_vector_(point_vector)
                IF ASSERTS:
                    assert v >= 0
                sum += v
        IF ASSERTS:
            assert sum >= 0, sum
        sum /= samples * samples
        IF ASSERTS:
            assert sum >= 0, "sum: " + str(sum)
        return sum

    @cython.wraparound(False)
    cpdef vector_from_xy(self, pos):
        cdef vec3 vector_ = self.vector_from_xy_(cp2v_2d(pos))
        return Vector((vector_.x, vector_.y, vector_.z))

    @cython.wraparound(False)
    cdef vec3 vector_from_xy_(self, vec2 pos) except *:
        cdef vec2 tile_ref_pos
        cdef vec2 rel_pos

        IF ASSERTS:
            assert 0 <= pos.x <= self.width - 1, pos.x
            assert 0 <= pos.y <= self.height - 1, pos.y

        tile_index = self.tile_index_from_xy_(pos)
        tile_ref_pos = self.reference_position_(tile_index)
        rel_pos.x = pos.x - tile_ref_pos.x
        rel_pos.y = pos.y - tile_ref_pos.y
        return self.vector_from_tile_xy_(tile_index, rel_pos)

    @cython.cdivision(True)
    @cython.wraparound(False)
    cdef vec3 vector_from_tile_xy_(self, int tile_index, vec2 pos) except *:
        """
        Gets vector from xy position of passed face tile
        """
        cdef vec3 vector
        a_index, b_index = pos.x, pos.y
        if not 0 <= a_index < self.tile_width:
            raise ValueError('Passed x {} was outside range 0-{}'
                             .format(a_index, self.tile_width))
        if not 0 <= b_index < self.tile_height:
            raise ValueError('Passed y {} was outside range 0-{}'
                             .format(b_index, self.tile_height))
        min_rel_x = -1
        min_rel_y = -1
        max_rel_x = 1
        max_rel_y = 1
        # flip values if needed
        if min_rel_x > max_rel_x:
            min_rel_x, max_rel_x = max_rel_x, min_rel_x
        if min_rel_y > max_rel_y:
            min_rel_y, max_rel_y = max_rel_y, min_rel_y
        a_range = max_rel_x - min_rel_x
        b_range = max_rel_y - min_rel_y
        # get relative positions from map indices
        map_rel_x = a_index / self.tile_width
        map_rel_y = b_index / self.tile_height
        a = map_rel_x * a_range + min_rel_x
        b = map_rel_y * b_range + min_rel_y
        # assert -1 <= a <= 1, a
        # assert -1 <= b <= 1, b
        if tile_index == 0:
            vector.x, vector.y, vector.z = 1, a, b
        elif tile_index == 1:
            vector.x, vector.y, vector.z = a, -1, b
        elif tile_index == 2:
            vector.x, vector.y, vector.z = -1, -a, b
        elif tile_index == 3:
            vector.x, vector.y, vector.z = -a, 1, b
        elif tile_index == 4:
            vector.x, vector.y, vector.z = a, b, 1
        elif tile_index == 5:
            vector.x, vector.y, vector.z = -a, b, -1
        else:
            raise ValueError('Invalid face index: {}'.format(tile_index))
        return vector

    cpdef get_reference_position(self, tile_index):
        if not 0 <= tile_index < 6:  # if outside valid range
            raise IndexError(tile_index)
        elif tile_index < 3:
            return tile_index * self.tile_width, 0
        elif tile_index < 6:
            return (tile_index - 3) * self.tile_width, self.tile_height

    cdef vec2 reference_position_(self, int tile_index) except *:
        cdef vec2 ref_pos
        if tile_index < 3:
            ref_pos.x =  tile_index * self.tile_width
            ref_pos.y = 0
        elif tile_index < 6:
            ref_pos.x = (tile_index - 3) * self.tile_width
            ref_pos.y = self.tile_height

        IF ASSERTS:
            assert 0 <= ref_pos.x <= self.width * 2 / 3, ref_pos
            assert 0 <= ref_pos.y <= self.height / 2, ref_pos
        return ref_pos

cdef class LatLonMap(TextureMap):
    """
    Stores a latitude-longitude texture map
    """

    def __init__(self, **kwargs):
        """
        Creates a LatLonMap either from a passed file path or
        passed parameters.
        :param kwargs: path, width, height
        """
        super().__init__(**kwargs)

    cpdef int v_from_lat_lon(self, pos) except? -1:
        """
        Gets pixel value at passed latitude and longitude.
        :param pos: tuple(lat, lon)
        :return: pos
        """
        xy_pos = self.lat_lon_to_xy(pos)
        v = self.v_from_xy(xy_pos)
        return v

    cdef int v_from_lat_lon_(self, latlon pos) except? -1:
        cdef vec2 xy_pos = self.lat_lon_to_xy_(pos)
        return self.v_from_xy_(xy_pos)

    cpdef int v_from_vector(self, vector) except? -1:
        """
        Gets pixel value at passed position on this map.
        :param vector: Vector (x, y, z)
        :return: PixelValue
        """
        return self.v_from_vector_(cp2v_3d(vector))

    cdef int v_from_vector_(self, vec3 vector) except? -1:
        cdef latlon lat_lon = lat_lon_from_vector_(vector)
        return self.v_from_lat_lon_(lat_lon)

    cpdef vector_from_xy(self, pos):
        return vector_from_lat_lon(self.xy_to_lat_lon(pos))

    @cython.wraparound(False)
    cpdef lat_lon_to_xy(self, lat_lon):
        assert MIN_LON <= lat_lon[1] <= MAX_LON
        assert MIN_LAT <= lat_lon[0] <= MAX_LAT
        cdef vec2 xy_pos = self.lat_lon_to_xy_(cp2ll(lat_lon))
        return xy_pos.x, xy_pos.y

    @cython.cdivision(True)
    @cython.wraparound(False)
    cdef vec2 lat_lon_to_xy_(self, latlon lat_lon):
        cdef vec2 xy_pos
        cdef double x, y
        lat = lat_lon.lat
        lon = lat_lon.lon
        x_ratio = lon / LON_RANGE + 0.5  # x as ratio of 0 to 1
        y_ratio = lat / LAT_RANGE + 0.5  # y as ratio from 0 to 1
        x = x_ratio * (self.width - 1)  # max index is 1 less than size
        y = y_ratio * (self.height - 1)  # max index is 1 less than size
        # correct floating point errors that take values outside range
        if x > self.width - 1:
            # if floating point error has taken x over width, correct it.
            # assert x - self.width - 1 < 0.01, x  # if larger, something's wrong
            x = self.width - 1
        elif x < 0:
            # assert x > -0.01, x
            x = 0
        if y > self.height - 1:
            # assert y - self.height - 1 < 0.01, y
            y = self.height - 1
        elif y < 0:
            # assert y > -0.01, y
            y = 0
        # store result
        xy_pos.x = x
        xy_pos.y = y
        return xy_pos

    @cython.cdivision(True)
    cpdef xy_to_lat_lon(self, pos):
        x, y = pos
        relative_x = x / self.width
        relative_y = y / self.height
        lon = (relative_x - 0.5) * MAX_LON
        lat = (relative_y - 0.5) * MAX_LAT
        return lat, lon


cdef class TileMap(TextureMap):
    """
    Stores a square texture map that is mapped to a portion of a sphere.
    """

    def __init__(self, p1, p2, cube_face, **kwargs):
        """
        Creates TileMap from upper left and lower right corner position
        relative to the face of the cube-map.
        Ex: (0,0) is center, (1,1) is lower right, (-1,1) is upper right
        Cube face is the face of the cube on which this tile is located.
        :param p1: tuple(x, y)
        :param p2: tuple(x, y)
        """
        super().__init__(**kwargs)
        self.cube_face = cube_face
        self.p1 = p1
        self.p2 = p2
        self.parent = None

    cpdef int v_from_lat_lon(self, pos) except? -1:
        """
        Gets pixel value at passed latitude and longitude.
        :param pos: tuple(lat, lon)
        :return: PixelValue
        """
        vector = vector_from_lat_lon(pos)
        value = self.v_from_vector(vector)
        return value

    cpdef int v_from_vector(self, vector) except? -1:
        """
        Gets pixel value at passed position on this map.
        :param vector: Vector (x, y, z)
        :return: PixelValue
        """
        return self.v_from_vector_(cp2v_3d(vector))

    @cython.cdivision(True)
    @cython.wraparound(False)
    cdef int v_from_vector_(self, vec3 vector) except? -1:
        """
        Gets value associated with passed vector.
        Unlike above version, vector is a memory view, not an object.
        """
        cdef double x, y, z
        cdef vec2 pos
        x = vector.x
        y = vector.y
        z = vector.z
        if x == 0. and y == 0. and z == 0.:
            raise ValueError('Passed vector was (0, 0, 0)')
        if self.cube_face == 0:
            a = y / x
            b = z / x
        elif self.cube_face == 1:
            a = x / -y
            b = z / -y
        elif self.cube_face == 2:
            a = y / x
            b = z / -x
        elif self.cube_face == 3:
            a = x / -y
            b = z / y
        elif self.cube_face == 4:
            a = x / z
            b = y / z
        elif self.cube_face == 5:
            a = x / z
            b = y / -z
        else:
            raise IndexError(self.cube_face)
        # correct minor floating point errors (~1e-12 or smaller)
        if a < -1:
            IF ASSERTS:
                assert a + 1 > -1e-12, a
            a = -1
        if a > 1:
            IF ASSERTS:
                assert a - 1 < 1e-12, a
            a = 1
        if b < -1:
            IF ASSERTS:
                assert b + 1 > -1e-12, b
            b = -1
        if b > 1:
            IF ASSERTS:
                assert b - 1 < 1e-12, b
            b = 1
        IF ASSERTS:
            assert -1 <= a <= 1 and -1 <= b <= 1, \
                'position outside expected range: ({},{}), tile: {}' \
                .format(a, b, self.cube_face)
        # convert a and b from (-1,-1) range to (0,1)
        pos.x = a / 2 + 0.5
        pos.y = b / 2 + 0.5
        IF ASSERTS:
            assert 0 <= pos.x <= 1, \
                'a value: {}, tile: {}'.format(pos.x, self.cube_face)
            assert 0 <= pos.y <= 1, \
                'b value: {}, tile: {}'.format(pos.y, self.cube_face)
        v = self.v_from_rel_xy_(pos)
        IF ASSERTS:
            assert v >= 0
        return v

    # getters of map indices from passed vector
    # these methods are intended to retrieve positions that will be
    # sampled in order to determine the value of the map at a position
    # that does not perfectly align with any one set of indices.

    cpdef get_sub_tile(self, p1, p2):
        """
        Gets sub-tile of this tile map
        :param p1: lower left corner
        :param p2: upper right corner
        :return: TileMap
        """
        # todo

    @cython.wraparound(False)
    cpdef vector_from_xy(self, pos):
        cdef vec3 vector
        cdef vec2 pos_
        # vector = np.ndarray((3), np.double)
        pos_.x, pos_.y = pos
        vector = self.vector_from_xy_(pos_)
        return Vector(vector)

    @cython.cdivision(True)
    @cython.wraparound(False)
    cdef vec3 vector_from_xy_(self, vec2 pos) except *:
        cdef vec3 vector
        a_index, b_index = pos.x, pos.y
        if not 0 <= a_index <= self.width - 1:
            raise ValueError('Passed x {} was outside range 0-{}'
                             .format(a_index, self.width))
        if not 0 <= b_index <= self.height - 1:
            raise ValueError('Passed x {} was outside range 0-{}'
                             .format(b_index, self.height))
        min_rel_x, min_rel_y = self.p1
        max_rel_x, max_rel_y = self.p2
        # flip values if needed
        if min_rel_x > max_rel_x:
            min_rel_x, max_rel_x = max_rel_x, min_rel_x
        if min_rel_y > max_rel_y:
            min_rel_y, max_rel_y = max_rel_y, min_rel_y
        a_range = max_rel_x - min_rel_x
        b_range = max_rel_y - min_rel_y
        # get relative positions from map indices
        map_rel_x = a_index / self.width
        map_rel_y = b_index / self.height
        a = map_rel_x * a_range + min_rel_x
        b = map_rel_y * b_range + min_rel_y
        # assert -1 <= a <= 1, a
        # assert -1 <= b <= 1, b
        if self.cube_face == 0:
            vector.x, vector.y, vector.z = 1, a, b
        elif self.cube_face == 1:
            vector.x, vector.y, vector.z = a, -1, b
        elif self.cube_face == 2:
            vector.x, vector.y, vector.z = -1, -a, b
        elif self.cube_face == 3:
            vector.x, vector.y, vector.z = -a, 1, b
        elif self.cube_face == 4:
            vector.x, vector.y, vector.z = a, b, 1
        elif self.cube_face == 5:
            vector.x, vector.y, vector.z = -a, b, -1
        else:
            raise ValueError('Invalid face index: {}'.format(self.cube_face))
        return vector


cdef class CubeSide(TileMap):

    def __init__(self, cube_face, cube_arr):
        self.cube_face = cube_face
        self._arr = cube_arr
        self.p1 = -1, -1
        self.p2 = 1, 1
        self.parent = None

        cube_map_shape = self._arr.shape
        self.height = int(cube_map_shape[0] / 2)
        self.width = int(cube_map_shape[1] / 3)
        self._ref_pos = self._find_reference_position()
        if not self.height == cube_map_shape[0] / 2:
            raise ValueError("height: {} is not evenly divisible into 2 parts"
                             .format(self.height))
        if not self.width == cube_map_shape[1] / 3:
            raise ValueError("width: {} is not evenly divisible into 3 parts"
                             .format(self.width))

    cpdef int v_from_xy(self, pos) except? -1:
        """
        Gets pixel value identified by vector.
        :param pos: x, y floats or Vector indicating position relative
                    to tile origin to access.
        :return: PixelValue
        """
        return self.v_from_xy_(cp2v_2d(pos))

    @cython.wraparound(False)
    cdef int v_from_xy_(self, vec2 pos) except? -1:
        """
        Gets pixel value identified by vector.
        :param pos: x, y doubles indicating position relative to tile
                    origin to access.
        :return: PixelValue
        """
        if not 0 <= pos.x <= self.width - 1:
            # correct minor floating point error
            if -1e-12 < pos.x < 0:
                pos.x = 0
            elif 1 < pos.x < self.width - 1 + 1e-12:
                pos.x = self.width - 1
            raise ValueError('x ({}) outside valid range'.format(pos.x))
        if not 0 <= pos.y <= self.height - 1:
            # correct minor floating point error
            if -1e-12 < pos.y < 0:
                pos.y = 0
            elif 1 < pos.y < self.height - 1 + 1e-12:
                pos.x = self.height - 1
            raise ValueError('y ({}) outside valid range'.format(pos.y))
        cdef vec2 viewed_map_xy
        x = pos.x
        y = pos.y
        # modify x and y to be relative to the tile's origin
        # for this cube side
        viewed_map_xy.x = x + self._ref_pos.x
        viewed_map_xy.y = y + self._ref_pos.y
        return sample(self._arr, viewed_map_xy)

    cdef vec2 _find_reference_position(self):
        IF ASSERTS:
            assert 0 <= self.cube_face < 6, self.cube_face
        if self.cube_face < 3:
            return mu.vec2New(self.cube_face * self.width, 0.)
        elif self.cube_face < 6:
            return mu.vec2New((self.cube_face - 3) * self.width, self.height)

    @property
    def reference_position(self):
        return self._ref_pos.x, self._ref_pos.y


cpdef vector_from_lat_lon(pos):
    """
    Converts a lat lon position into a Vector
    :param pos: tuple(lat, lon)
    :return: Vector
    """
    cdef vec3 vector_ = vector_from_lat_lon_(cp2ll(pos))
    return Vector((vector_.x, vector_.y, vector_.z))

IF ASSERTS:
    cdef vec3 vector_from_lat_lon_(latlon lat_lon) except *:
        cdef vec3 vector
        cdef double lat = lat_lon.lat, lon = lat_lon.lon

        assert MIN_LAT <= lat <= MAX_LAT + 1e-6, 'bad lat: {}'.format(lat_lon)
        assert MIN_LON <= lon <= MAX_LON + 1e-6, 'bad lon: {}'.format(lat_lon)

        vector.x = cos(lat) * cos(lon)
        vector.y = cos(lat) * sin(lon)
        vector.z = sin(lat)
        return vector
ELSE:
    cdef vec3 vector_from_lat_lon_(latlon lat_lon):
        cdef vec3 vector
        cdef double lat = lat_lon.lat, lon = lat_lon.lon

        vector.x = cos(lat) * cos(lon)
        vector.y = cos(lat) * sin(lon)
        vector.z = sin(lat)
        return vector

cpdef lat_lon_from_vector(vector):
    vector = Vector(vector)
    lat = atan2(vector.z, sqrt(pow(vector.x, 2) + pow(vector.y, 2)))
    lon = atan2(vector.y, vector.x)
    return lat, lon


IF ASSERTS:
    @cython.wraparound(False)
    cdef latlon lat_lon_from_vector_(vec3 vector) except *:
        assert not isnan(vector.x), vector
        assert not isnan(vector.y), vector
        assert not isnan(vector.z), vector
        assert vector.x != 0 or vector.y != 0 or vector.z != 0, vector

        cdef latlon lat_lon
        x = vector.x
        y = vector.y
        z = vector.z
        lat_lon.lat = atan2(z, sqrt(pow(x, 2) + pow(y, 2)))
        lat_lon.lon = atan2(y, x)

        assert MIN_LAT <= lat_lon.lat <= MAX_LAT, lat_lon
        assert MIN_LON <= lat_lon.lon <= MAX_LON, lat_lon
        return lat_lon
ELSE:
    @cython.wraparound(False)
    cdef latlon lat_lon_from_vector_(vec3 vector):
        cdef latlon lat_lon
        x = vector.x
        y = vector.y
        z = vector.z
        lat_lon.lat = atan2(z, sqrt(pow(x, 2) + pow(y, 2)))
        lat_lon.lon = atan2(y, x)
        return lat_lon


cdef int sample(np.ndarray arr, vec2 pos) except? -1:
    """
    Samples passed array at passed position.

    Passed x and y positions may be values other than an integer,
    in which case the returned value will be a weighted average of
    the surrounding positions in the array.
    :param arr np.ndarray
    :param pos vec2 indicating x, y position at which to sample array.
    :return int
    """
    cdef int a_index, b_index, vf
    cdef int[2] p0, p1, p2, p3
    cdef float left0, left1, right0, right1, left, right
    cdef float a_mod, b_mod

    a = pos.x
    b = pos.y
    a_index = int(a)
    b_index = int(b)
    a_mod = a % 1
    b_mod = b % 1

    if a_mod and b_mod:
        # if all 4 pixels are to be used
        p2[0] = a_index
        p2[1] = b_index
        p3[0] = p2[0] + 1
        p3[1] = p2[1]
        p1[0] = p2[0]
        p1[1] = p2[1] + 1
        p0[0] = p2[0] + 1
        p0[1] = p2[1] + 1

        left0 = arr[p2[1]][p2[0]]
        left1 = arr[p1[1]][p1[0]]
        right0 = arr[p3[1]][p3[0]]
        # right1 is accessed only if it exists.

        IF ASSERTS:
            assert p0[0] >= 0 or p0[0] == -1, p0[0]
            assert p0[1] >= 0 or p0[1] == -1, p0[1]

        if p0[0] != -1:
            # if p0 exists
            right1 = arr[p0[1]][p0[0]]
        else:
            # if no fourth position exists,
            # for example: the position is on a corner
            right1 = (right0 + left1) / 2

        left0 = left1 * b_mod + left0 * (1 - b_mod)
        right0 = right1 * b_mod + right0 * (1 - b_mod)
        vf = int(right0 * a_mod + left0 * (1 - a_mod))
    elif a_mod:  # if a_mod > 0 and b_mod == 0:
        # if only one row
        p2[0] = a_index
        p2[1] = b_index
        p3[0] = p2[0] + 1
        p3[1] = p2[1]
        left0 = arr[p2[1]][p2[0]]
        right0 = arr[p3[1]][p3[0]]
        vf = int(right0 * a_mod + left0 * (1 - a_mod))
    elif b_mod:  # if b_mod > 0 and a_mod == 0:
        # if only one column
        p2[0] = a_index
        p2[1] = b_index
        p1[0] = p2[0]  # get pixel above base (p2) pixel
        p1[1] = p2[1] + 1
        left0 = arr[p2[1]][p2[0]]
        left1 = arr[p1[1]][p1[1]]
        vf = int(left1 * b_mod + left0 * (1 - b_mod))
    else:  # both a_mod and b_mod are 0.:
        # if both passed values are whole numbers, just get the
        # corresponding value
        vf = int(arr[b_index][a_index])  # may store shorts, etc

    return vf