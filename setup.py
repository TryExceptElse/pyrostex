"""
setup script for pyrostex

example use; building extensions:
    python setup.py build_ext --inplace --debug --test
"""
import os
import subprocess as sub

from distutils.core import setup, Extension
from Cython.Build import cythonize
from sys import argv
from zipfile import ZipFile
from cymacro import ExtExpCol

from simd_setup import BuildCLib, c_libs
from settings import FLAGS_PXI_PATH, PLANET_GEN_DIR, PLANET_ZIP, \
    PLANET_GEN_EXE, PLANET_GEN_PATH, NOISE_DIR, SIMD_NOISE_DIR

SIMD_NOISE_SOURCES = os.path.join(SIMD_NOISE_DIR, 'FastNoiseSIMD')

#######################################################################
# READ INPUT


def parse_args():
    # parse custom arguments
    flags = {  # names flags that will be looked for
        'debug',  # indicates whether maps, debug messages should be printed
        'asserts',  # indicates whether asserts are included in generated C(++)
        'test'
    }

    # read flags from argv
    flags = {flag: '--' + flag in argv for flag in flags}
    # remove custom flags from argv so that setup doesn't get confused
    [argv.remove('--' + flag) for flag in flags if '--' + flag in argv]
    return flags


#######################################################################
# Build planet from .zip


def build_planet():
    # extract planet.zip if needed
    if not os.path.exists(PLANET_GEN_DIR):
        print('Extracting \'planet\'.zip')
        os.mkdir(PLANET_GEN_DIR)
        # extract files
        with ZipFile(PLANET_ZIP, 'r') as zip_f:
            zip_f.extractall(PLANET_GEN_DIR)

    # if planet generator has not been built yet, do that.
    if not os.path.exists(PLANET_GEN_PATH):
        # build
        print('Building \'planet\' from sources')
        # store old directory so we can move back later
        old_path = os.path.realpath(os.curdir)
        os.chdir(PLANET_GEN_DIR)  # change directory
        # final call should look something like:
        # 'gcc planet.c -o planet -lm -O3'
        sub.call([
            'gcc',
            'planet.c',
            '-o', PLANET_GEN_EXE,
            '-lm',
            '-O3'
        ])
        os.chdir(old_path)  # move back to whatever previous directory was


#######################################################################
# GET FASTNOISE FROM GITHUB


def get_fast_noise():
    if not os.path.exists(NOISE_DIR):
        print('Cloning FastNoise')
        os.mkdir(NOISE_DIR)
        repo = 'https://github.com/Auburns/FastNoise.git'
        if os.system('git clone {} {}'.format(repo, NOISE_DIR)):
            raise ValueError('Could not clone FastNoise')


def get_fast_noise_simd():
    if not os.path.exists(SIMD_NOISE_DIR):
        print('Cloning FastNoise')
        os.mkdir(SIMD_NOISE_DIR)
        repo = 'https://github.com/Auburns/FastNoiseSIMD.git'
        if os.system('git clone {} {}'.format(repo, SIMD_NOISE_DIR)):
            raise ValueError('Could not clone FastNoise')


#######################################################################
# CREATE FLAGS.PXI


flags_content = """
# THIS IS A FILE GENERATED BY setup.py
# CHANGES MADE TO THIS FILE WILL BE OVERWRITTEN

DEF DEBUG = {debug}  # indicates whether maps, debug messages should be printed
DEF ASSERTS = {asserts}  # indicates whether asserts are included
"""


def create_flags_file(flags):
    # create flags.pxi
    content = flags_content.format_map(flags)

    try:
        # check if flags actually needs to be changed
        # avoiding unneeded writes to flags.pxi means that the files will
        # only be cythonized if actually required.
        with open(FLAGS_PXI_PATH, 'r+') as flags_pxi:
            eq = flags_pxi.read() == content
    except IOError:
        eq = False

    if not eq:
        with open(FLAGS_PXI_PATH, 'w+') as flags_pxi:
            flags_pxi.write(content)


#######################################################################
# CREATE EXTENSIONS AND RUN SETUP


def set_up_project():
    flags = parse_args()
    if any([cmd in argv for cmd in ('build', 'build_ext', 'build_clib')]):
        build_planet()
        get_fast_noise()
        get_fast_noise_simd()
        create_flags_file(flags)

    # get test extensions
    test_extensions = [
        Extension(
            name='test.cy_mathutils_test',
            sources=['test/cy_mathutils_test.pyx'],
        ),
    ]

    macro_expander = ExtExpCol()
    print(argv)

    # run setup
    setup(
        name='pyrostex',
        libraries=c_libs,
        cmdclass={
            'build_clib': BuildCLib
        },
        ext_modules=cythonize(macro_expander(
            [
                Extension(
                    name='pyrostex.map',
                    sources=['pyrostex/map.pyx.cm'],
                    extra_compile_args=["-ffast-math", "-Ofast"],
                ),
                Extension(
                    name='pyrostex.brush',
                    sources=['pyrostex/brush.pyx'],
                    extra_compile_args=["-ffast-math", "-Ofast"],
                ),
                Extension(
                    name='pyrostex.temp',
                    sources=['pyrostex/temp.pyx'],
                    extra_compile_args=["-ffast-math", "-Ofast"]
                ),
                Extension(
                    name='pyrostex.height',
                    sources=['pyrostex/height.pyx'],
                    language='c++',
                    extra_compile_args=["-fopenmp", '-Ofast'],
                    extra_link_args=['-fopenmp'],
                ),
                Extension(
                    name='pyrostex.wind',
                    sources=['pyrostex/wind.pyx'],
                    language='c++',
                    extra_compile_args=["-ffast-math", "-Ofast"]
                ),
                Extension(
                    name='pyrostex.noise.noise',
                    sources=[
                        'pyrostex/noise/noise.pyx',
                        NOISE_DIR + '/FastNoise.cpp'
                    ],
                    language="c++",
                    extra_compile_args=[
                        "-ffast-math",
                        "-Ofast",
                        '-std=c++11',
                        '-msse', '-msse2'
                    ],
                ),
                Extension(
                    name='pyrostex.noise.simdnoise',
                    sources=[
                        'pyrostex/noise/simdnoise.pyx',
                        SIMD_NOISE_SOURCES + '/FastNoiseSIMD.cpp',
                        SIMD_NOISE_SOURCES + '/FastNoiseSIMD_internal.cpp',
                        SIMD_NOISE_SOURCES + '/FastNoiseSIMD_neon.cpp',
                    ],
                    language="c++",
                    extra_compile_args=[
                        # "-ffast-math",
                        "-Ofast",
                        '-std=c++11',
                    ],
                ),
            ] + (test_extensions if flags['test'] else [])
        ))
    )


if __name__ == '__main__':
    set_up_project()
