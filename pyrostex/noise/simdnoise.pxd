from ..includes.cmathutils cimport vec2, vec3


cdef extern from "fast_simd/FastNoiseSIMD/FastNoiseSIMD.h":
    cdef cppclass FastNoiseSIMD:
        enum FractalType "FastNoiseSIMD::FractalType": FBM, Billow, RigidMulti

        @staticmethod
        FastNoiseSIMD *NewFastNoiseSIMD() except +

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
        void SetFractalType(FractalType fractalType) nogil
        FractalType GetFractalType() nogil

        void FillSimplexFractalSet(
            float *noiseSet,
            FastNoiseVectorSet *vectorSet) nogil


    cdef cppclass FastNoiseVectorSet:
        int size
        float* xSet
        float* ySet
        float* zSet

        # Only used for sampled vector sets
        int sampleScale
        int sampleSizeX
        int sampleSizeY
        int sampleSizeZ

        FastNoiseVectorSet() except +

        void Free()

        void SetSize(int _size)


cdef class PyFastNoiseSIMD:
    cdef FastNoiseSIMD *n  # wrapped C++ instance

    cdef void _init_wrapped_noise(self)

    cdef void fill_simplex_fractal_set(
            self,
            float *noise_set,
            FastNoiseVectorSet *vector_set) nogil
