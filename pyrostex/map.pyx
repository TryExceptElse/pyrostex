# cython: infer_types=True, boundscheck=False, nonecheck=False, language_level=3,

"""
Maps for storing data about a map for a sphere.
"""

import numpy as np
import png
import itertools as itr

cimport numpy as np


from mathutils import Vector

from math import radians
from libc.math cimport cos, sin, atan2, sqrt, pow

MIN_LAT = radians(-90)
MAX_LAT = radians(90)
LAT_RANGE = MAX_LAT - MIN_LAT
MIN_LON = radians(-180)
MAX_LON = radians(180)
LON_RANGE = MAX_LON - MIN_LON

QTR_PI = radians(45)


cdef class TextureMap:
    """
    Abstract map
    """

    cdef:
        np.ndarray _arr
        public int width, height

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
            self.set_arr(self.make_arr(width, height, p.data_type))
            assert self.height == height, (self.height, height)
            assert self.width == width, (self.width, width)
            for x, y in itr.product(range(width), range(height)):
                # get vector corresponding to position
                vector = self.get_vector_from_xy((x, y))
                v = p.v_from_vector(vector)
                self.set_xy((x, y), v)

        else:
            width = kwargs.get('width', 2048 * 3)
            height = kwargs.get('height', 2048 * 2)
            data_type = kwargs.get('data_type', np.uint8)
            self.set_arr(self.make_arr(width, height, data_type))

        assert self.width
        assert self.height

    cpdef load_arr(self, path):
        return np.load(path, allow_pickle=False)

    cpdef save(self, path):
        np.save(path, self._arr, allow_pickle=False)

    cpdef make_arr(self, width, height, data_type=np.uint8):
        arr = np.ndarray((height, width), data_type)
        return arr

    cpdef set_arr(self, arr):
        self._arr = arr
        self.height, self.width = arr.shape

    cpdef v_from_lat_lon(self, pos):
        """
        Gets pixel value at passed latitude and longitude.
        :param pos: tuple(lat, lon)
        :return: pos
        """
        raise NotImplementedError

    cpdef v_from_xy(self, pos):
        """
        Gets pixel value at passed position on this map.
        :param pos: pos
        :return:
        """
        a, b = pos
        if not 0 <= a <= self.width - 1:
            raise ValueError(
                '{} outside width range 0 - {}'.format(a, self.width - 1))
        if not 0 <= b <= self.height - 1:
            raise ValueError(
                '{} outside height range 0 - {}'.format(b, self.height - 1))
        a_mod = a % 1
        b_mod = b % 1
        if a_mod == 0:
            a0 = int(a)
            a1 = None
        else:
            a0 = int(a)
            a1 = int(a) + 1
            assert a1 < self.width
        if b_mod == 0:
            b0 = int(b)
            b1 = None
        else:
            b0 = int(b)
            b1 = int(b) + 1
            assert b1 < self.height
        assert a0 < self.width
        assert b0 < self.height

        if b1 is None and a1 is None:
            # if both passed values are whole numbers, just get the
            # corresponding value
            vf = self._arr[b0, a0]
        elif a1 is None and b1:
            # if only one column
            v0 = self._arr[b1, a0]
            v1 = self._arr[b0, a0]
            vf = v1 * b_mod + v0 * (1 - b_mod)
        elif b1 is None and a1:
            # if only one row
            v0 = self._arr[b0, a0]
            v1 = self._arr[b0, a1]
            vf = v1 * a_mod + v0 * (1 - a_mod)
        else:
            # if all 4 pixels are to be used
            left0 = self._arr[b0, a0]
            left1 = self._arr[b1, a0]
            right0 = self._arr[b0, a1]
            right1 = self._arr[b1, a1]
            left = left1 * b_mod + left0 * (1 - b_mod)
            right = right1 * b_mod + right0 * (1 - b_mod)
            vf = right * a_mod + left * (1 - a_mod)
        return vf

    cpdef v_from_vector(self, vector):
        """
        Gets pixel value identified by vector.
        :param vector:
        :return:
        """
        raise NotImplementedError

    cpdef get_vector_from_xy(self, pos):
        raise NotImplementedError

    cpdef set_xy(self, pos, v):
        x = int(pos[0])
        y = int(pos[1])
        if not 0 <= x < self.width:
            raise ValueError('Width {} outside range 0 - {}'
                             .format(x, self.width))
        if not 0 <= y < self.height:
            raise ValueError('Height {} outside range 0 - {}'
                             .format(y, self.height))
        self._arr[y][x] = v

    cpdef write_png(self, out):
        """
        Writes map as a png to the passed path
        :param out: path String
        :return: None
        """
        if '.' not in out:
            out += '.png'
        assert isinstance(self._arr, np.ndarray)
        if self._arr.dtype == np.uint8:
            out_arr = self._arr
        elif self._arr.dtype == np.uint16:
            out_arr = np.empty_like(self._arr, np.uint8)
            for y, row in enumerate(self._arr):
                for x, v in enumerate(row):
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

    cdef list tile_maps

    def __init__(self, **kwargs):
        self.tile_maps = []
        super().__init__(**kwargs)

    cpdef make_arr(self, width, height, data_type=np.uint8):
        arr = super(CubeMap, self).make_arr(width, height, data_type)

        # create tiles
        for i in range(6):
            tile = CubeSide(i, arr)
            self.tile_maps.append(tile)

        return arr

    cpdef v_from_lat_lon(self, pos):
        """
        Gets pixel value at passed latitude and longitude.
        :param pos: tuple(lat, lon)
        :return: pos
        """
        tile = self.tile_from_lat_lon(pos)
        assert isinstance(tile, TileMap)
        v = tile.v_from_lat_lon(pos)
        return v

    cpdef v_from_vector(self, vector):
        """
        Gets pixel value at passed position on this map.
        :param vector: Vector (x, y, z)
        :return:
        """
        lat_lon = lat_lon_from_vector(vector)
        tile = self.tile_from_lat_lon(lat_lon)
        tile.v_from_vector(vector)

    cpdef v_from_xy(self, pos, tile=None):
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
            return self._arr[y][x]

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
        x, y = pos
        third_width = self.width / 3
        if not 0 <= x < self.width:
            raise ValueError('x {} outside range: 0-{}'.format(x, self.width))
        if not 0 <= y < self.height:
            raise ValueError('y {} outside range: 0-{}'.format(y, self.height))
        if x < third_width:
            i = 0
        elif x < third_width * 2:
            i = 1
        else:
            i = 2
        if y >= self.height / 2:
            i += 3
        return self.tile_maps[i]

    cpdef get_vector_from_xy(self, pos):
        tile = self.tile_from_xy(pos)
        # get relative position on tile from cube-map position
        tile_ref_pos = self.get_reference_position(tile.cube_face)
        rel_pos = (pos[0] - tile_ref_pos[0], pos[1] - tile_ref_pos[1])
        vector = tile.get_vector_from_xy(rel_pos)
        return vector

    cpdef get_reference_position(self, tile_index):
        if not 0 <= tile_index < 6:  # if outside valid range
            raise IndexError(tile_index)
        elif tile_index < 3:
            return tile_index * self.tile_width, 0
        elif tile_index < 6:
            return (tile_index - 3) * self.tile_width, self.tile_height

    @property
    def tile_width(self):
        width = self.width / 3
        assert width % 1 == 0
        return width

    @property
    def tile_height(self):
        height = self.height / 2
        assert height % 1 == 0
        return height


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

    cpdef v_from_lat_lon(self, pos):
        """
        Gets pixel value at passed latitude and longitude.
        :param pos: tuple(lat, lon)
        :return: pos
        """
        xy_pos = self.lat_lon_to_xy(pos)
        vector = vector_from_lat_lon(pos)
        v = self.v_from_xy(xy_pos)
        return v

    cpdef v_from_vector(self, vector):
        """
        Gets pixel value at passed position on this map.
        :param vector: Vector (x, y, z)
        :return: PixelValue
        """
        lat_lon = lat_lon_from_vector(vector)
        return self.v_from_lat_lon(lat_lon)

    cpdef get_vector_from_xy(self, pos):
        lat_lon = self.xy_to_lat_lon(pos)
        return vector_from_lat_lon(lat_lon)

    cpdef lat_lon_to_xy(self, lat_lon):
        lat, lon = lat_lon
        assert MIN_LON <= lon <= MAX_LON
        assert MIN_LAT <= lat <= MAX_LAT
        x_ratio = lon / LON_RANGE + 0.5  # x as ratio of 0 to 1
        y_ratio = lat / LAT_RANGE + 0.5  # y as ratio from 0 to 1
        x = x_ratio * (self.width - 1)  # max index is 1 less than size
        y = y_ratio * (self.height - 1)  # max index is 1 less than size
        # correct floating point errors that take values outside range
        if x > self.width - 1:
            # if floating point error has taken x over width, correct it.
            assert x - self.width - 1 < 0.01, x  # if larger, something's wrong
            x = self.width - 1
        elif x < 0:
            assert x > -0.01, x
            x = 0
        if y > self.height - 1:
            assert y - self.height - 1 < 0.01, y
            y = self.height - 1
        elif y < 0:
            assert y > -0.01, y
            y = 0
        return x, y

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

    cdef:
        tuple p1, p2
        object parent
        public short cube_face

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

    cpdef v_from_lat_lon(self, pos):
        """
        Gets pixel value at passed latitude and longitude.
        :param pos: tuple(lat, lon)
        :return: PixelValue
        """
        vector = vector_from_lat_lon(pos)
        value = self.v_from_vector(vector)
        return value

    cpdef v_from_vector(self, vector):
        """
        Gets pixel value at passed position on this map.
        :param vector: Vector (x, y, z)
        :return: PixelValue
        """
        if self.cube_face == 0:
            a = vector.y / vector.x
            b = vector.z / vector.x
        elif self.cube_face == 1:
            a = vector.x / -vector.y
            b = vector.z / -vector.y
        elif self.cube_face == 2:
            a = vector.y / vector.x
            b = vector.z / -vector.x
        elif self.cube_face == 3:
            a = vector.x / vector.y
            b = vector.z / vector.y
        elif self.cube_face == 4:
            a = vector.x / vector.z
            b = vector.y / vector.z
        elif self.cube_face == 5:
            a = vector.x / -vector.z
            b = vector.y / -vector.z
        else:
            raise IndexError(self.cube_face)
        self.v_from_xy((a, b))

    cpdef get_sub_tile(self, p1, p2):
        """
        Gets sub-tile of this tile map
        :param p1: lower left corner
        :param p2: upper right corner
        :return: TileMap
        """
        # todo

    cpdef get_vector_from_xy(self, pos):
        a_index, b_index = pos
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
        assert -1 <= a <= 1, a
        assert -1 <= b <= 1, b
        if self.cube_face == 0:
            vector = Vector((1, a, b))
        elif self.cube_face == 1:
            vector = Vector((a, -1, b))
        elif self.cube_face == 2:
            vector = Vector((-1, -a, b))
        elif self.cube_face == 3:
            vector = Vector((-a, 1, b))
        elif self.cube_face == 4:
            vector = Vector((a, b, 1))
        elif self.cube_face == 5:
            vector = Vector((a, b, -1))
        else:
            raise ValueError('Invalid face index: {}'.format(self.cube_face))
        assert vector.magnitude < 1.9, vector.magnitude
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
        assert self.height == cube_map_shape[0] / 2
        assert self.width == cube_map_shape[1] / 3
    
    cpdef v_from_xy(self, pos):
        """
        Gets pixel value identified by vector.
        :param pos: map x, y position to access
        :return: PixelValue
        """
        x, y = pos
        # modify x and y to be relative to the reference point
        # for this cube side
        x_ref, y_ref = self.reference_position
        x += x_ref
        y += y_ref
        return super().v_from_xy((x, y))

    @property
    def reference_position(self):
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
