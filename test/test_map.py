from unittest import TestCase

from math import radians
from mathutils import Vector

from pyrostex import map
from pyrostex.map import GreyLatLonMap, GreyCubeMap, GreyCubeSide
from pyrostex.map import mix_region, pure_region, mix_av


class TestCubeMap(TestCase):
    def test_cube_is_instantiated_with_correct_width(self):
        m = GreyCubeMap(width=1536, height=1024)
        self.assertEqual(1536, m.width)

    def test_cube_is_instantiated_with_correct_height(self):
        m = GreyCubeMap(width=1536, height=1024)
        self.assertEqual(1024, m.height)

    def test_tile_from_xy_returns_correctly1(self):
        m = GreyCubeMap(width=1536, height=1024)
        i = m.tile_from_xy((512, 0))
        self.assertEqual(1, i.cube_face)

    def test_tile_from_xy_returns_correctly3(self):
        m = GreyCubeMap(width=1536, height=1024)
        i = m.tile_from_xy((0, 512))
        self.assertEqual(3, i.cube_face)

    def test_tile_from_xy_returns_correctly5(self):
        m = GreyCubeMap(width=1536, height=1024)
        i = m.tile_from_xy((1535, 1023))
        self.assertEqual(5, i.cube_face)

    def test_tile_from_lat_lon_returns_correctly_near_tile_5_edge(self):
        m = GreyCubeMap(width=1536, height=1024)
        i = m.tile_from_lat_lon((radians(40), -radians(50))).cube_face
        self.assertEqual(4, i)

    def test_tile_from_lat_lon_returns_correctly_center_tile_0(self):
        m = GreyCubeMap(width=1536, height=1024)
        i = m.tile_from_lat_lon((radians(4), -radians(10))).cube_face
        self.assertEqual(0, i)

    def test_tile_from_lat_lon_returns_correctly_center_tile_1(self):
        m = GreyCubeMap(width=1536, height=1024)
        i = m.tile_from_lat_lon((radians(4), -radians(90))).cube_face
        self.assertEqual(1, i)

    def test_tile_from_lat_lon_returns_correctly_center_tile_2(self):
        m = GreyCubeMap(width=1536, height=1024)
        i = m.tile_from_lat_lon((radians(4), -radians(180))).cube_face
        self.assertEqual(2, i)

    def test_tile_from_lat_lon_returns_correctly_center_tile_3(self):
        m = GreyCubeMap(width=1536, height=1024)
        i = m.tile_from_lat_lon((radians(4), radians(90))).cube_face
        self.assertEqual(3, i)

    def test_tile_from_lat_lon_returns_correctly_center_tile_4(self):
        m = GreyCubeMap(width=1536, height=1024)
        i = m.tile_from_lat_lon((radians(90), -radians(-110))).cube_face
        self.assertEqual(4, i)

    def test_tile_from_lat_lon_returns_correctly_near_center_tile_4(self):
        m = GreyCubeMap(width=1536, height=1024)
        i = m.tile_from_lat_lon((radians(85), radians(0))).cube_face
        self.assertEqual(4, i)

    def test_tile_from_lat_lon_returns_correctly_center_tile_5(self):
        m = GreyCubeMap(width=1536, height=1024)
        i = m.tile_from_lat_lon((radians(-80), -radians(-40))).cube_face
        self.assertEqual(5, i)

    def test_vector_from_xy_returns_approximately_correct_value_in_tile0(self):
        m = GreyCubeMap(width=1536, height=1024)
        vec = m.vector_from_xy((256, 256))
        self.assertGreater(vec.x, 0.99)
        self.assertTrue(-0.01 < vec.y < 0.01, vec.y)
        self.assertTrue(-0.01 < vec.z < 0.01, vec.z)

    def test_vector_from_xy_returns_approximately_correct_value_in_tile1(self):
        m = GreyCubeMap(width=1536, height=1024)
        vec = m.vector_from_xy((768, 256))
        self.assertTrue(-0.01 < vec.x < 0.01, vec.x)
        self.assertLess(vec.y, -0.99)
        self.assertTrue(-0.01 < vec.z < 0.01, vec.z)

    def test_vector_from_xy_returns_approximately_correct_value_in_tile2(self):
        m = GreyCubeMap(width=1536, height=1024)
        vec = m.vector_from_xy((1280, 256))
        self.assertLess(vec.x, -0.99)
        self.assertTrue(-0.01 < vec.y < 0.01, vec.y)
        self.assertTrue(-0.01 < vec.z < 0.01, vec.z)

    def test_vector_from_xy_returns_approximately_correct_value_in_tile3(self):
        m = GreyCubeMap(width=1536, height=1024)
        vec = m.vector_from_xy((256, 768))
        self.assertTrue(-0.01 < vec.x < 0.01)
        self.assertGreater(vec.y, 0.99)
        self.assertTrue(-0.01 < vec.z < 0.01)

    def test_vector_from_xy_returns_approximately_correct_value_in_tile4(self):
        m = GreyCubeMap(width=1536, height=1024)
        vec = m.vector_from_xy((768, 768))
        self.assertTrue(-0.01 < vec.x < 0.01)
        self.assertTrue(-0.01 < vec.y < 0.01)
        self.assertGreater(vec.z, 0.99)

    def test_vector_from_xy_returns_approximately_correct_value_in_tile5(self):
        m = GreyCubeMap(width=1536, height=1024)
        vec = m.vector_from_xy((1280, 768))
        self.assertTrue(-0.01 < vec.x < 0.01)
        self.assertTrue(-0.01 < vec.y < 0.01)
        self.assertLess(vec.z, -0.99)


class TestLatLonMap(TestCase):
    def test_lat_lon_to_xy_returns_correct_value_at_edge(self):
        m = GreyLatLonMap(width=2048, height=2048)
        x, y = m.xy_from_lat_lon((radians(90), radians(180)))
        self.assertEqual(2047, y)
        self.assertEqual(2047, x)

    def test_lat_lon_to_xy_returns_correct_value_at_lower_edge(self):
        m = GreyLatLonMap(width=2048, height=2048)
        x, y = m.xy_from_lat_lon((radians(-90), radians(-180)))
        self.assertEqual(0, y)
        self.assertEqual(0, x)


class TestCubeSide(TestCase):
    def test_reference_positions_returns_correct_value_for_tile0(self):
        cm = GreyCubeMap(width=1536, height=1024)
        m = cm.get_tile(0)
        ref_pos = m.reference_position
        self.assertEqual(0, ref_pos[0])
        self.assertEqual(0, ref_pos[1])

    def test_reference_positions_returns_correct_value_for_tile1(self):
        cm = GreyCubeMap(width=1536, height=1024)
        m = cm.get_tile(1)
        ref_pos = m.reference_position
        self.assertEqual(512, ref_pos[0])
        self.assertEqual(0, ref_pos[1])

    def test_reference_positions_returns_correct_value_for_tile2(self):
        cm = GreyCubeMap(width=1536, height=1024)
        m = cm.get_tile(2)
        ref_pos = m.reference_position
        self.assertEqual(1024, ref_pos[0])
        self.assertEqual(0, ref_pos[1])

    def test_reference_positions_returns_correct_value_for_tile3(self):
        cm = GreyCubeMap(width=1536, height=1024)
        m = cm.get_tile(3)
        ref_pos = m.reference_position
        self.assertEqual(0, ref_pos[0])
        self.assertEqual(512, ref_pos[1])

    def test_reference_positions_returns_correct_value_for_tile4(self):
        cm = GreyCubeMap(width=1536, height=1024)
        m = cm.get_tile(4)
        ref_pos = m.reference_position
        self.assertEqual(512, ref_pos[0])
        self.assertEqual(512, ref_pos[1])

    def test_reference_positions_returns_correct_value_for_tile5(self):
        cm = GreyCubeMap(width=1536, height=1024)
        m = cm.get_tile(5)
        ref_pos = m.reference_position
        self.assertEqual(1024, ref_pos[0])
        self.assertEqual(512, ref_pos[1])


class TestFunctions(TestCase):
    def test_meridian_vector_has_correct_lat_lon_conversion(self):
        vector = Vector((1, 0, 0))
        lat, lon = map.lat_lon_from_vector(vector)
        self.assertEqual(0, lat)
        self.assertEqual(0, lon)

    def test_45_lon_vector_has_correct_lat_lon_conversion(self):
        vector = Vector((1, 1, 0))
        lat, lon = map.lat_lon_from_vector(vector)
        self.assertEqual(0, lat)
        self.assertEqual(radians(45), lon)

    def test_90_lon_vector_has_correct_lat_lon_conversion(self):
        vector = Vector((0, -1, 0))
        lat, lon = map.lat_lon_from_vector(vector)
        self.assertEqual(0, lat)
        self.assertEqual(radians(-90), lon)

    def test_latitude_has_correct_conversion(self):
        vector = Vector((1, 0, 1))
        lat, lon = map.lat_lon_from_vector(vector)
        self.assertEqual(radians(45), lat)

    def test_longitude_converts_to_vector_correctly(self):
        vector = map.vector_from_lat_lon((0, radians(45)))
        self.assertEqual(vector.x, vector.y)

    def test_latitude_converts_to_vector_correctly(self):
        vector = map.vector_from_lat_lon((radians(45), 0))
        self.assertEqual(vector.x, vector.z)


class TestVec2Mixing(TestCase):
    def test_vec_can_be_mixed1(self):
        r = mix_av((1, 0.4), 0.75, (0, 0), 0.25)
        self.assertAlmostEqual(0.75, r[0])
        self.assertAlmostEqual(0.3, r[1])

    def test_vec_can_be_mixed2(self):
        r = mix_av((1, 0.4), 3, (0, 0), 1)
        self.assertAlmostEqual(0.75, r[0])
        self.assertAlmostEqual(0.3, r[1])

    def test_vec_can_be_mixed3(self):
        r = mix_av((1, 0.4), 1, (0.5, 0.1), 1)
        self.assertAlmostEqual(0.75, r[0])
        self.assertAlmostEqual(0.25, r[1])


class TestRegionConversions(TestCase):
    def test_pure_region_can_be_created_correctly(self):
        r = pure_region(2)
        self.assertEqual(2, r['r0'])
        self.assertEqual(0, r['r1'])
        self.assertEqual(0, r['r2'])
        self.assertEqual(0, r['r3'])
        self.assertEqual(1, r['w0'])
        self.assertEqual(0, r['w1'])
        self.assertEqual(0, r['w2'])
        self.assertEqual(0, r['w3'])

    def test_two_regions_are_mixed_correctly(self):
        r0 = pure_region(1)
        r1 = pure_region(2)
        rf = mix_region(r0, 0.75, r1, 0.25)
        self.assertEqual(1, rf['r0'])
        self.assertEqual(2, rf['r1'])
        self.assertEqual(0.75, rf['w0'])
        self.assertEqual(0.25, rf['w1'])

    def test_four_regions_are_mixed_correctly(self):
        r0 = pure_region(1)
        r1 = pure_region(2)
        r2 = pure_region(3)
        r3 = pure_region(4)
        r_left = mix_region(r1, 0.75, r2, 0.25)
        r_right = mix_region(r0, 0.75, r3, 0.25)
        rf = mix_region(r_left, 0.75, r_right, 0.25)
        self.assertEqual(2, rf['r0'])
        self.assertEqual(4, rf['r3'])
