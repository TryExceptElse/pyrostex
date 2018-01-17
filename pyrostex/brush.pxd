

cdef class Brush:
    """
    A Brush contains data that can be scaled, rotated, and applied
    to a map.
    Brushes are intended to be initialized from a file containing
    brush data.
    """

    cpdef void apply(subject, position, scale, rotation) except *