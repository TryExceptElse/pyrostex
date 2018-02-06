/**
 * Header file that provides an isnan function available from c or c++
 */

#ifdef __cplusplus
#include <cmath>
#define isnan std::isnan
#else
#include <math.h>
#endif