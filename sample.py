from time import time

from pyrostex.procede import Spheroid
from settings import ROOT_PATH


def make_sample_spheroid():
    spheroid_dir = ROOT_PATH + '/test/resources/out/test_spheroid'
    print('creating spheroid')
    start_t = time()
    spheroid = Spheroid(
        124,
        'rock',
        1e26,
        220,
        5e6,
        0.5,
        0.1,
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
