"""
Sample script for manually testing functionality of pyrostex

Creates a sample Spheroid and writes all debug information to
test/resources/out/test_spheroid
"""

from time import time

from pyrostex.procede import Spheroid
from settings import ROOT_PATH


def make_sample_spheroid():
    spheroid_dir = ROOT_PATH + '/test/resources/out/test_spheroid'
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
    print('Done')


if __name__ == '__main__':
    make_sample_spheroid()
