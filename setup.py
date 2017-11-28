from distutils.core import setup, Extension
from Cython.Build import cythonize


setup(
    name='pyrostex',
    ext_modules=cythonize(
        [
            Extension(
                name='pyrostex.map',
                sources=['pyrostex/map.pyx'],
                extra_compile_args=["-ffast-math", "-Ofast"]
            ),
            Extension(
                name='pyrostex.height',
                sources=['pyrostex/height.pyx'],
                extra_compile_args=["-ffast-math", "-Ofast"]
            ),
            Extension(
                name='pyrostex.temp',
                sources=['pyrostex/temp.pyx'],
                extra_compile_args=["-ffast-math", "-Ofast"]
            ),
            Extension(
                name='pyrostex.wind',
                sources=['pyrostex/wind.pyx'],
                language='c++',
                extra_compile_args=["-ffast-math", "-Ofast"]
            ),
            Extension(
                name='pyrostex.v_map',
                sources=['pyrostex/v_map.pyx'],
                extra_compile_args=["-ffast-math", "-Ofast"],
            ),
            Extension(
                name='pyrostex.noise.noise',
                sources=[
                    'pyrostex/noise/noise.pyx',
                    'pyrostex/noise/FastNoise.cpp'
                ],
                language="c++",
                extra_compile_args=["-ffast-math", "-Ofast"],
            ),
        ]
    ),
)
