"""
Tests functions defined in cmathutils and other cython headers
"""

from unittest import TestCase

from pyrostex.includes cimport cmathutils as mu
from pyrostex.includes.cmathutils cimport vec2, vec3, mat3x3


class TestCMathUtils(TestCase):

    def test_vec2_add(self):
        cdef vec2 a, b, result
        a = mu.vec2New(4, 5)
        b = mu.vec2New(5, 6)
        result = mu.vec2Add(a, b)
        self.assertEqual(9 , result.x)
        self.assertEqual(11, result.y)

    def test_vec2_sub(self):
        cdef vec2 a, b, result
        a = mu.vec2New(7, 5)
        b = mu.vec2New(5, 4)
        result = mu.vec2Subtract(a, b)
        self.assertEqual(2, result.x)
        self.assertEqual(1, result.y)

    def test_mat3x3Add(self):
        cdef mat3x3 a, b, r
        
        a[0][0] = 0.
        a[0][1] = 1.
        a[0][2] = 2.
        a[1][0] = 3.
        a[1][1] = 4.
        a[1][2] = 5.
        a[2][0] = 6.
        a[2][1] = 7.
        a[2][2] = 8.
        
        b[0][0] = 9.
        b[0][1] = 8.
        b[0][2] = 7.
        b[1][0] = 6.
        b[1][1] = 5.
        b[1][2] = 4.
        b[2][0] = 3.
        b[2][1] = 2.
        b[2][2] = 1.

        mu.mat3x3Add(r, a, b)

        self.assertEqual(9, r[0][0])
        self.assertEqual(9, r[0][1])
        self.assertEqual(9, r[0][2])
        self.assertEqual(9, r[1][0])
        self.assertEqual(9, r[1][1])
        self.assertEqual(9, r[1][2])
        self.assertEqual(9, r[2][0])
        self.assertEqual(9, r[2][1])
        self.assertEqual(9, r[2][2])

    def test_mat3x3Add_can_store_result_in_addend(self):
        cdef mat3x3 a, b

        a[0][0] = 0.
        a[0][1] = 1.
        a[0][2] = 2.
        a[1][0] = 3.
        a[1][1] = 4.
        a[1][2] = 5.
        a[2][0] = 6.
        a[2][1] = 7.
        a[2][2] = 8.

        b[0][0] = 9.
        b[0][1] = 8.
        b[0][2] = 7.
        b[1][0] = 6.
        b[1][1] = 5.
        b[1][2] = 4.
        b[2][0] = 3.
        b[2][1] = 2.
        b[2][2] = 1.

        mu.mat3x3Add(a, a, b)

        self.assertEqual(9, a[0][0])
        self.assertEqual(9, a[0][1])
        self.assertEqual(9, a[0][2])
        self.assertEqual(9, a[1][0])
        self.assertEqual(9, a[1][1])
        self.assertEqual(9, a[1][2])
        self.assertEqual(9, a[2][0])
        self.assertEqual(9, a[2][1])
        self.assertEqual(9, a[2][2])

    def test_rotation_matrix_can_be_found_and_used(self):
        cdef vec3 a, b, v
        cdef mat3x3 r

        a = mu.vec3New(0., 0., 1.)
        b = mu.vec3New(0., 1., 0.)

        mu.rotation_difference(r, a, b)

        v = mu.mat3x3MultiplyVector(r, a)

        self.assertEqual(0., v.x, 'incorrect result x: {}'.format(v))
        self.assertEqual(1., v.y, 'incorrect result y: {}'.format(v))
        self.assertEqual(0., v.z, 'incorrect result z: {}'.format(v))

    def test_rotation_matrix_can_be_found_and_used2(self):
        cdef vec3 a, b, v
        cdef mat3x3 r

        a = mu.vec3New(0., 0., 1.)
        b = mu.vec3New(0., 0.7, 0.7)

        mu.rotation_difference(r, a, b)

        v = mu.mat3x3MultiplyVector(r, a)

        self.assertEqual(0., v.x, 'incorrect result x: {}'.format(v))
        self.assertEqual(0.7, v.y, 'incorrect result y: {}'.format(v))
        self.assertEqual(0.7, v.z, 'incorrect result z: {}'.format(v))

    def test_vector_can_be_rotated_in_place(self):
        cdef vec3 a, b, v
        cdef mat3x3 r

        a = mu.vec3New(0., 0., 1.)
        b = mu.vec3New(0., 1., 0.)

        mu.rotation_difference(r, a, b)

        a = mu.mat3x3MultiplyVector(r, a)

        self.assertEqual(0., a.x, 'incorrect result x: {}'.format(a))
        self.assertEqual(1., a.y, 'incorrect result y: {}'.format(a))
        self.assertEqual(0., a.z, 'incorrect result z: {}'.format(a))

    def test_vector_can_be_rotated_in_place2(self):
        cdef vec3 a, b
        cdef mat3x3 r

        a = mu.vec3New(0., 0., 1.)
        b = mu.vec3New(0., 0.65, 0.65)

        mu.rotation_difference(r, a, b)

        a = mu.mat3x3MultiplyVector(r, a)

        self.assertEqual(0.00, a.x, 'incorrect result x: {}'.format(a))
        self.assertEqual(0.65, a.y, 'incorrect result y: {}'.format(a))
        self.assertEqual(0.65, a.z, 'incorrect result z: {}'.format(a))

    def test_rotation_difference_func_can_handle_equal_vectors(self):
        cdef vec3 a, b
        cdef mat3x3 r

        a = mu.vec3New(0., 0.65, 0.65)
        b = mu.vec3New(0., 0.65, 0.65)

        mu.rotation_difference(r, a, b)

        a = mu.mat3x3MultiplyVector(r, a)

        self.assertEqual(0.00, a.x, 'incorrect result x: {}'.format(a))
        self.assertEqual(0.65, a.y, 'incorrect result y: {}'.format(a))
        self.assertEqual(0.65, a.z, 'incorrect result z: {}'.format(a))

    def test_rotation_difference_func_can_handle_reciprocal_vectors1(self):
        cdef vec3 a, b
        cdef mat3x3 r

        a = mu.vec3New(0., 0, -1)
        b = mu.vec3New(0., 0, 1)

        mu.rotation_difference(r, a, b)

        a = mu.mat3x3MultiplyVector(r, a)

        self.assertEqual(0.00, a.x, 'incorrect result x: {}'.format(a))
        self.assertEqual(0.00, a.y, 'incorrect result y: {}'.format(a))
        self.assertEqual(1.00, a.z, 'incorrect result z: {}'.format(a))

    def test_rotation_difference_func_can_handle_reciprocal_vectors2(self):
        cdef vec3 a, b
        cdef mat3x3 r

        a = mu.vec3New(0., -0.65, -0.65)
        b = mu.vec3New(0., 0.65, 0.65)

        mu.rotation_difference(r, a, b)

        a = mu.mat3x3MultiplyVector(r, a)

        self.assertEqual(0.00, a.x, 'incorrect result x: {}'.format(a))
        self.assertEqual(0.65, a.y, 'incorrect result y: {}'.format(a))
        self.assertEqual(0.65, a.z, 'incorrect result z: {}'.format(a))
