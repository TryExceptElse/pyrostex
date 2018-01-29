"""
Module for calculating region from height and temperature
"""

cdef:
    int NULL_REGION = 0  # Not to be used.
    int ROCK        = 1  # default land area
    int MARE        = 2  # low-lying areas, may or may not be liquid filled
    int ICE         = 3  # ex: polar caps


cdef class Region:
    """
    Class representing a type of region, which contains properties
    and methods unique to the type of terrain
    """

    cdef get_hardness(double depth, vector pos)


