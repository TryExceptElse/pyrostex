"""
Sample script for manually testing functionality of pyrostex

Creates a sample Spheroid and writes all debug information to
test/resources/out/test_spheroid
"""
import os
import shutil

from time import time

from pyrostex.procede import Spheroid, Tile
from settings import ROOT_PATH


def make_sample_spheroid():
    spheroid_dir = ROOT_PATH + '/test/resources/out/test_spheroid'
    if os.path.exists(spheroid_dir):
        print('clearing spheroid dir')
        shutil.rmtree(spheroid_dir)
    print('creating spheroid')
    start_t = time()
    spheroid = Spheroid(
        124,  # seed
        'rock',  # type
        1e26,  # mass
        220,  # mean temp
        5e6,  # radius
        0.5,  # gravities
        0.1,  # atm
        dir_path=spheroid_dir
    )
    end_t = time()
    print('Created Spheroid. Elapsed time: {}'.format(end_t - start_t))
    print('writing debug graphics')
    spheroid.write_debug_png()
    print('Wrote debug graphics')
    print('')
    print('Creating sample sub-tile, 100x100km')
    rw = 100e3 / 2 / spheroid.radius  # relative width
    tile100 = Tile(spheroid, 0, None, (-rw, -rw), (rw, rw))
    tile100.write_debug_png()
    print('')
    print('Creating sample sub-tile, 1x1km')
    rw = 1e3 / 2 / spheroid.radius  # relative width
    tile1 = Tile(spheroid, 0, None, (-rw, -rw), (rw, rw))
    tile1.write_debug_png()
    print('Done')


if __name__ == '__main__':
    make_sample_spheroid()
