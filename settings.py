from os import path

import platform

ROOT_PATH = path.abspath(path.dirname(__file__))
RESOURCES_DIR = path.join(ROOT_PATH, 'resources')
PLANET_GEN_DIR = path.join(ROOT_PATH, 'pgen')
PLANET_GEN_EXE = 'planet.exe' if platform.system() == 'Windows' else 'planet'
PLANET_GEN_PATH = path.join(PLANET_GEN_DIR, PLANET_GEN_EXE)
PLANET_ZIP = path.join(RESOURCES_DIR, 'planet.zip')
NOISE_DIR = path.join(ROOT_PATH, 'pyrostex', 'noise', 'fast')
SIMD_NOISE_DIR = path.join(ROOT_PATH, 'pyrostex', 'noise', 'fast_simd')
SIMD_NOISE_SOURCES = path.join(SIMD_NOISE_DIR, 'FastNoiseSIMD')
FLAGS_PXI_PATH = path.join(ROOT_PATH, 'pyrostex', 'flags.pxi')
TEST_PNG = path.join(ROOT_PATH, 'resources', 'out', 'test_out.png')
