# cython: infer_types=True, boundscheck=False, nonecheck=False, language_level=3,

"""
Maps for storing data about a map for a sphere.
"""

include "macro.pxi"

import numpy as np
import png
import itertools as itr

cimport numpy as np
cimport cython


from mathutils import Vector

from math import radians
from libc.math cimport cos, sin, atan2, sqrt, pow

DEF PI = 3.1415926535897932384626433832795028841971
DEF QTR_PI = 0.78539816339

DEF MIN_LAT = -1.57079632679
DEF MAX_LAT = 1.57079632679
DEF LAT_RANGE = PI
DEF MIN_LON = -PI
DEF MAX_LON = PI
DEF LON_RANGE = 6.28318530718


cdef class TextureMap:
    """
    Abstract map
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

        assert self.width, self.width
        assert self.height, self.height

    cpdef np.ndarray load_arr(self, unicode path):
        return np.load(path, allow_pickle=False)

    cpdef void save(self, unicode path):
        np.save(path, self._arr, allow_pickle=False)

    cpdef np.ndarray make_arr(self, width, height, data_type=np.uint8):
        return np.ndarray((height, width), data_type or np.uint8)

    cpdef void set_arr(self, arr):
        self._arr = arr
        self.height, self.width = arr.shape
        if arr.dtype == np.uint8:
            self.max_value = 255
        elif arr.dtype == np.uint16:
            self.max_value = 65535
        else:
            raise ValueError

    cdef void clone(self, TextureMap p, int width, int height):
        """
        Clones array information from passed prototype, converting
        information to a new format (Cube from LatLon for example)
        if needed.
        """
        self.set_arr(self.make_arr(width, height, p.data_type))
        assert self.height == height, (self.height, height)
        assert self.width == width, (self.width, width)

        cdef double[2] pos
        cdef double[3] vector
        cdef int[2] map_pos
        cdef int v
        for x in range(width):
            for y in range(height):
                # get vector corresponding to position
                pos[0] = x
                pos[1] = y
                self.vector_from_xy_(vector, pos)
                v = p.v_from_vector_(vector)
                map_pos[0] = x
                map_pos[1] = y
                self.set_xy_(map_pos, v)

    cpdef int v_from_lat_lon(self, pos):
        """
        Gets pixel value at passed latitude and longitude.
        :param pos: tuple(lat, lon)
        :return: pos
        """
        raise NotImplementedError

    cdef int v_from_lat_lon_(self, double[2] pos):
        raise NotImplementedError

    cpdef int v_from_xy(self, pos):
        """
        Gets pixel value at passed position on this map.
        :param pos: pos
        :return:
        """
        cdef double[2] pos_
        cp2a_2d(pos, pos_)
        if not 0 <= pos_[0] < self.width:
            raise ValueError('x value: {} was greater than width: {}'
                             .format(pos_[0], self.width))
        if not 0 <= pos_[1] < self.height:
            raise ValueError('y value: {} was greater than height: {}'
                             .format(pos_[1], self.height))
        return self.v_from_xy_(pos_)

    cdef int v_from_xy_(self, double[2] pos):
        """
        Gets pixel value at passed position on this map.
        :param pos: pos
        :return: int
        """
        cdef int a0, a1, b0, b1, vf
        cdef float left0, left1, right0, right1, left, right, v0, v1
        cdef float a_mod, b_mod

        a = pos[0]
        b = pos[1]
        if not 0 <= a <= self.width - 1:
            raise ValueError(
                '{} outside width range 0 - {}'.format(a, self.width - 1))
        if not 0 <= b <= self.height - 1:
            raise ValueError(
                '{} outside height range 0 - {}'.format(b, self.height - 1))
        a_mod = a % 1
        b_mod = b % 1
        if a_mod == 0.:
            a0 = int(a)
            a1 = -1
        else:
            a0 = int(a)
            a1 = int(a) + 1
            # assert a1 < self.width
        if b_mod == 0.:
            b0 = int(b)
            b1 = -1
        else:
            b0 = int(b)
            b1 = int(b) + 1
            # assert b1 < self.height
        # assert a0 < self.width
        # assert b0 < self.height

        if b1 == -1 and a1 == -1:
            # if both passed values are whole numbers, just get the
            # corresponding value
            vf = int(self._arr[b0][a0])  # may store shorts, uint16, etc
        elif a1 == -1 and b1:
            # if only one column
            v0 = self._arr[b1][a0]
            v1 = self._arr[b0][a0]
            vf = int(v1 * b_mod + v0 * (1 - b_mod))
        elif b1 == -1 and a1:
            # if only one row
            v0 = self._arr[b0][a0]
            v1 = self._arr[b0][a1]
            vf = int(v1 * a_mod + v0 * (1 - a_mod))
        else:
            # if all 4 pixels are to be used
            left0 = self._arr[b0][a0]
            left1 = self._arr[b1][a0]
            right0 = self._arr[b0][a1]
            right1 = self._arr[b1][a1]
            left = left1 * b_mod + left0 * (1 - b_mod)
            right = right1 * b_mod + right0 * (1 - b_mod)
            vf = int(right * a_mod + left * (1 - a_mod))
        return vf

    cpdef int v_from_rel_xy(self, tuple pos):
        cdef double[2] pos_
        cp2a_2d(pos, pos_)
        return self.v_from_rel_xy_(pos_)

    cdef int v_from_rel_xy_(self, double[2] pos):
        cdef double[2] abs_pos
        abs_pos[0] = pos[0] * self.width
        abs_pos[1] = pos[1] * self.height
        return self.v_from_xy_(abs_pos)

    cdef int v_from_xy_indices_(self, int[2] pos):
        a = pos[0]
        b = pos[1]
        if not 0 <= a <= self.width - 1:
            raise ValueError(
                '{} outside width range 0 - {}'.format(a, self.width - 1))
        if not 0 <= b <= self.height - 1:
            raise ValueError(
                '{} outside height range 0 - {}'.format(b, self.height - 1))

        return self._arr[b][a]

    cpdef int v_from_vector(self, vector):
        """
        Gets pixel value identified by vector.
        :param vector:
        :return:
        """
        raise NotImplementedError

    cdef int v_from_vector_(self, double[3] vector):
        raise NotImplementedError

    cpdef object gradient_from_xy(self, tuple[double] pos):
        cdef double[2] gr
        cdef double[2] pos_
        cp2a_2d(pos, pos_)
        self.gradient_from_xy_(gr, pos_)
        return Vector((gr[0], gr[1]))

    @cython.cdivision(True)
    cdef void gradient_from_xy_(self, double[2] gr, double[2] pos):
        cdef int[2] p0, p1, p2, p3
        cdef int v0, v1, v2, v3
        self._sample_pos(p0, p1, p2, p3, pos)
        if p0[0] == -1:
            # if no fourth quadrant exists for the passed position
            v1 = self.v_from_xy_indices_(p0)
            v2 = self.v_from_xy_indices_(p1)
            v3 = self.v_from_xy_indices_(p2)
            gr[0] = float(v3 - v2)
            gr[1] = float(v1 - v2)
        else:
            # otherwise, if four positions are available to be sampled..
            v0 = self.v_from_xy_indices_(p0)
            v1 = self.v_from_xy_indices_(p1)
            v2 = self.v_from_xy_indices_(p2)
            v3 = self.v_from_xy_indices_(p3)
            # find gradient
            gr[0] = float((v0 + v3) - (v1 + v2)) / 2  # x v of gradient vector
            gr[1] = float((v0 + v1) - (v2 + v3)) / 2  # y v of gradient vector
            # Does not return anything, result is stored in passed gr arr.
        
    cdef inline void _sample_pos(
            self,
            int[2] p0,
            int[2] p1,
            int[2] p2,
            int[2] p3,
            double[2] pos):
        """
        Gets indices of map that contain information relevant to passed
        double position.
        p3 may be given a value of (-1, -1) indicating that it does not
        exist (for example; if passed position is located where
        geometry folds, such as a cube's corner)
        """
        p2[0] = int(pos[0])
        p2[1] = int(pos[1])
        self.r_px_(p3, p2)
        self.u_px_(p1, p2)
        self.ur_px_(p0, p2)


    cdef void r_px_(self, int[2] new_pos, int[2] old_pos):
        """
        Returns position 1 map pixel right of the passed position
        """
        raise NotImplementedError

    cdef void u_px_(self, int[2] new_pos, int[2] old_pos):
        """
        Returns position 1 map pixel down of the passed position
        """
        raise NotImplementedError

    cdef void ur_px_(self, int[2] new_pos, int[2] old_pos):
        raise NotImplementedError

    cpdef vector_from_xy(self, pos):
        raise NotImplementedError

    cdef void vector_from_xy_(self, double[3] vector, double[2] pos):
        """
        From a passed position, sets vector array to x, y, z of
        associated position
        """
        raise NotImplementedError

    cpdef tuple lat_lon_from_xy(self, tuple pos):
        cdef double[2] lat_lon
        cdef double[2] xy_pos
        cp2a_2d(pos, xy_pos)
        self.lat_lon_from_xy_(lat_lon, xy_pos)
        return lat_lon

    cdef void lat_lon_from_xy_(self, double[2] lat_lon, double[2] xy_pos):
        cdef double[3] vector
        self.vector_from_xy_(vector, xy_pos)
        lat_lon_from_vector_(lat_lon, vector)
        # does not return a value, instead stores result in lat_lon.

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
    cpdef void write_png(self, out):
        """
        Writes map as a png to the passed path
        :param out: path String
        :return: None
        """
        cdef np.ndarray out_arr, row
        if '.' not in out:
            out += '.png'
        assert isinstance(self._arr, np.ndarray)
        if self._arr.dtype == np.uint8:
            out_arr = self._arr
        elif self._arr.dtype == np.uint16:
            out_arr = np.empty_like(self._arr, np.uint8)
            for y in range(self.height):
                row = self._arr[y]
                for x in range(self.width):
                    v = row[x]
                    out_arr[y][x] = v / 256
        else:
            raise TypeError(
                'Cannot display data type {}'.format(self._arr.dtype))
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
            self.tile_maps.append(tile)

        return arr

    cpdef void set_arr(self, arr):
        super(CubeMap, self).set_arr(arr)
        self.tile_height = int(self.height / 2)
        self.tile_width = int(self.width / 3)
        self.two_thirds_width = self.tile_width * 2  # used in some methods

    cpdef int v_from_lat_lon(self, pos):
        """
        Gets pixel value at passed latitude and longitude.
        :param pos: tuple(lat, lon)
        :return: pos
        """
        tile = self.tile_from_lat_lon(pos)
        assert isinstance(tile, TileMap)
        v = tile.v_from_lat_lon(pos)
        return v

    cpdef int v_from_vector(self, vector):
        """
        Gets pixel value at passed position on this map.
        :param vector: Vector (x, y, z)
        :return:
        """
        lat_lon = lat_lon_from_vector(vector)
        tile = self.tile_from_lat_lon(lat_lon)
        tile.v_from_vector(vector)

    cpdef int v_from_xy(self, pos, tile=None):
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

    cpdef get_tile(self, index):
        """
        gets the tile of the passed index
        :param index: int
        :return: TileMap
        """
        return self.tile_maps[index]

    cpdef tile_from_lat_lon(self, pos):
        """
        Gets the tile on which the passed lat, lon value is located.
        :param pos tuple(latitude, longitude)
        :return integer in range 0, 6
        """
        lat, lon = pos
        if not MIN_LAT < lat < MAX_LAT:
            raise ValueError('invalid lat; {}'.format(lat))
        if not MIN_LON < lon < MAX_LON:
            raise ValueError('invalid lon; {}'.format(lon))
        if lat > QTR_PI:
            tile_index = 4  # top tile
        elif lat < -QTR_PI:
            tile_index = 5  # bottom tile
        elif -QTR_PI < lon < QTR_PI:
            tile_index = 0  # meridian tile
        elif -QTR_PI > lon > -3 * QTR_PI:
            tile_index = 1  # left
        elif QTR_PI < lon < 3 * QTR_PI:
            tile_index = 3  # right
        else:
            tile_index = 2  # opposite-meridian
        tile = self.tile_maps[tile_index]
        return tile

    cpdef tile_from_xy(self, pos):
        cdef double[2] pos_
        cp2a_2d(pos, pos_)
        return self._tile_from_xy(pos_)

    cdef object _tile_from_xy(self, double[2] pos):
        return self.tile_maps[self.tile_index_from_xy_(pos)]

    @cython.cdivision(True)
    cdef short tile_index_from_xy_(self, double[2] pos):
        """
        Private method for finding the index corresponding to 
        a passed position.
        """
        cdef:
            double x = pos[0]
            double y = pos[1]
        if not 0 <= x < self.width:
            raise ValueError('x {} outside range: 0-{}'.format(x, self.width))
        if not 0 <= y < self.height:
            raise ValueError('y {} outside range: 0-{}'.format(y, self.height))
        if x < self.tile_width:
            i = 0
        elif x < self.two_thirds_width:
            i = 1
        else:
            i = 2
        if y >= self.height / 2:
            i += 3
        return i

    @cython.cdivision(True)
    @cython.wraparound(False)
    cdef void r_px_(self, int[2] new_pos, int[2] old_pos):
        """
        Returns position 1 map pixel right of the passed position.
        'Right' is defined purely as relative to the referenced pixel
        as it appears in the map, and bears no guaranteed relationship
        to the orientation of the Sphere as described by the cube map.
        """
        x = old_pos[0]
        y = old_pos[1]
        # if passed pos is in tile 0, 1, or 2..
        if y < self.height:
            # if x is on the rightmost border, or center-right border...
            if x == self.width - 1 or x == self.two_thirds_width - 1:
                # move to the left edge of the tile to the left
                new_pos[0] = x - self.two_thirds_width + 1
                new_pos[1] = y
            # or, if x is on the right border of tile 0, go to tile 3
            elif x == self.tile_width - 1:
                new_pos[0] = x - self.tile_width + 1
                new_pos[1] = x + self.tile_height
            # otherwise, just increase x by 1
            else:
                new_pos[0] = x + 1
                new_pos[1] = y
        # otherwise if position is in lower row
        else:
            # if x is on tile 3's right border, go to tile 0's left border
            if x == self.tile_width - 1:
                new_pos[0] = 0
                new_pos[1] = y - self.tile_height
            elif x == self.two_thirds_width - 1:
                if self.tile_width == self.tile_height:
                    new_pos[0] = y - self.tile_height
                else:
                    new_pos[0] = ((y - self.tile_height) *
                        self.tile_width / self.tile_height)
                new_pos[1] = self.tile_height - 1
            elif x == self.width - 1:
                if self.tile_width == self.tile_height:
                    new_pos[0] = self.width - (y - self.tile_height) - 1
                else:
                    new_pos[0] = self.width - 1 - \
                        ((y - self.tile_height) *
                         self.tile_width / self.tile_height)
                new_pos[1] = 0
            # otherwise, if x is not on a border
            else:
                new_pos[0] = x + 1
                new_pos[1] = y

    @cython.cdivision(True)
    @cython.wraparound(False)
    cdef void u_px_(self, int[2] new_pos, int[2] old_pos):
        """
        Returns position 1 map pixel up from the passed position.
        up in this case is relative to the y value.
        This is to keep gradients, etc accurately representative
        as slopes of x and y values, without having to invert values.
        """
        cdef int x, y
        x = old_pos[0]
        y = old_pos[1]
        # if y is at max value in tile 0, 1, or 2...
        if y == self.tile_height - 1:
            if x < self.tile_width:
                new_pos[0] = self.two_thirds_width - 1
                if self.height == self.width:
                    new_pos[1] = self.tile_height + (x - self.two_thirds_width)
                else:
                    new_pos[1] = self.tile_height + \
                        ((x - self.two_thirds_width) *
                         self.tile_height / self.tile_width)
            elif x < self.two_thirds_width:
                new_pos[0] = x
                new_pos[1] = y + 1
            else:
                new_pos[0] = self.tile_width - 1
                if self.height == self.width:
                    new_pos[1] = self.height - 1 - x
                else:
                    new_pos[1] = self.height - 1 - \
                        (x * self.tile_height / self.tile_width)
        elif y == self.height - 1:
            # same algorithm works for upper border of tile 3 and 4
            if x < self.two_thirds_width:
                new_pos[0] = self.two_thirds_width - 1 - x
                new_pos[1] = self.height - 1
            else:
                # handle tile 5
                new_pos[0] = x - self.two_thirds_width
                new_pos[1] = self.tile_height - 1
        else:
            new_pos[0] = old_pos[0]
            new_pos[1] = old_pos[1] + 1

    @cython.cdivision(True)
    @cython.wraparound(False)
    cdef void ur_px_(self, int[2] new_pos, int[2] old_pos):
        """
        Returns position 1 map pixel up from the passed position,
        and 1 to the right.
        Up in this case is relative to the y value of the position.
        May return a value of (-1, -1) indicating that no upper-right
        position exists (for example, if the pixel resides at
        """
        cdef int x, y
        x = old_pos[0]
        y = old_pos[1]
        # if x is at any right-side edge of a tile, handle
        # case specially
        if x == self.tile_width - 1:
            if y == self.tile_height - 1 or y == self.height - 1:
                # no fourth position exists
                new_pos[0] = -1
                new_pos[1] = -1
            elif y < self.tile_height:
                new_pos[0] = 0
                new_pos[1] = x + self.tile_height + 1
            else:
                new_pos[0] = self.two_thirds_width
                new_pos[1] = x - self.tile_height + 1
        elif x == self.two_thirds_width - 1:
            if y == self.tile_height - 1 or y == self.height - 1:
                # no fourth position exists
                new_pos[0] = -1
                new_pos[1] = -1
            elif y < self.tile_height:
                new_pos[0] = 0
                new_pos[1] = y + 1
            else:
                if self.tile_height == self.tile_width:
                    new_pos[0] = y - self.tile_height + 1
                else:
                    new_pos[1] = (y - self.tile_height) * \
                        self.tile_width / self.tile_height + 1
                new_pos[1] = self.tile_height - 1
        elif x == self.width - 1:
            if y == self.tile_height - 1 or y == self.height - 1:
                # no fourth position exists
                new_pos[0] = -1
                new_pos[1] = -1
            elif y < self.tile_height:
                new_pos[0] = self.tile_width
                new_pos[1] = y + 1
            else:
                if self.tile_height == self.tile_width:
                    new_pos[0] = y + self.tile_height + 1
                else:
                    new_pos[0] = (y - self.tile_height) * \
                        self.tile_width / self.tile_height + \
                        self.two_thirds_width + 1
        elif y == self.tile_height - 1:
            if x < self.tile_width:
                new_pos[0] = self.two_thirds_width - 1
                if self.tile_width == self.tile_height:
                    new_pos[1] = x + 1 + self.tile_height
                else:
                    new_pos[1] = x * self.tile_height / self.tile_width + \
                        self.tile_height + 1
            elif x < self.two_thirds_width:
                # act normally
                new_pos[0] = old_pos[0] + 1
                new_pos[1] = old_pos[1] + 1
            else:
                new_pos[0] = self.tile_width
                if self.tile_height == self.tile_width:
                    new_pos[1] = self.height - 1 - (x - self.two_thirds_width)
                else:
                    new_pos[1] = self.height - 1 - \
                        (x - self.two_thirds_width) * self.tile_height / \
                        self.tile_width
        elif y == self.height - 1:
            # same logic handles upper-y edge of tiles 3 and 4
            if x < self.two_thirds_width:
                new_pos[0] = self.two_thirds_width - x - 2
                new_pos[1] = self.height - 1
            else:
                new_pos[0] = x - self.two_thirds_width + 1
                new_pos[1] = self.height - 1
        else:
            new_pos[0] = old_pos[0] + 1
            new_pos[1] = old_pos[1] + 1

    cpdef vector_from_xy(self, pos):
        tile = self.tile_from_xy(pos)
        # get relative position on tile from cube-map position
        tile_ref_pos = self.get_reference_position(tile.cube_face)
        rel_pos = (pos[0] - tile_ref_pos[0], pos[1] - tile_ref_pos[1])
        vector = tile.get_vector_from_xy(rel_pos)
        return vector

    cdef void vector_from_xy_(self, double[3] vector, double[2] pos):
        cdef double[2] tile_ref_pos
        cdef double[2] rel_pos
        tile_index = self.tile_index_from_xy_(pos)
        self.reference_position_(tile_ref_pos, tile_index)
        rel_pos[0] = pos[0] - tile_ref_pos[0]
        rel_pos[1] = pos[1] - tile_ref_pos[1]
        self.vector_from_tile_xy_(vector, tile_index, rel_pos)

    @cython.cdivision(True)
    cdef void vector_from_tile_xy_(
            self, 
            double[3] vector, 
            int tile_index, 
            double[2] pos):
        """
        Gets vector from xy position of passed face tile
        """
        a_index, b_index = pos[0], pos[1]
        if not 0 <= a_index <= self.tile_width - 1:
            raise ValueError('Passed x {} was outside range 0-{}'
                             .format(a_index, self.tile_width))
        if not 0 <= b_index <= self.tile_height - 1:
            raise ValueError('Passed x {} was outside range 0-{}'
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
            vector[0], vector[1], vector[2] = 1, a, b
        elif tile_index == 1:
            vector[0], vector[1], vector[2] = a, -1, b
        elif tile_index == 2:
            vector[0], vector[1], vector[2] = -1, -a, b
        elif tile_index == 3:
            vector[0], vector[1], vector[2] = -a, 1, b
        elif tile_index == 4:
            vector[0], vector[1], vector[2] = a, b, 1
        elif tile_index == 5:
            vector[0], vector[1], vector[2] = -a, b, -1
        else:
            raise ValueError('Invalid face index: {}'.format(tile_index))
        # No value returned, results are stored in passed vector.

    cpdef get_reference_position(self, tile_index):
        if not 0 <= tile_index < 6:  # if outside valid range
            raise IndexError(tile_index)
        elif tile_index < 3:
            return tile_index * self.tile_width, 0
        elif tile_index < 6:
            return (tile_index - 3) * self.tile_width, self.tile_height

    cdef void reference_position_(self, double[2] ref_pos, int tile_index):
        if tile_index < 3:
            ref_pos[0] =  tile_index * self.tile_width
            ref_pos[1] = 0
        elif tile_index < 6:
            ref_pos[0] = (tile_index - 3) * self.tile_width
            ref_pos[1] = self.tile_height

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

    cpdef int v_from_lat_lon(self, pos):
        """
        Gets pixel value at passed latitude and longitude.
        :param pos: tuple(lat, lon)
        :return: pos
        """
        xy_pos = self.lat_lon_to_xy(pos)
        v = self.v_from_xy(xy_pos)
        return v

    cdef int v_from_lat_lon_(self, double[2] pos):
        cdef double[2] xy_pos
        self.lat_lon_to_xy_(xy_pos, pos)
        v = self.v_from_xy_(xy_pos)
        return v

    cpdef int v_from_vector(self, vector):
        """
        Gets pixel value at passed position on this map.
        :param vector: Vector (x, y, z)
        :return: PixelValue
        """
        cdef double[3] vector_
        vector_[0], vector_[1], vector_[2] = vector[0], vector[1], vector[2]
        return self.v_from_vector_(vector_)

    cdef int v_from_vector_(self, double[3] vector):
        cdef double[2] lat_lon
        lat_lon_from_vector_(lat_lon, vector)
        return self.v_from_lat_lon_(lat_lon)

    @cython.wraparound(False)
    cdef void r_px_(self, int[2] new_pos, int[2] old_pos):
        if old_pos[0] == self.width - 1:
            # reset to other side of map
            new_pos[0] = 0
        else:
            new_pos[0] = old_pos[0] + 1
        new_pos[1] = old_pos[1]

    @cython.cdivision(True)
    @cython.wraparound(False)
    cdef void u_px_(self, int[2] new_pos, int[2] old_pos):
        if old_pos[1] < self.height - 1:
            new_pos[0] = old_pos[0]
            new_pos[1] = old_pos[1] + 1
        else:
            new_pos[0] = old_pos[0] + self.width / 2 - 1
            if new_pos[0] >= self.width:
                new_pos[0] -= self.width
            new_pos[1] = self.height - 1


    @cython.wraparound(False)
    @cython.cdivision(True)
    cdef void ur_px_(self, int[2] new_pos, int[2] old_pos):
        if old_pos[1] < self.height - 1:
            new_pos[0] = old_pos[0] + 1
            new_pos[1] = old_pos[1] + 1
        else:
            new_pos[0] = old_pos[0] + self.width / 2
            new_pos[1] = old_pos[1]
        if new_pos[0] >= self.width:
            new_pos[0] -= self.width

    cpdef vector_from_xy(self, pos):
        lat_lon = self.xy_to_lat_lon(pos)
        return vector_from_lat_lon(lat_lon)

    cpdef lat_lon_to_xy(self, lat_lon):
        assert MIN_LON <= lat_lon[1] <= MAX_LON
        assert MIN_LAT <= lat_lon[0] <= MAX_LAT
        cdef double[2] xy_pos
        cdef double[2] lat_lon_
        lat_lon_[0] = lat_lon[0]
        lat_lon_[1] = lat_lon[1]
        self.lat_lon_to_xy_(xy_pos, lat_lon_)
        return xy_pos[0], xy_pos[1]

    @cython.cdivision(True)
    cdef void lat_lon_to_xy_(self, double[2] xy_pos, double[2] lat_lon):
        cdef double x, y
        lat = lat_lon[0]
        lon = lat_lon[1]
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
        xy_pos[0] = x
        xy_pos[1] = y
        # no return, result is stored in passed xy_pos memory view.

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

    cpdef int v_from_lat_lon(self, pos):
        """
        Gets pixel value at passed latitude and longitude.
        :param pos: tuple(lat, lon)
        :return: PixelValue
        """
        vector = vector_from_lat_lon(pos)
        value = self.v_from_vector(vector)
        return value

    cpdef int v_from_vector(self, vector):
        """
        Gets pixel value at passed position on this map.
        :param vector: Vector (x, y, z)
        :return: PixelValue
        """
        cdef double[3] vector_
        vector_[0] = vector.x
        vector_[1] = vector.y
        vector_[2] = vector.z
        return self.v_from_vector_(vector_)

    @cython.cdivision(True)
    cdef int v_from_vector_(self, double[3] vector):
        """
        Gets value associated with passed vector.
        Unlike above version, vector is a memoryview, not an object.
        """
        cdef double x, y, z
        cdef double[2] pos
        x = vector[0]
        y = vector[1]
        z = vector[2]
        if x == 0.:
            raise ValueError('Passed vector had an x value of 0')
        if y == 0.:
            raise ValueError('Passed vector had an y value of 0')
        if z == 0.:
            raise ValueError('Passed vector had an z value of 0')
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
            a = x / y
            b = z / y
        elif self.cube_face == 4:
            a = x / z
            b = y / z
        elif self.cube_face == 5:
            a = x / z
            b = y / -z
        else:
            raise IndexError(self.cube_face)
        pos[0] = a
        pos[1] = b
        return self.v_from_xy_(pos)

    cpdef get_sub_tile(self, p1, p2):
        """
        Gets sub-tile of this tile map
        :param p1: lower left corner
        :param p2: upper right corner
        :return: TileMap
        """
        # todo

    cpdef vector_from_xy(self, pos):
        cdef double[3] vector
        cdef double[2] pos_
        vector = np.ndarray((3), np.double)
        pos_[0], pos_[1] = pos
        self.vector_from_xy_(vector, pos_)
        return Vector(vector)

    @cython.cdivision(True)
    cdef void vector_from_xy_(self, double[3] vector, double[2] pos):
        a_index, b_index = pos[0], pos[1]
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
            vector[0], vector[1], vector[2] = 1, a, b
        elif self.cube_face == 1:
            vector[0], vector[1], vector[2] = a, -1, b
        elif self.cube_face == 2:
            vector[0], vector[1], vector[2] = -1, -a, b
        elif self.cube_face == 3:
            vector[0], vector[1], vector[2] = -a, 1, b
        elif self.cube_face == 4:
            vector[0], vector[1], vector[2] = a, b, 1
        elif self.cube_face == 5:
            vector[0], vector[1], vector[2] = -a, b, -1
        else:
            raise ValueError('Invalid face index: {}'.format(self.cube_face))
        # No value returned, results are stored in passed vector.
    
    
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
        assert self.height == cube_map_shape[0] / 2
        assert self.width == cube_map_shape[1] / 3
    
    cpdef int v_from_xy(self, pos):
        """
        Gets pixel value identified by vector.
        :param pos: map x, y position to access
        :return: PixelValue
        """
        cdef double[2] viewed_map_xy
        x, y = pos
        # modify x and y to be relative to the reference point
        # for this cube side
        x_ref, y_ref = self.reference_position
        viewed_map_xy[0] = x + x_ref
        viewed_map_xy[1] = y + y_ref
        return super(CubeSide, self).v_from_xy_(viewed_map_xy)

    @property
    def reference_position(self):  # todo: calculate only once
        if not 0 <= self.cube_face < 6:  # if outside valid range
            raise IndexError(self.cube_face)
        elif self.cube_face < 3:
            return self.cube_face * self.width, 0
        elif self.cube_face < 6:
            return (self.cube_face - 3) * self.width, self.height


cpdef vector_from_lat_lon(pos):
    """
    Converts a lat lon position into a Vector
    :param pos: tuple(lat, lon)
    :return: Vector
    """
    lat, lon = pos

    assert MIN_LAT <= lat <= MAX_LAT, lat
    assert MIN_LON <= lon <= MAX_LON, lon

    x = cos(lat) * cos(lon)
    y = cos(lat) * sin(lon)
    z = sin(lat)

    return Vector((x, y, z))


cpdef lat_lon_from_vector(vector):
    lat = atan2(vector.z, sqrt(pow(vector.x, 2) + pow(vector.y, 2)))
    lon = atan2(vector.y, vector.x)
    return lat, lon


@cython.wraparound(False)
cdef lat_lon_from_vector_(double[2] lat_lon, double[3] vector):
    x = vector[0]
    y = vector[1]
    z = vector[2]
    lat_lon[0] = atan2(z, sqrt(pow(x, 2) + pow(y, 2)))
    lat_lon[1] = atan2(y, x)
