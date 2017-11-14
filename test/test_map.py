from unittest import TestCase

import os

from math import radians

from pyrostex.map import LatLonMap
from settings import ROOT_PATH


class TestCubeMap:
    pass


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
