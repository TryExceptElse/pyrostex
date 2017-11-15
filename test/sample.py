from pyrostex.procede import Spheroid
from settings import ROOT_PATH


def make_sample_spheroid():
    spheroid_dir = ROOT_PATH + '/test/resources/out/test_spheroid'
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
    spheroid.write_debug_png()


if __name__ == '__main__':
    make_sample_spheroid()