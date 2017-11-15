from unittest import TestCase

import os

from math import radians

from pyrostex.map import LatLonMap, CubeMap


class TestCubeMap(TestCase):
    def test_cube_is_instantiated_with_correct_width(self):
        m = CubeMap(width=1536, height=1024)
        self.assertEqual(1536, m.width)

    def test_cube_is_instantiated_with_correct_height(self):
        m = CubeMap(width=1536, height=1024)
        self.assertEqual(1024, m.height)

    def test_make_arr_creates_correct_height(self):
        m = CubeMap(width=1536, height=1024)
        arr = m.make_arr(1536, 1024)
        self.assertEqual(1024, len(arr))

    def test_make_arr_creates_correct_width(self):
        m = CubeMap(width=1536, height=1024)
        arr = m.make_arr(1536, 1024)
        self.assertEqual(1536, len(arr[0]))

    def test_tile_from_xy_returns_correctly1(self):
        m = CubeMap(width=1536, height=1024)
        i = m.tile_from_xy((512, 0))
        self.assertEqual(1, i.cube_face)

    def test_tile_from_xy_returns_correctly3(self):
        m = CubeMap(width=1536, height=1024)
        i = m.tile_from_xy((0, 512))
        self.assertEqual(3, i.cube_face)

    def test_tile_from_xy_returns_correctly5(self):
        m = CubeMap(width=1536, height=1024)
        i = m.tile_from_xy((1535, 1023))
        self.assertEqual(5, i.cube_face)


class TestLatLonMap(TestCase):
    def test_lat_lon_to_xy_returns_correct_value_at_edge(self):
        m = LatLonMap(width=2048, height=2048)
        x, y = m.lat_lon_to_xy((radians(90), radians(180)))
        self.assertEqual(2047, y)
        self.assertEqual(2047, x)

    def test_lat_lon_to_xy_returns_correct_value_at_lower_edge(self):
        m = LatLonMap(width=2048, height=2048)
        x, y = m.lat_lon_to_xy((radians(-90), radians(-180)))
        self.assertEqual(0, y)
        self.assertEqual(0, x)
