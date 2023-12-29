structure Array = struct
  open Array
  fun fromVector v = tabulate (Vector.length v, fn i => Vector.sub (v, i))
end