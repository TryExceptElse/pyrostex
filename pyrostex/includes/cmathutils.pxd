# cython: infer_types=True, nonecheck=False, boundscheck=False, language_level=3,

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

from libc.math cimport sin, cos, sqrt, pow

ctypedef double mu_type

cdef extern from "ccVector.h":

    ###################################################################
    # STRUCTS
    ###################################################################

    # two-value vector
    ctypedef struct vec2:
        mu_type x, y

    # three-value vector
    ctypedef struct vec3:
        mu_type x, y, z

    # four-value vector
    ctypedef struct vec4:
        mu_type x, y, z, w

    # 3x3 matrix
    ctypedef mu_type[3][3] mat3x3

    # 4x4 matrix
    ctypedef mu_type[4][4] mat4x4

    ###################################################################
    # VEC 2 FUNCTIONS
    ###################################################################

    vec2    vec2Zero        ()
    vec2    vec2New         (const mu_type x, const mu_type y)
    vec2    vec2Negate      (const vec2 v)
    int     vec2IsZero      (const vec2 v)
    vec2    vec2Add         (const vec2 a, const vec2 b)
    vec2    vec2Subtract    (const vec2 a, const vec2 b)
    vec2    vec2Multiply    (vec2 v, const mu_type n)
    mu_type vec2DotProduct  (const vec2 a, const vec2 b)
    mu_type vec2Length      (const vec2 v)
    vec2    vec2Normalize   (vec2 v)
    vec2    vec2Reflect     (const vec2 n, const vec2 r)
    vec2    vec2Mix         (const vec2 a, const vec2 b, const mu_type f)
    int     vec2Equal       (const vec2 a, const vec2 b)

    ###################################################################
    # VEC 3 FUNCTIONS
    ###################################################################

    vec3    vec3Zero        ()
    vec3    vec3New         (const mu_type x, const mu_type y, const mu_type z)
    vec3    vec3Negate      (const vec3 v)
    int     vec3IsZero      (const vec3 v)
    vec3    vec3Add         (const vec3 a, const vec3 b)
    vec3    vec3Subtract    (const vec3 a, const vec3 b)
    vec3    vec3Multiply    (vec3 v, const mu_type n)
    mu_type vec3DotProduct  (const vec3 a, const vec3 b)
    vec3    vec3CrossProduct(const vec3 a, const vec3 b)
    mu_type vec3Length      (const vec3 v)
    vec3    vec3Normalize   (vec3 v)
    vec3    vec3Reflect     (const vec3 n, const vec3 r)
    vec3    vec3Mix         (const vec3 a, const vec3 b, const mu_type f)
    int     vec3Equal       (const vec3 a, const vec3 b)
    
    ###################################################################
    # VEC 4 FUNCTIONS
    ###################################################################
    
    vec4    vec4Zero        ()
    vec4    vec4Negate      (const vec4 v)
    int     vec4IsZero      (const vec4 v)
    vec4    vec4Add         (const vec4 a, const vec4 b)
    vec4    vec4Subtract    (const vec4 a, const vec4 b)
    vec4    vec4Multiply    (vec4 v, const mu_type n)
    mu_type vec4DotProduct  (const vec4 a, const vec4 b)
    mu_type vec4Length      (const vec4 v)
    vec4    vec4Normalize   (vec4 v)
    vec4    vec4Reflect     (const vec4 n, const vec4 r)
    vec4    vec4Mix         (const vec4 a, const vec4 b, const mu_type f)
    int     vec4Equal       (const vec4 a, const vec4 b)
    
    ###################################################################
    # MAT 3X3 FUNCTIONS
    ###################################################################
    
    void    mat3x3Zero              (mat3x3 m)
    int     mat3x3IsZero            (mat3x3 m)
    void    mat3x3Add               (mat3x3 m, const mat3x3 a, const mat3x3 b)
    void    mat3x3Subtract          (mat3x3 m, const mat3x3 a, const mat3x3 b)
    void    mat3x3Copy              (mat3x3 dest, const mat3x3 source)
    void    mat3x3Identity          (mat3x3 m)
    void    mat3x3MultiplyScalar    (mat3x3 m, const mu_type n)
    vec3    mat3x3MultiplyVector    (const mat3x3 a, const vec3 b)
    void    mat3x3MultiplyMatrix    (mat3x3 m, const mat3x3 a, const mat3x3 b)
    vec3    mat3x3GetRow            (mat3x3 m, const unsigned int n)
    vec3    mat3x3GetCol            (mat3x3 m, const unsigned int n)
    void    mat3x3Transpose         (mat3x3 m, mat3x3 n)
    int     mat3x3Equal             (mat3x3 a, mat3x3 b)
    
    ###################################################################
    # MAT 4X4 FUNCTIONS
    ###################################################################
    
    void    mat4x4Zero              (mat4x4 m)
    int     mat4x4IsZero            (mat4x4 m)
    void    mat4x4Add               (mat4x4 m, const mat4x4 a, const mat4x4 b)
    void    mat4x4Subtract          (mat4x4 m, const mat4x4 a, const mat4x4 b)
    void    mat4x4Copy              (mat4x4 dest, const mat4x4 source)
    void    mat4x4Identity          (mat4x4 m)
    void    mat4x4MultiplyScalar    (mat4x4 m, const mu_type n)
    vec4    mat4x4MultiplyVector    (const mat4x4 a, const vec4 b)
    void    mat4x4MultiplyMatrix    (mat4x4 m, const mat4x4 a, const mat4x4 b)
    vec4    mat4x4GetRow            (mat4x4 m, const unsigned int n)
    vec4    mat4x4GetCol            (mat4x4 m, const unsigned int n)
    void    mat4x4Transpose         (mat4x4 m, mat4x4 n)
    int     mat4x4Equal             (mat4x4 a, mat4x4 b)


#######################################################################
# UTILITY FUNCTIONS
#######################################################################


cdef inline mu_type vec2Magnitude(vec2 v):
    return sqrt(pow(v.x, 2) + pow(v.y, 2))

cdef inline mu_type vec3Magnitude(vec3 v):
    return sqrt(pow(v.x, 2) + pow(v.y, 2) + pow(v.z, 2))

cdef inline mu_type vec4Magnitude(vec4 v):
    return sqrt(pow(v.x, 2) + pow(v.y, 2) + pow(v.z, 2) + pow(v.w, 2))

@cython.wraparound(False)
@cython.initializedcheck(False)
cdef inline void negation_matrix(mat3x3 m):
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

cdef inline int vec3IsNegate(vec3 a, vec3 b):
    """
    Tests whether passed vectors are negated versions of each other
    :return bint
    """
    return a.x + b.x == 0 and a.y + b.y == 0 and a.z + b.z == 0

@cython.cdivision(True)
@cython.initializedcheck(False)
cdef inline void rotation_difference(mat3x3 r, vec3 a, vec3 b):
    """
    Finds the rotation matrix required to rotate vector a to align
    with vector b
    :param a vec3
    :param b vec3
    :return mat3x3
    """
    cdef vec3 v
    cdef mu_type s, c
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
    mat3x3Add(r, r, m)

    # result stored in passed mat3x3 mat. No return value
