from distutils.core import setup, Extension
from Cython.Build import cythonize


setup(
    name='pyrostex',
    ext_modules=cythonize(Extension(
        name='pyrostex.map',
        sources=['pyrostex/map.pyx'],
        extra_compile_args=["-ffast-math", "-Og"]
    )),
)
