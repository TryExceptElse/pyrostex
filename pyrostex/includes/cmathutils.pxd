# cython: infer_types=True, nonecheck=False, boundscheck=False, language_level=3, initializedcheck=False

"""
Cython header declaring functions from ccVector and other vector and
matrix functions.

This module is intended to contain C replacements for functions and
methods from mathutils.

The C implementations of these functions come from ccVector, credit for
these implementations belong entirely to the ccore authors

Because the c header file ccVector contains an immense amount of
methods, they are not all re-declared here, instead, they should be
added to this file as they are needed.
"""

cimport cython

from libc.math cimport sin, cos, sqrt, pow, floor

ctypedef double ft

cdef extern from "ccVector.h":

    ###################################################################
    # STRUCTS
    ###################################################################

    # two-value vector
    ctypedef struct vec2:
        ft x, y

    # three-value vector
    ctypedef struct vec3:
        ft x, y, z

    # four-value vector
    ctypedef struct vec4:
        ft x, y, z, w

    # 3x3 matrix
    ctypedef ft[3][3] mat3x3

    # 4x4 matrix
    ctypedef ft[4][4] mat4x4

    ###################################################################
    # VEC 2 FUNCTIONS
    ###################################################################

    vec2    vec2Zero        ()                                          nogil
    vec2    vec2New         (const ft x, const ft y)                    nogil
    vec2    vec2Negate      (const vec2 v)                              nogil
    int     vec2IsZero      (const vec2 v)                              nogil
    vec2    vec2Add         (const vec2 a, const vec2 b)                nogil
    vec2    vec2Subtract    (const vec2 a, const vec2 b)                nogil
    vec2    vec2Multiply    (vec2 v, const ft n)                        nogil
    ft      vec2DotProduct  (const vec2 a, const vec2 b)                nogil
    ft      vec2Length      (const vec2 v)                              nogil
    vec2    vec2Normalize   (vec2 v)                                    nogil
    vec2    vec2Reflect     (const vec2 n, const vec2 r)                nogil
    vec2    vec2Mix         (const vec2 a, const vec2 b, const ft f)    nogil
    int     vec2Equal       (const vec2 a, const vec2 b)                nogil

    ###################################################################
    # VEC 3 FUNCTIONS
    ###################################################################

    vec3    vec3Zero        ()                                          nogil
    vec3    vec3New         (const ft x, const ft y, const ft z)        nogil
    vec3    vec3Negate      (const vec3 v)                              nogil
    int     vec3IsZero      (const vec3 v)                              nogil
    vec3    vec3Add         (const vec3 a, const vec3 b)                nogil
    vec3    vec3Subtract    (const vec3 a, const vec3 b)                nogil
    vec3    vec3Multiply    (vec3 v, const ft n)                        nogil
    ft      vec3DotProduct  (const vec3 a, const vec3 b)                nogil
    vec3    vec3CrossProduct(const vec3 a, const vec3 b)                nogil
    ft      vec3Length      (const vec3 v)                              nogil
    vec3    vec3Normalize   (vec3 v)                                    nogil
    vec3    vec3Reflect     (const vec3 n, const vec3 r)                nogil
    vec3    vec3Mix         (const vec3 a, const vec3 b, const ft f)    nogil
    int     vec3Equal       (const vec3 a, const vec3 b)                nogil
    
    ###################################################################
    # VEC 4 FUNCTIONS
    ###################################################################
    
    vec4    vec4Zero        ()                                          nogil
    vec4    vec4New         (const ft x, const ft y,
                             const ft z, const ft w)                    nogil
    vec4    vec4Negate      (const vec4 v)                              nogil
    int     vec4IsZero      (const vec4 v)                              nogil
    vec4    vec4Add         (const vec4 a, const vec4 b)                nogil
    vec4    vec4Subtract    (const vec4 a, const vec4 b)                nogil
    vec4    vec4Multiply    (vec4 v, const ft n)                        nogil
    ft      vec4DotProduct  (const vec4 a, const vec4 b)                nogil
    ft      vec4Length      (const vec4 v)                              nogil
    vec4    vec4Normalize   (vec4 v)                                    nogil
    vec4    vec4Reflect     (const vec4 n, const vec4 r)                nogil
    vec4    vec4Mix         (const vec4 a, const vec4 b, const ft f)    nogil
    int     vec4Equal       (const vec4 a, const vec4 b)                nogil
    
    ###################################################################
    # MAT 3X3 FUNCTIONS
    ###################################################################
    
    void    mat3x3Zero              (mat3x3 m)                                  nogil
    int     mat3x3IsZero            (mat3x3 m)                                  nogil
    void    mat3x3Add               (mat3x3 m, const mat3x3 a, const mat3x3 b)  nogil
    void    mat3x3Subtract          (mat3x3 m, const mat3x3 a, const mat3x3 b)  nogil
    void    mat3x3Copy              (mat3x3 dest, const mat3x3 source)          nogil
    void    mat3x3Identity          (mat3x3 m)                                  nogil
    void    mat3x3MultiplyScalar    (mat3x3 m, const ft n)                      nogil
    vec3    mat3x3MultiplyVector    (const mat3x3 a, const vec3 b)              nogil
    void    mat3x3MultiplyMatrix    (mat3x3 m, const mat3x3 a, const mat3x3 b)  nogil
    vec3    mat3x3GetRow            (mat3x3 m, const unsigned int n)            nogil
    vec3    mat3x3GetCol            (mat3x3 m, const unsigned int n)            nogil
    void    mat3x3Transpose         (mat3x3 m, mat3x3 n)                        nogil
    int     mat3x3Equal             (mat3x3 a, mat3x3 b)                        nogil
    
    ###################################################################
    # MAT 4X4 FUNCTIONS
    ###################################################################
    
    void    mat4x4Zero              (mat4x4 m)
    int     mat4x4IsZero            (mat4x4 m)
    void    mat4x4Add               (mat4x4 m, const mat4x4 a, const mat4x4 b)
    void    mat4x4Subtract          (mat4x4 m, const mat4x4 a, const mat4x4 b)
    void    mat4x4Copy              (mat4x4 dest, const mat4x4 source)
    void    mat4x4Identity          (mat4x4 m)
    void    mat4x4MultiplyScalar    (mat4x4 m, const ft n)
    vec4    mat4x4MultiplyVector    (const mat4x4 a, const vec4 b)
    void    mat4x4MultiplyMatrix    (mat4x4 m, const mat4x4 a, const mat4x4 b)
    vec4    mat4x4GetRow            (mat4x4 m, const unsigned int n)
    vec4    mat4x4GetCol            (mat4x4 m, const unsigned int n)
    void    mat4x4Transpose         (mat4x4 m, mat4x4 n)
    int     mat4x4Equal             (mat4x4 a, mat4x4 b)


#######################################################################
# UTILITY FUNCTIONS
#######################################################################


cdef inline ft vec2Magnitude(const vec2 v) nogil:
    return sqrt(pow(v.x, 2) + pow(v.y, 2))


cdef inline ft vec3Magnitude(const vec3 v) nogil:
    return sqrt(pow(v.x, 2) + pow(v.y, 2) + pow(v.z, 2))


cdef inline ft vec4Magnitude(const vec4 v) nogil:
    return sqrt(pow(v.x, 2) + pow(v.y, 2) + pow(v.z, 2) + pow(v.w, 2))


# component multiplication of vectors


cdef inline vec2 vec2CompMult(const vec2 a, const vec2 b) nogil:
    return vec2New(a.x * b.x, a.y * b.y)


cdef inline vec3 vec3CompMult(const vec3 a, const vec3 b) nogil:
    return vec3New(a.x * b.x, a.y * b.y, a.z * b.z)


cdef inline vec4 vec4CompMult(const vec4 a, const vec4 b) nogil:
    return vec4New(a.x * b.x, a.y * b.y, a.z * b.z, a.w * b.w)


# vector component floor


cdef inline vec2 vec2Floor(const vec2 v) nogil:
    return vec2New(floor(v.x), floor(v.y))


cdef inline vec3 vec3Floor(const vec3 v) nogil:
    return vec3New(floor(v.x), floor(v.y), floor(v.z))


cdef inline vec4 vec4Floor(const vec4 v) nogil:
    return vec4New(floor(v.x), floor(v.y), floor(v.z), floor(v.w))


# vector component modulo


cdef inline vec2 vec2Mod(const vec2 v, const ft mod) nogil:
    return vec2New(v.x % mod, v.y % mod)


cdef inline vec3 vec3Mod(const vec3 v, const ft mod) nogil:
    return vec3New(v.x % mod, v.y % mod, v.z % mod)


cdef inline vec4 vec4Mod(const vec4 v, const ft mod) nogil:
    return vec4New(v.x % mod, v.y % mod, v.z % mod, v.w % mod)


# vector component fract


cdef inline vec2 vec2Fract(const vec2 v) nogil:
    return vec2New(v.x % 1, v.y % 1)


cdef inline vec3 vec3Fract(const vec3 v) nogil:
    return vec3New(v.x % 1, v.y % 1, v.z % 1)
    

cdef inline vec4 vec4Fract(const vec4 v) nogil:
    return vec4New(v.x % 1, v.y % 1, v.z % 1, v.w % 1)


# vector scalar add


cdef inline vec2 vec2ScalarAdd(const vec2 v, const ft addend) nogil:
    return vec2New(v.x + addend, v.y + addend)


cdef inline vec3 vec3ScalarAdd(const vec3 v, const ft addend) nogil:
    return vec3New(v.x + addend, v.y + addend, v.z + addend)


cdef inline vec4 vec4ScalarAdd(const vec4 v, const ft addend) nogil:
    return vec4New(v.x + addend, v.y + addend, v.z + addend, v.w + addend)


# vector scalar subtract


cdef inline vec2 vec2ScalarSub(const vec2 v, const ft sub) nogil:
    return vec2New(v.x - sub, v.y - sub)


cdef inline vec3 vec3ScalarSub(const vec3 v, const ft sub) nogil:
    return vec3New(v.x - sub, v.y - sub, v.z - sub)


cdef inline vec4 vec4ScalarSub(const vec4 v, const ft sub) nogil:
    return vec4New(v.x - sub, v.y - sub, v.z - sub, v.w - sub)


# vector scalar square root


cdef inline vec2 vec2Sqrt(const vec2 v) nogil:
    return vec2New(sqrt(v.x), sqrt(v.y))

cdef inline vec3 vec3Sqrt(const vec3 v) nogil:
    return vec3New(sqrt(v.x), sqrt(v.y), sqrt(v.z))

cdef inline vec4 vec4Sqrt(const vec4 v) nogil:
    return vec4New(sqrt(v.x), sqrt(v.y), sqrt(v.z), sqrt(v.w))


# other


@cython.wraparound(False)
@cython.initializedcheck(False)
cdef inline void negation_matrix(mat3x3 m) nogil:
    """
    Returns a matrix that inverts a vec3
    :param m mat3x3 matrix to store values in.
    """
    m[0][0] = -1
    m[0][1] = 0
    m[0][2] = 0
    m[1][0] = 0
    m[1][1] = -1
    m[1][2] = 0
    m[2][0] = 0
    m[2][1] = 0
    m[2][2] = -1
    # no return value.

cdef inline int vec3IsNegate(const vec3 a, const vec3 b) nogil:
    """
    Tests whether passed vectors are negated versions of each other
    :return bint
    """
    return a.x + b.x == 0 and a.y + b.y == 0 and a.z + b.z == 0


@cython.cdivision(True)
@cython.initializedcheck(False)
cdef inline void rotation_difference(mat3x3 r, const vec3 a, const vec3 b) nogil:
    """
    Finds the rotation matrix required to rotate vector a to align
    with vector b
    :param a vec3
    :param b vec3
    :return mat3x3
    """
    cdef vec3 v
    cdef ft s, c
    cdef mat3x3 vx, m

    # if a == b, no transform is needed
    if vec3Equal(a, b):
        mat3x3Identity(r)
        return
    # if a and b are directly opposed, return negation matrix
    if vec3IsNegate(a, b):
        negation_matrix(r)
        return

    v = vec3CrossProduct(b, a)
    c = vec3DotProduct(b, a)

    vx[0][0] = 0.
    vx[0][1] = -v.z
    vx[0][2] = v.y
    vx[1][0] = v.z
    vx[1][1] = 0.
    vx[1][2] = -v.x
    vx[2][0] = -v.y
    vx[2][1] = v.x
    vx[2][2] = 0.

    # R = I + [v]x + ([v]x)^2 * (1 / 1 + c)

    mat3x3Identity(r)  # set r to identity array
    mat3x3Add(r, r, vx)
    mat3x3MultiplyMatrix(m, vx, vx)
    mat3x3MultiplyScalar(
        m,
        (1. - c) / (pow(v.x, 2) + pow(v.y, 2) + pow(v.z, 2))  # s^2
    )
    mat3x3Add(r, r, m)  # r = r + m

    # result stored in passed mat3x3 mat. No return value
