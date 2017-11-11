"""
Maps for storing data about a map for a sphere.
"""

import numpy as np
import png

from mathutils import Vector

from math import radians, cos, sin, tan

MIN_LAT = radians(-90)
MAX_LAT = radians(90)
MIN_LON = radians(-180)
MAX_LON = radians(180)

QTR_PI = radians(45)


class TextureMap:
    """
    Abstract map
    """

    def v_from_lat_lon(self, pos):
        """
        Gets pixel value at passed latitude and longitude.
        :param pos: tuple(lat, lon)
        :return: pos
        """
        raise NotImplementedError

    def v_from_xy(self, pos):
        """
        Gets pixel value at passed position on this map.
        :param pos: pos
        :return:
        """
        raise NotImplementedError

    def v_from_vector(self, vector):
        """
        Gets pixel value identified by vector.
        :param vector:
        :return:
        """
        raise NotImplementedError


class CubeMap(TextureMap):
    def __init__(self, **kwargs):
        # if path is passed to load texture from
        try:
            path = kwargs['path']
            reader = png.Reader()
            reader  # todo
        except KeyError:
            #
            width = kwargs.get('width', 4096 * 1.5)
            height = kwargs.get('height', 4096)
            try:
                self._arr = kwargs['arr']
            except KeyError:
                self._arr = np.ndarray((width, height), np.uint8)

    def v_from_lat_lon(self, pos):
        """
        Gets pixel value at passed latitude and longitude.
        :param pos: tuple(lat, lon)
        :return: pos
        """
        lat, lon = pos
        if not MIN_LAT < lat < MAX_LAT:
            raise ValueError('invalid lat; {}'.format(lat))
        if not MIN_LON < lon < MAX_LON:
            raise ValueError('invalid lon; {}'.format(lon))
        if lat > QTR_PI:
            tile = 4  # top tile
        elif lat <  -QTR_PI:
            tile = 5  # bottom tile
        elif -QTR_PI < lon < QTR_PI:
            tile = 0  # meridian tile
        elif 

    def v_from_vector(self, vector):
        """
        Gets pixel value at passed position on this map.
        :param vector: Vector (x, y, z)
        :return:
        """

    def v_from_xy(self, pos, tile=None):
        """
        Gets pixel value identified by vector.
        :param pos: map x, y
        :param tile: tile index
        :return: value
        """

    def get_tile(self, index):
        """
        gets the tile of the passed index
        :param index:
        :return:
        """
        
    def tile_from_lat_lon(pos):
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
            tile = 4  # top tile
        elif lat <  -QTR_PI:
            tile = 5  # bottom tile
        elif -QTR_PI < lon < QTR_PI:
            tile = 0  # meridian tile
        elif 


    def get_reference_position(self, tile_index):
        if not 0 <= tile_index < 6:  # if outside valid range
            raise IndexError(tile_index)
        elif tile_index < 3:
            return tile_index * self.tile_width, 0
        elif tile_index < 6:
            return (tile_index - 3) * self.tile_width, self.tile_height

    @property
    def width(self):
        return len(self._arr[0])

    @property
    def height(self):
        return len(self._arr)

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


class LatLonMap(TextureMap):
    """
    Stores a latitude-longitude texture map
    """

    def v_from_lat_lon(self, pos):
        """
        Gets pixel value at passed latitude and longitude.
        :param pos: tuple(lat, lon)
        :return: pos
        """


    def v_from_vector(self, vector):
        """
        Gets pixel value at passed position on this map.
        :param vector: Vector (x, y, z)
        :return:
        """

    def v_from_xy(self, pos):
        """
        Gets pixel value identified by vector.
        :param pos: map x, y
        :return:
        """


class TileMap(TextureMap):
    """
    Stores a square texture map that is mapped to a portion of a sphere.
    """
    def __init__(self, p1, p2, cube_face, width=2048, height=2048):
        """
        Creates TileMap from upper left and lower right corner position
        relative to the face of the cube-map.
        Ex: (0,0) is center, (1,1) is lower right, (-1,1) is upper right
        Cube face is the face of the cube on which this tile is located.
        :param p1: tuple(x, y)
        :param p2: tuple(x, y)
        """
        self.cube_face = cube_face
        self.p1 = p1
        self.p2 = p2
        self.parent = None
        self._arr = np.ndarray((width, height), np.uint8)


    def v_from_lat_lon(self, pos):
        """
        Gets pixel value at passed latitude and longitude.
        :param pos: tuple(lat, lon)
        :return: PixelValue
        """
        vector = vector_from_lat_lon(pos)
        value = self.v_from_vector(vector)
        return value

    def v_from_vector(self, vector):
        """
        Gets pixel value at passed position on this map.
        :param vector: Vector (x, y, z)
        :return: PixelValue
        """
        if self.cube_face == 0:
            a = vector.y / vector.x
            b = vector.z / vector.x
        elif self.cube_face == 1:
            a = vector.x / vector.y
            b = vector.z / vector.y
        elif self.cube_face == 2:
            a = vector.y / vector.x
            b = vector.z / -vector.x
        elif self.cube_face == 3:
            a = vector.y / vector.x
            b = vector.z / -vector.y
        elif self.cube_face == 4:
            a = vector.x / vector.z
            b = vector.y / vector.z
        elif self.cube_face == 5:
            a = vector.x / -vector.z
            b = vector.y / -vector.z
        else:
            raise IndexError(self.cube_face)
        self.v_from_xy((a, b))

    def v_from_xy(self, pos):
        """
        Gets pixel value identified by vector.
        :param pos: map x, y
        :return:
        """
        a, b = pos
        a_mod = a % 1
        b_mod = b % 1
        if a_mod == 0:
            a0 = int(a)
            a1 = None
        else:
            a0 = int(a)
            a1 = int(a) + 1
            assert a1 <= self.width
        if b_mod == 0:
            b0 = int(b)
            b1 = None
        else:
            b0 = int(b)
            b1 = int(b) + 1
            assert b1 <= self.height

        vector = self.get_vector_from_xy(pos)
        if b1 is None and a1 is None:
            # if both passed values are whole numbers, just get the
            # corresponding value
            pixel_value = PixelValue(self._arr[b0, a0], vector)
        elif a1 is None and b1:
            # if only one column
            v0 = self._arr[b1, a0]
            v1 = self._arr[b0, a0]
            vf = v1 * b_mod + v0 * (1 - b_mod)
            pixel_value = PixelValue(vf, vector)
        elif b1 is None and a1:
            # if only one row
            v0 = self._arr[b0, a0]
            v1 = self._arr[b0, a1]
            vf = v1 * a_mod + v0 * (1 - a_mod)
            pixel_value = PixelValue(vf, vector)
        else:
            # if all 4 pixels are to be used
            left0 = self._arr[b0, a0]
            left1 = self._arr[b1, a0]
            right0 = self._arr[b0, a1]
            right1 = self._arr[b1, a1]
            left = left1 * b_mod + left0 * (1 - b_mod)
            right = right1 * b_mod + right0 * (1 - b_mod)
            vf = right * a_mod + left * (1 - a_mod)
            pixel_value = PixelValue(vf, vector)
        return pixel_value

    def get_sub_tile(self, p1, p2):


    def get_vector_from_xy(self, pos):
        a, b = pos
        assert -1 <= a <= 1, a
        assert -1 <= b <= 1, b
        if self.cube_face == 0:
            vector = Vector((1, a, b))
        elif self.cube_face == 1:
            vector = Vector((a, 1, b))
        elif self.cube_face == 2:
            vector = Vector((-1, -a, b))
        elif self.cube_face == 3:
            vector = Vector((-a, -1, b))
        elif self.cube_face == 4:
            vector = Vector((a, b, 1))
        elif self.cube_face == 5:
            vector = Vector((a, b, -1))
        else:
            raise ValueError('Invalid face index: {}'.format(self.cube_face))
        assert vector.magnitude < 1.42, vector.magnitude
        return vector

    @property
    def width(self):
        return len(self._arr[0])

    @property
    def height(self):
        return len(self._arr)


class PixelValue:
    def __init__(self, value, vector):
        self.value = value
        self.vector = vector


def vector_from_lat_lon(pos):
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
