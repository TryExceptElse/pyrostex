

cdef inline vec2 cp2v_2d(t):
    """
    Copy to vector 2 doubles
    """
    cdef vec2 v
    v.x = t[0]
    v.y = t[1]
    return v


cdef inline vec3 cp2v_3d(t):
    """
    Copy to vector 3 doubles
    """
    cdef vec3 v
    v.x = t[0]
    v.y = t[1]
    v.z = t[2]
    return v


cdef inline latlon cp2ll(t):
    """
    Copy to vector 2 doubles
    """
    cdef latlon ll
    ll.lat = t[0]
    ll.lon = t[1]
    return ll
