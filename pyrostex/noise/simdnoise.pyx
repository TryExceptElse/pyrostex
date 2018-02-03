
from libc.stdlib cimport free

cdef enum FractalType:
    FBM, Billow, RigidMulti


cdef class PyFastNoiseSIMD:
    """
    Cython class wrapping the C++ FastNoise class
    """

    def __cinit__(self):
        self._init_wrapped_noise()

    def __dealloc__(self):
        free(self.n)

    cdef void _init_wrapped_noise(self):
        self.n = FastNoiseSIMD.NewFastNoiseSIMD()

    # getter / setters

    @property
    def seed(self):
        return self.n.GetSeed()

    @seed.setter
    def seed(self, seed):
        self.n.SetSeed(int(seed))

    @property
    def frq(self):
        raise NotImplementedError

    @frq.setter
    def frq(self, frq):
        self.n.SetFrequency(frq)

    @property
    def fractal_octaves(self):
        raise NotImplementedError

    @fractal_octaves.setter
    def fractal_octaves(self, octaves):
        self.n.SetFractalOctaves(int(octaves))

    @property
    def lacunarity(self):
        raise NotImplementedError

    @lacunarity.setter
    def lacunarity(self, lacunarity):
        self.n.SetFractalLacunarity(lacunarity)

    @property
    def fractal_gain(self):
        raise NotImplementedError

    @fractal_gain.setter
    def fractal_gain(self, gain):
        self.n.SetFractalGain(gain)

    @property
    def fractal_type(self):
        raise NotImplementedError

    @fractal_type.setter
    def fractal_type(self, unicode fractal_type):
        if fractal_type == 'FBM':
            self.n.SetFractalType(FractalType.FBM)
        elif fractal_type == 'Billow':
            self.n.SetFractalType(FractalType.Billow)
        elif fractal_type == 'RigidMulti':
            self.n.SetFractalType(FractalType.RigidMulti)

    # Noise generation methods

    cdef void fill_simplex_fractal_set(
            self,
            float *noise_set,
            FastNoiseVectorSet *vector_set) nogil:
        self.n.FillSimplexFractalSet(noise_set, vector_set)
