import logging
import os
import numpy as np

import settings

from .map import GreyLatLonMap, GreyCubeMap, GreyTileMap
from .temp import make_warming_map
from .wind import make_wind_map
from .height import make_height_detail, make_tectonic_cube

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

WARMING_MAP_NAME = 'warming.npy'


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
            atm_warming=0,
            axial_tilt=0.05,
            albedo=0.3,
            tidal_locked=False,
            dir_path=None,
    ):
        logger = logging.getLogger(__name__)
        logger.info('Creating spheroid')
        # seeds 46338 and larger cause failures. reason unknown.
        self.seed = seed % 46337
        self.type = planet_type
        self.mass = mass
        self.mean_temp = mean_temp
        self.radius = radius
        self.surface_gravities = surface_gravities
        self.surface_pressure = surface_atmospheres
        self.atm_warming = atm_warming
        self.axial_tile = axial_tilt
        self.albedo = albedo
        self.tidal_locked = tidal_locked
        self._dir_path = dir_path

        # maps
        self.tectonic_map = None
        self.warming_map = None
        self.temp_map = None
        self.wind_map = None
        self.height_map = None  # final height map used for
        self.tex_map = None

        # check dir exists
        if not os.path.exists(self.dir_path):
            os.mkdir(self.dir_path)

        # generate highest level maps
        self.build()

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
        tiles_dir = os.path.join(self.dir_path, 'tiles')
        if not os.path.exists(tiles_dir):
            os.mkdir(tiles_dir)
        self.tectonic_map = self.make_tectonic_map()
        self.warming_map = self.make_warming_map()
        if self.surface_pressure > 0.01:
            self.wind_map = self.make_wind_map()
        self.temp_map = self.make_temp_map()
        self.make_detail_h_map()
        self.tex_map = self.make_tex_map()

    def make_dir(self):
        """
        Creates directory for files.
        :return: None
        """
        if not os.path.exists(self.dir_path):
            os.mkdir(self.dir_path)

    def make_tectonic_arr(self):
        """
        Converts base height map into grey-scale npy arr.
        :return: None
        """
        base_map_path = os.path.join(
            self.dir_path, BASE_MAP_NAME + HEIGHTFIELD_SUFFIX)
        height_field = HeightField(base_map_path)
        width = BASE_MAP_WIDTH
        height = height_field.n_rows
        arr = np.ndarray((height, width), np.float32)

        for y, row in enumerate(height_field.filled_rows):
            arr[y] = row
        for row in arr:
            assert any(value for value in row), row

        # get path to file to save in
        height_map_path = os.path.join(self.dir_path, HEIGHT_MAP_NAME)

        np.save(height_map_path, arr)

    def call_planet_subprocess(self):
        # we need to change working directory to planet_gen path
        initial_dir = os.curdir
        os.chdir(settings.PLANET_GEN_DIR)
        base_map_path = os.path.join(self.dir_path, BASE_MAP_NAME)
        # For some unfathomable reason,
        # subprocess breaks when this command is run.
        # It seems to only apply a select few of the arguments passed.
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

    def make_tectonic_map(self):
        """
        Creates cube map from lat-lon map
        :return: None
        """
        self.call_planet_subprocess()
        self.make_tectonic_arr()
        height_map_path = os.path.join(self.dir_path, HEIGHT_MAP_NAME)
        lat_lon_map = GreyLatLonMap(
            height=1302, width=2048, path=height_map_path)  # load from file
        cube_map = GreyCubeMap(height=1024, width=1536)
        make_tectonic_cube(cube_map, lat_lon_map, self)

        return cube_map

    def make_warming_map(self):
        """
        Creates a map that stores information about warming areas of
        the planet surface.
        :return: TMap
        """
        return make_warming_map(
            height_map=self.tectonic_map,
            rel_res=0.5,  # relative resolution
            mean_temp=self.mean_temp,
            base_atm=self.surface_pressure,
            atm_warming=self.atm_warming,
            base_gravity=self.surface_gravities,
            radius=self.radius)

    def make_wind_map(self):
        return make_wind_map(
            self.warming_map,
            self.seed + 100,
            self.mass,
            self.radius,
            self.surface_pressure)

    def make_temp_map(self):
        """
        Creates temperature cube map from height map + other
        information about planet. (mean temp, mass, atmosphere, etc)
        :return: None
        """

    def make_detail_h_map(self):
        if self.height_map is None:
            # self.height_map = GreyCubeMap(height=2048, width=3072)
            # self.height_map = GreyCubeMap(height=1024, width=1536)
            self.height_map = GreyCubeMap(height=512, width=768)
        make_height_detail(self.height_map, self)

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
        self.tectonic_map.write_png(os.path.join(
            self.dir_path, 'height_cube.png'))
        self.warming_map.write_png(os.path.join(self.dir_path, 'warming.png'))
        self.height_map.write_png(
            os.path.join(self.dir_path, 'height_detail.png'))
        # todo: temp + others

    def write_cache(self) -> None:
        """
        Writes data to cache so that it can be accessed again quickly
        if spheroid needs to be re-created.
        :return: None
        """
        self.tectonic_map.save(os.path.join(self.dir_path, 'height_cube.npy'))
        self.height_map.save(os.path.join(self.dir_path, 'height_detail.npy'))

    @property
    def dir_path(self):
        return self._dir_path or os.path.join(OUT_PATH, self.uid)


class HeightField:
    """
    Handles information from height field file.
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
        Gets range of rows with useful data.
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


class Tile:
    """
    Handles generation of data for a tile belonging to a Spheroid.
    """

    def __init__(self, spheroid, face, parent=None, p1=(-1, -1), p2=(1, 1)):
        """
        Initializes sub-tile of a spheroid.
        :param spheroid: Spheroid
        :param parent: tile parent
        :param face: index of the cube face on which this tile resides.
        :param p1: lower left tile corner position, with valid range
                being (-1, 1)
        :param p2: upper right tile corner position, with valid range
                being (-1, 1)
        """
        # validate data
        if p1[0] > p2[0] or p1[1] > p2[1]:
            raise ValueError(
                'p1, p2 mismatch: p1: {}, p2: {}'.format(p1, p2))
        self.spheroid = spheroid
        self.parent = parent
        self.face = face
        self.p1 = p1
        self.p2 = p2
        self.rel_width = p2[0] - p1[0]  # width relative to spheroid
        self.radius = spheroid.radius
        self.seed = spheroid.seed  # should use same height fractals, etc

        # tile maps
        self.height_map = None

        self.sub_tiles = []

        self.build()  # build maps

    def make_sub_tile(self, index):
        if not 0 <= index < 4:
            raise ValueError('Unexpected index received: {}'.format(index))
        # todo

    def build(self) -> None:
        """
        Creates height, color, etc map.
        :return: None
        """
        if not os.path.exists(self.dir_path):
            os.mkdir(self.dir_path)
        self.make_height_map()

    def make_height_map(self) -> None:
        """
        Creates height map.
        :return:
        """
        # create height_map if it does not yet exist.
        self.height_map = self.height_map or GreyTileMap(
            width=1024, height=1024,
            p1=self.p1, p2=self.p2, cube_face=self.face
        )
        make_height_detail(self.height_map, self)

    def write_debug_png(self) -> None:
        """
        Writes maps to png files for debug purposes
        :return:
        """
        self.height_map.write_png(os.path.join(
            self.dir_path, 'height.png'))

    def write_cache(self) -> None:
        """
        Writes data to cache so that it can be accessed again quickly
        if tile needs to be re-created.
        :return: None
        """
        self.height_map.save(os.path.join(self.dir_path, 'height.npy'))

    @property
    def dir_path(self) -> str:
        """
        Returns the directory to which tile should store data
        (such as cached height, texture, etc maps) and
        other output (such as debug images, etc).
        :return: str
        """
        return os.path.join(
            self.spheroid.dir_path, 'tiles', str(self.pos_hash))

    @property
    def pos_hash(self) -> int:
        """
        Produces a hash unique to the tiles position.
        Tiles with identical positions (same face, p1 and p2) will
        share hashes.
        Hashes are -not- dependant on Spheroid, so all tiles with
        face=1, p1=(-1, -1), p2=(1, 1) will have the same hash, even
        if they are members of different spheroids.
        Tiles therefor should be stored within
        :return:
        """
        return hash((self.face, self.p1, self.p2))

    @property
    def tectonic_map(self):
        return self.spheroid.tectonic_map
