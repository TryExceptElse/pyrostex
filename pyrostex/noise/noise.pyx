"""
Handles use of fast noise library
"""


cdef class PyFastNoise:
    """
    Cython class wrapping the C++ FastNoise class
    """

    def __cinit__(self):
        self.n = FastNoise()

    # getter / setters

    @property
    def seed(self):
        return self.n.GetSeed()

    @seed.setter
    def seed(self, seed):
        self.n.SetSeed(int(seed))

    @property
    def frq(self):
        return self.n.GetFrequency()

    @frq.setter
    def frq(self, frq):
        self.n.SetFrequency( frq)

    @property
    def fractal_octaves(self):
        return self.n.GetFractalOctaves()

    @fractal_octaves.setter
    def fractal_octaves(self, octaves):
        self.n.SetFractalOctaves(int(octaves))

    @property
    def lacunarity(self):
        return self.n.GetFractalLacunarity()

    @lacunarity.setter
    def lacunarity(self, lacunarity):
        self.n.SetFractalLacunarity(lacunarity)

    @property
    def fractal_gain(self):
        return self.n.GetFractalGain()

    @fractal_gain.setter
    def fractal_gain(self, gain):
        self.n.SetFractalGain(gain)

    # 2d

    cpdef float get_simplex_2d(PyFastNoise self, float x, float y):
        return self.n.GetSimplex(x, y)

    cpdef float get_perlin_2d(PyFastNoise self, float x, float y):
        return self.n.GetPerlin(x, y)

    cpdef float get_simplex_fractal_2d(PyFastNoise self, float x, float y):
        return self.n.GetSimplexFractal(x, y)

    cpdef float get_perlin_fractal_2d(PyFastNoise self, float x, float y):
        return self.n.GetPerlinFractal(x, y)

    cpdef float get_simplex_3d(PyFastNoise self, float x, float y, float z):
        return self.n.GetSimplex(x, y, z)

    cpdef float get_perlin_3d(PyFastNoise self, float x, float y, float z):
        return self.n.GetPerlin(x, y, z)

    cpdef float get_simplex_fractal_3d(
            PyFastNoise self, float x, float y, float z):
        return self.n.GetSimplexFractal(x, y, z)

    cpdef float get_perlin_fractal_3d(
            PyFastNoise self, float x, float y, float z):
        return self.n.GetPerlinFractal(x, y, z)
        
    
    cdef float get_simplex_2d_          (PyFastNoise self, const vec2 p) nogil:
        return self.n.GetSimplex(p.x, p.y)
        
    cdef float get_simplex_fractal_2d_  (PyFastNoise self, const vec2 p) nogil:
        return self.n.GetSimplexFractal(p.x, p.y)
        
    cdef float get_perlin_2d_           (PyFastNoise self, const vec2 p) nogil:
        return self.n.GetPerlin(p.x, p.y)
        
    cdef float get_perlin_fractal_2d_   (PyFastNoise self, const vec2 p) nogil:
        return self.n.GetPerlinFractal(p.x, p.y)
        
    cdef float get_simplex_3d_          (PyFastNoise self, const vec3 p) nogil:
        return self.n.GetPerlin(p.x, p.y, p.z)
        
    cdef float get_simplex_fractal_3d_  (PyFastNoise self, const vec3 p) nogil:
        return self.n.GetSimplexFractal(p.x, p.y, p.z)
        
    cdef float get_perlin_3d_           (PyFastNoise self, const vec3 p) nogil:
        return self.n.GetPerlin(p.x, p.y, p.z)
        
    cdef float get_perlin_fractal_3d_   (PyFastNoise self, const vec3 p) nogil:
        return self.n.GetPerlinFractal(p.x, p.y, p.z)
