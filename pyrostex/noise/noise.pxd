from ..includes.cmathutils cimport vec2, vec3


cdef extern from "FastNoise.h":
    cdef cppclass FastNoise:
        FastNoise() except +

        # getter / setters
        void SetSeed(int seed) nogil
        int GetSeed() nogil
        void SetFrequency(float frequency) nogil
        float GetFrequency() nogil
        void SetFractalOctaves(int octaves) nogil
        int GetFractalOctaves() nogil
        void SetFractalLacunarity(float lacunarity) nogil
        float GetFractalLacunarity() nogil
        void SetFractalGain(float gain) nogil
        float GetFractalGain() nogil

        # 2d
        float GetSimplex(float x, float y) nogil
        float GetPerlin(float x, float y) nogil
        float GetSimplexFractal(float x, float y) nogil
        float GetPerlinFractal(float x, float y) nogil

        # 3d
        float GetSimplex(float x, float y, float z) nogil
        float GetPerlin(float x, float y, float z) nogil
        float GetSimplexFractal(float x, float y, float z) nogil
        float GetPerlinFractal(float x, float y, float z) nogil


cdef class PyFastNoise:
    cdef FastNoise n  # wrapped C++ instance
    cpdef float get_simplex_2d(PyFastNoise self, float x, float y)
    cpdef float get_simplex_fractal_2d(PyFastNoise self, float x, float y)
    cpdef float get_perlin_2d(PyFastNoise self, float x, float y)
    cpdef float get_perlin_fractal_2d(PyFastNoise self, float x, float y)
    cpdef float get_simplex_3d(PyFastNoise self, float x, float y, float z)
    cpdef float get_simplex_fractal_3d(
            PyFastNoise self, float x, float y, float z)
    cpdef float get_perlin_3d(PyFastNoise self, float x, float y, float z)
    cpdef float get_perlin_fractal_3d(
            PyFastNoise self, float x, float y, float z)
    
    cdef float get_simplex_2d_           (PyFastNoise self, const vec2 p) nogil
    cdef float get_simplex_fractal_2d_   (PyFastNoise self, const vec2 p) nogil
    cdef float get_perlin_2d_            (PyFastNoise self, const vec2 p) nogil
    cdef float get_perlin_fractal_2d_    (PyFastNoise self, const vec2 p) nogil
    cdef float get_simplex_3d_           (PyFastNoise self, const vec3 p) nogil
    cdef float get_simplex_fractal_3d_   (PyFastNoise self, const vec3 p) nogil
    cdef float get_perlin_3d_            (PyFastNoise self, const vec3 p) nogil
    cdef float get_perlin_fractal_3d_    (PyFastNoise self, const vec3 p) nogil
