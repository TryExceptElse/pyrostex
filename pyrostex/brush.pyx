cdef class Brush:
    """
    A Brush contains data that can be scaled, rotated, and applied
    to a spheroid or tile.
    Brushes contain all information needed to modify a portion of a
    Spheroid or TileMap.
    """

    def __init__(double w, double h):
        pass

    cpdef void apply(subject, position, scale, rotation) except *:
        pass