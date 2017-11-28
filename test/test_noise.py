"""
Tests functionality of noise module
"""

from unittest import TestCase

from pyrostex.noise.noise import PyFastNoise


class TestFastNoise(TestCase):
    def test_noise_is_consistent(self):
        n = PyFastNoise()
        n.seed = 127
        a = n.get_simplex_fractal_3d(100, 200, 300)
        b = n.get_simplex_fractal_3d(100, 200, 300)
        self.assertEqual(a, b)
