

cdef inline void cp2a_2d(tuple t, double[2] a):
    """
    Copy to array 2 doubles
    """
    a[0] = t[0]
    a[1] = t[1]


cdef inline void cp2a_3d(tuple t, double[3] a):
    """
    Copy to array 3 doubles
    """
    a[0] = t[0]
    a[1] = t[1]
    a[2] = t[2]
