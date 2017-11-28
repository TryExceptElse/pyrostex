cdef extern from "FastNoise.h":
    cdef cppclass FastNoise:
        FastNoise() except +

        # getter / setters
        void SetSeed(int seed)
        int GetSeed()
        void SetFrequency(float frequency)
        float GetFrequency()
        void SetFractalOctaves(int octaves)
        int GetFractalOctaves()
        void SetFractalLacunarity(float lacunarity)
        float GetFractalLacunarity()
        void SetFractalGain(float gain)
        float GetFractalGain()

        # 2d
        float GetSimplex(float x, float y)
        float GetPerlin(float x, float y)
        float GetSimplexFractal(float x, float y)
        float GetPerlinFractal(float x, float y)

        # 3d
        float GetSimplex(float x, float y, float z)
        float GetPerlin(float x, float y, float z)
        float GetSimplexFractal(float x, float y, float z)
        float GetPerlinFractal(float x, float y, float z)


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
