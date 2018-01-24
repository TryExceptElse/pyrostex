"""
Tests functions defined in cmathutils and other cython headers
"""

from unittest import TestCase

from pyrostex.includes cimport cmathutils as mu
from pyrostex.includes.cmathutils cimport vec2, vec3, vec4, mat3x3


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

    def test_vec2_component_multiply_functions_correctly(self):
        cdef vec2 a, b, r

        a = mu.vec2New( 1,  2)
        b = mu.vec2New(.1, .2)

        r = mu.vec2CompMult(a, b)

        self.assertAlmostEqual(0.1, r.x)
        self.assertAlmostEqual(0.4, r.y)

    def test_vec3_component_multiply_functions_correctly(self):
        cdef vec3 a, b, r

        a = mu.vec3New( 1,  2,  3)
        b = mu.vec3New(.1, .2, .3)

        r = mu.vec3CompMult(a, b)

        self.assertAlmostEqual(0.1, r.x)
        self.assertAlmostEqual(0.4, r.y)
        self.assertAlmostEqual(0.9, r.z)

    def test_vec4_component_multiply_functions_correctly(self):
        cdef vec4 a, b, r

        a = mu.vec4New( 1,  2,  3,  4)
        b = mu.vec4New(.1, .2, .3, .4)

        r = mu.vec4CompMult(a, b)

        self.assertAlmostEqual(0.1, r.x)
        self.assertAlmostEqual(0.4, r.y)
        self.assertAlmostEqual(0.9, r.z)
        self.assertAlmostEqual(1.6, r.w)

    def test_vec2_component_floor_functions_correctly(self):
        cdef vec2 a, r
        
        a = mu.vec2New(3.1, 5.7)
        r = mu.vec2Floor(a)
        
        self.assertEqual(3, r.x)
        self.assertEqual(5, r.y)

    def test_vec3_component_floor_functions_correctly(self):
        cdef vec3 a, r
        
        a = mu.vec3New(3.1, 5.7, 8.8)
        r = mu.vec3Floor(a)
        
        self.assertEqual(3, r.x)
        self.assertEqual(5, r.y)
        self.assertEqual(8, r.z)

    def test_vec4_component_floor_functions_correctly(self):
        cdef vec4 a, r
        
        a = mu.vec4New(3.1, 5.7, 8.8, 14.5)
        r = mu.vec4Floor(a)
        
        self.assertEqual(3,  r.x)
        self.assertEqual(5,  r.y)
        self.assertEqual(8,  r.z)
        self.assertEqual(14, r.w)

    def test_vec2_component_modulo_functions_correctly(self):
        cdef vec2 a, r

        a = mu.vec2New(3.1, 5.7)
        r = mu.vec2Mod(a, 2)

        self.assertAlmostEqual(1.1,  r.x)
        self.assertAlmostEqual(1.7,  r.y)

    def test_vec3_component_modulo_functions_correctly(self):
        cdef vec3 a, r

        a = mu.vec3New(3.1, 5.7, 8.8)
        r = mu.vec3Mod(a, 2)

        self.assertAlmostEqual(1.1,  r.x)
        self.assertAlmostEqual(1.7,  r.y)
        self.assertAlmostEqual(0.8,  r.z)

    def test_vec4_component_modulo_functions_correctly(self):
        cdef vec4 a, r

        a = mu.vec4New(3.1, 5.7, 8.8, 14.5)
        r = mu.vec4Mod(a, 2)

        self.assertAlmostEqual(1.1, r.x)
        self.assertAlmostEqual(1.7, r.y)
        self.assertAlmostEqual(0.8, r.z)
        self.assertAlmostEqual(0.5, r.w)

    def test_vec2_component_fract_functions_correctly(self):
        cdef vec2 a, r

        a = mu.vec2New(3.1, 5.7)
        r = mu.vec2Fract(a)

        self.assertAlmostEqual(0.1,  r.x)
        self.assertAlmostEqual(0.7,  r.y)

    def test_vec3_component_fract_functions_correctly(self):
        cdef vec3 a, r

        a = mu.vec3New(3.1, 5.7, 8.8)
        r = mu.vec3Fract(a)

        self.assertAlmostEqual(0.1,  r.x)
        self.assertAlmostEqual(0.7,  r.y)
        self.assertAlmostEqual(0.8,  r.z)

    def test_vec4_component_fract_functions_correctly(self):
        cdef vec4 a, r

        a = mu.vec4New(3.1, 5.7, 8.8, 14.5)
        r = mu.vec4Fract(a)

        self.assertAlmostEqual(0.1, r.x)
        self.assertAlmostEqual(0.7, r.y)
        self.assertAlmostEqual(0.8, r.z)
        self.assertAlmostEqual(0.5, r.w)


    def test_vec2_scalar_add_functions_correctly(self):
        cdef vec2 a, r

        a = mu.vec2New(3.1, 5.7)
        r = mu.vec2ScalarAdd(a, 2)

        self.assertAlmostEqual(5.1,  r.x)
        self.assertAlmostEqual(7.7,  r.y)

    def test_vec3_scalar_add_functions_correctly(self):
        cdef vec3 a, r

        a = mu.vec3New(3.1, 5.7, 8.8)
        r = mu.vec3ScalarAdd(a, 2)

        self.assertAlmostEqual(5.1,  r.x)
        self.assertAlmostEqual(7.7,  r.y)
        self.assertAlmostEqual(10.8, r.z)

    def test_vec4_scalar_add_functions_correctly(self):
        cdef vec4 a, r

        a = mu.vec4New(3.1, 5.7, 8.8, 14.5)
        r = mu.vec4ScalarAdd(a, 2)

        self.assertAlmostEqual(5.1,  r.x)
        self.assertAlmostEqual(7.7,  r.y)
        self.assertAlmostEqual(10.8, r.z)
        self.assertAlmostEqual(16.5, r.w)


    def test_vec2_scalar_sub_functions_correctly(self):
        cdef vec2 a, r

        a = mu.vec2New(3.1, 5.7)
        r = mu.vec2ScalarSub(a, 2)

        self.assertAlmostEqual(1.1,  r.x)
        self.assertAlmostEqual(3.7,  r.y)

    def test_vec3_scalar_sub_functions_correctly(self):
        cdef vec3 a, r

        a = mu.vec3New(3.1, 5.7, 8.8)
        r = mu.vec3ScalarSub(a, 2)

        self.assertAlmostEqual(1.1,  r.x)
        self.assertAlmostEqual(3.7,  r.y)
        self.assertAlmostEqual(6.8,  r.z)

    def test_vec4_scalar_sub_functions_correctly(self):
        cdef vec4 a, r

        a = mu.vec4New(3.1, 5.7, 8.8, 14.5)
        r = mu.vec4ScalarSub(a, 2)

        self.assertAlmostEqual(1.1,  r.x)
        self.assertAlmostEqual(3.7,  r.y)
        self.assertAlmostEqual(6.8,  r.z)
        self.assertAlmostEqual(12.5, r.w)
