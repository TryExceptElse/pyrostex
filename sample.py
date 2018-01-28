"""
Sample script for manually testing functionality of pyrostex.

Creates a sample Spheroid and writes all debug information to
test/resources/out/test_spheroid.

Displayed plot can be changed in scale by passing tile width in meters
as an argument to the script.
"""
import sys
import os
import shutil
import matplotlib.pyplot as plt
import numpy as np
import itertools as itr

from mpl_toolkits.mplot3d import Axes3D
from time import time
from matplotlib import cm
from matplotlib.ticker import LinearLocator, FormatStrFormatter

from pyrostex.procede import Spheroid, Tile
from settings import ROOT_PATH


def make_sample_spheroid(view_w):
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
    print('Creating sample sub-tile')
    if view_w > spheroid.radius * 2:
        raise ValueError('Passed view dimension too large: {} > {}'
                         .format(view_w, spheroid.radius * 2))
    rw = view_w / 2 / spheroid.radius  # relative width
    tile = Tile(spheroid, 0, None, (-rw, -rw), (rw, rw))
    tile.write_debug_png()
    print('Done')
    print('\nGraphing')

    h_map = tile.height_map
    fig = plt.figure()
    ax = fig.gca(projection='3d')

    # Make data.
    d_samples = 100
    X = np.linspace(-view_w / 2, view_w / 2, d_samples)
    Y = np.linspace(-view_w / 2, view_w / 2, d_samples)
    Z = np.ndarray((len(X), len(Y)), np.float32)
    for i, (x, y) in enumerate(itr.product(X, Y)):
        rel_x = x / view_w + 0.5
        rel_y = y / view_w + 0.5
        Z[i // d_samples][i % d_samples] = h_map.v_from_rel_xy((rel_x, rel_y))
    X, Y = np.meshgrid(X, Y)
    print("d_samples: " + str(d_samples))
    print('sub-tile shape: ({w}, {w})'.format(w=view_w))

    # Plot the surface.
    surf = ax.plot_surface(X, Y, Z, cmap=cm.coolwarm, rstride=1, cstride=1,
                           linewidth=0, antialiased=False)

    # Customize the z axis.
    ax.set_zlim(-view_w / 2, view_w / 2)
    ax.zaxis.set_major_locator(LinearLocator(10))
    ax.zaxis.set_major_formatter(FormatStrFormatter('%.02f'))

    # Add a color bar which maps values to colors.
    fig.colorbar(surf, shrink=0.5, aspect=5)

    plt.show()


if __name__ == '__main__':
    view_width = float(sys.argv[1]) if len(sys.argv) > 1 else 100e3
    make_sample_spheroid(view_width)
