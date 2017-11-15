import logging
import os
import numpy as np

import settings

from .map import LatLonMap, CubeMap

TN_PATH = os.path.join(settings.ROOT_PATH, 'pyrostex')
TN_RESOURCE_PATH = os.path.join(TN_PATH, 'resources')
OUT_PATH = os.path.join(TN_PATH, 'out')

BASE_MAP_HEIGHT = 1306
BASE_MAP_WIDTH = 2048
BASE_MAP_DIMENSIONS = BASE_MAP_WIDTH, BASE_MAP_HEIGHT
BASE_MAP_NAME = 'base_height'
HEIGHTFIELD_SUFFIX = '.heightfield'

HEIGHT_MAP_NAME = 'height.npy'  # needs extension
MIN_HEIGHT_MAP_EL = -1.2e7
MAX_HEIGHT_MAP_EL = 1.2e7
HEIGHT_MAP_RANGE = MAX_HEIGHT_MAP_EL - MIN_HEIGHT_MAP_EL


class Spheroid:
    """
    Base sphere-like object to be mapped
    """

    def __init__(
            self,
            seed,
            planet_type,
            mass,
            mean_temp,
            radius,
            surface_gravities,
            surface_atmospheres=0,
            axial_tilt=0.05,
            albedo=0.3,
            tidal_locked=False,
            dir_path=None,
    ):
        logger = logging.getLogger(__name__)
        logger.info('Creating spheroid')
        self.seed = seed
        self.type = planet_type
        self.mass = mass
        self.mean_temp = mean_temp
        self.radius = radius
        self.surface_gravities = surface_gravities
        self.surface_pressure = surface_atmospheres
        self.axial_tile = axial_tilt
        self.albedo = albedo
        self.tidal_locked = tidal_locked
        self._dir_path = dir_path

        # check dir exists
        if not os.path.exists(self.dir_path):
            os.mkdir(self.dir_path)

        # generate highest level maps
        self.make_base_height_map()
        self.make_height_arr()
        self.height_map = self.make_height_cube_map()
        self.temp_map = self.make_temp_map()
        self.tex_map = self.make_tex_map()

    @property
    def uid(self):
        """
        Gets unique identifier from spheroid,
        composed of type, seed, and mass.
        :return: None
        """
        return '{type}{seed}{mass}'.format(
            type=self.type,
            seed=self.seed,
            mass='{:.0f}'.format(self.mass)[:12]
        ).strip('.')  # remove any '.'

    def build(self):
        self.make_dir()
        self.make_base_height_map()

    def make_dir(self):
        """
        Creates directory for files.
        :return: None
        """
        if not os.path.exists(self.dir_path):
            os.mkdir(self.dir_path)

    def make_height_arr(self):
        """
        Converts base height map into grey-scale png.
        Created grey-scale png file is located within own dir.
        :return: None
        """
        base_map_path = os.path.join(
            self.dir_path, BASE_MAP_NAME + HEIGHTFIELD_SUFFIX)
        height_field = HeightField(base_map_path)
        width = BASE_MAP_WIDTH
        height = height_field.n_rows
        arr = np.ndarray((height, width), np.uint16)

        def scale(v):
            assert v > MIN_HEIGHT_MAP_EL, v
            assert v < MAX_HEIGHT_MAP_EL, v
            return int(v / -HEIGHT_MAP_RANGE * 65536) + 32768  # 2^16 & 2^16/2

        for y, row in enumerate(height_field.filled_rows):
            arr[y] = [scale(v) for v in row]
        for row in arr:
            assert any(value for value in row), row

        # get path to file to save in
        height_map_path = os.path.join(self.dir_path, HEIGHT_MAP_NAME)

        np.save(height_map_path, arr)

    def make_base_height_map(self):
        # we need to change working directory to planet_gen path
        initial_dir = os.curdir
        os.chdir(settings.PLANET_GEN_DIR)
        base_map_path = os.path.join(self.dir_path, BASE_MAP_NAME)
        # for some unfathomable reason,
        # subprocess breaks when this command is run
        # it seems to only apply a select few of the arguments passed
        os.system(
            './planet -o {out} '
            '-pprojection=q '
            '-s {seed} '
            '-n '
            '-S '
            '-w {w} '
            '-h {h} '
            '-H'
            .format(
                out=base_map_path,
                seed=self.seed,
                w=BASE_MAP_DIMENSIONS[0],
                h=BASE_MAP_DIMENSIONS[1],
            )
        )
        os.chdir(initial_dir)  # change dir back to whatever it started as

    def make_height_cube_map(self):
        """
        Creates cube map from lat-lon map
        :return: None
        """
        height_map_path = os.path.join(self.dir_path, HEIGHT_MAP_NAME)
        lat_lon_map = LatLonMap(path=height_map_path)  # load from file
        cube_map = CubeMap(prototype=lat_lon_map, height=1024, width=1536)
        return cube_map

    def make_temp_map(self):
        """
        Creates temperature cube map from height map + other
        information about planet. (mean temp, mass, atmosphere, etc)
        :return: None
        """

    def make_tex_map(self):
        """
        Creates map
        :return:
        """

    def write_debug_png(self):
        """
        Writes maps to png files for debug purposes
        :return:
        """
        self.height_map.write_png(os.path.join(self.dir_path, 'height_cube.png'))
        # todo: temp + others

    @property
    def dir_path(self):
        return self._dir_path or os.path.join(OUT_PATH, self.uid)


class HeightField:
    """
    Handles information from height field file
    """

    def __init__(self, path):
        self.path = path
        self._rows = None
        self._cols = None

    @property
    def n_rows(self):
        if not self._rows:
            self._rows = len(self.filled_range)
        return self._rows

    @property
    def n_cols(self):
        if not self._cols:
            with open(self.path, 'r') as f:
                self._rows = len(f.readline().rstrip().split())
        return self._cols

    @property
    def filled_range(self):
        """
        Gets range of rows with useful data
        :return: range
        """
        with open(self.path, 'r') as f:
            content = False
            first_row = None
            last_row = None
            counter = 0
            for y, line in enumerate(f.readlines()):
                blank = all([not int(i) for i in line.rstrip().split()])
                if not content and not blank:
                    first_row = y
                    content = True
                elif content and blank:
                    last_row = y - 1
                counter = y
            if not first_row:
                first_row = 0
            if not last_row:
                last_row = counter
            if not self._rows:
                self._rows = counter
            return range(first_row, last_row)

    @property
    def filled_rows(self):
        with open(self.path, 'r') as f:
            rng = self.filled_range
            for row in f.readlines()[slice(rng.start, rng.stop)]:
                yield [int(n) for n in row.rstrip().split()]
