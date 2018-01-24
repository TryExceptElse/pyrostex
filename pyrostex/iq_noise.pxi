# cython: infer_types=True, boundscheck=False, nonecheck=False, language_level=3, initializedcheck=False

"""
 The MIT License
 Copyright © 2016 Inigo Quilez
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


 Computing normals analytically has the benefit of being faster if you need them often,
 while numerical normals are easier to filter for antialiasing. See line 200.

 More info: http://iquilezles.org/www/articles/morenoise/morenoise.htm

 See this too: https://www.shadertoy.com/view/XsXfRH

 Proper noise code isolated here: https://www.shadertoy.com/view/XsXfRH


 converted to cython from code written by Inigo Quilez.
"""


from .includes.cmathutils cimport vec3, vec4, \
    vec3New, vec3Zero, vec3Multiply, vec3Add, vec3Floor, vec3Fract, \
    vec3CompMult, \
    vec4New
from libc.math cimport floor, sin


cdef float hash(float n) nogil:
    return (sin(n)*753.5453123) % 1


#---------------------------------------------------------------
# value noise, and its analytical derivatives
#---------------------------------------------------------------

cdef vec4 noised(vec3 x) nogil:
    cdef:
        vec3 p = vec3Floor(x)
        vec3 w = vec3Fract(x)

        vec3 u = vec3New(
            w.x * w.x * (3.0-2.0*w.x),
            w.y * w.y * (3.0-2.0*w.y),
            w.z * w.z * (3.0-2.0*w.z),
        )

        vec3 du = vec3New(
            6.0*w.x*(1.0-w.x),
            6.0*w.y*(1.0-w.y),
            6.0*w.z*(1.0-w.z)
        )

        float n = p.x + p.y*157.0 + 113.0*p.z;

        float a = hash(n+  0.0);
        float b = hash(n+  1.0);
        float c = hash(n+157.0);
        float d = hash(n+158.0);
        float e = hash(n+113.0);
        float f = hash(n+114.0);
        float g = hash(n+270.0);
        float h = hash(n+271.0);

        float k0 =   a;
        float k1 =   b - a;
        float k2 =   c - a;
        float k3 =   e - a;
        float k4 =   a - b - c + d;
        float k5 =   a - c - e + g;
        float k6 =   a - b - e + f;
        float k7 = - a + b + c - d + e - f - g + h;

        vec3 temp = vec3CompMult(
            du,
            vec3Add(
                vec3Add(
                    vec3New(k1,k2,k3),
                    vec3CompMult(vec3New(u.y, u.z, u.x), vec3New(k4,k5,k6))
                ),
                vec3Add(
                    vec3CompMult(vec3New(u.z, u.x, u.y), vec3New(k6,k4,k5)),
                    vec3Multiply(
                        vec3CompMult(
                            vec3New(u.y, u.z, u.x),
                            vec3New(u.z, u.x, u.y)
                        ),
                        k7
                    )
                )
            )
        )

    return vec4New(
        k0 + k1*u.x + k2*u.y + k3*u.z + k4*u.x*u.y + k5*u.y*u.z + \
            k6*u.z*u.x + k7*u.x*u.y*u.z,
        temp.x,
        temp.y,
        temp.z
    )

#---------------------------------------------------------------

cdef vec4 fbmd(vec3 x) nogil:
    cdef:
        float scale  = 1.5;

        float a = 0.0;
        float b = 0.5;
        float f = 1.0;
        vec3  d = vec3Zero();
        vec4  n

    for i in range(15):
        n = noised(vec3Multiply(x, f*scale))

        # accumulate values, derivatives
        a += b*n.x;
        d = vec3Add(d, vec3Multiply(vec3New(n.x, n.y, n.z), b*f*scale))

        b *= 0.5;             # amplitude decrease
        f *= 1.8;             # frequency increase

    return vec4New(a, d.x, d.y, d.z)
