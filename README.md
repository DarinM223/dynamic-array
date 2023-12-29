dynamic-array
=============

MLton currently uses an older version of smlnj-lib which has a buggy `DynamicArray` implementation,
but porting the newer smlnj-lib into MLton is difficult. As a stopgap measure, this package can be
imported to get the newer behavior of `DynamicArray` on non-SML/NJ compilers like MLton, Poly/ML, and MLKit.