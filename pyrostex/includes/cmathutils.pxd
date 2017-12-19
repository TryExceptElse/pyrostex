# cython: infer_types=True, nonecheck=False, language_level=3,

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

ctypedef float mu_type

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
    vec3    vec3Negate      (const vec3 v)
    int     vec3IsZero      (const vec3 v)
    vec3    vec3Add         (const vec3 a, const vec3 b)
    vec3    vec3Subtract    (const vec3 a, const vec3 b)
    vec3    vec3Multiply    (vec3 v, const mu_type n)
    mu_type vec3DotProduct  (const vec3 a, const vec3 b)
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
