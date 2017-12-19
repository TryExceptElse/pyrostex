# pyrostex
Python Procedural Spherical Texture

For creation and use of procedural textures for spheres, 
intended for use with procedural planet generation


### Building:
run setup.py build_ext inplace to build cython extensions

    python3 setup.py build_ext --inplace

asserts can be built by passing '--asserts' to setup.py

    python3 setup.py build_ext --inplace --asserts

### Test Usage:
run sample.py for a simple test of functionality

sample use of procede.Spheroid:

    # create Spheroid
    s = Spheroid(
        124,  # seed - any int
        'rock',  # type
        1e26,  # mass
        220,  # mean temp at surface
        5e6,  # radius
        0.5,  # gravities at surface
        0.1,  # atmospheric pressure in atm's
        dir_path=spheroid_dir  # path in which to write output and/or caches
    )

    # write visualizations of all maps to dir_path
    spheroid.write_debug_png()

In the future, additional methods to access generated maps at
varying levels of detail will be added.
