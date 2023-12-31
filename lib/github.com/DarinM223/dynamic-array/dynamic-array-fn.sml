(* dynamic-array-fn.sml
 *
 * COPYRIGHT (c) 2023 The Fellowship of SML/NJ (http://www.smlnj.org)
 * All rights reserved.
 *
 * Monomorphic arrays of unbounded length
 *
 * TODO: add the missing operations that the DynamicArray structure
 * provides.  Adding these will require including the MONO_ARRAY_SLICE
 * structure as a functor parameter.
 *)

functor DynamicArrayFn (A : MONO_ARRAY) : MONO_DYNAMIC_ARRAY =
  struct

    type elem = A.elem

    (* BLOCK(arr, dflt, bnd):
     *	arr	- current data store; is at least !bnd+1 elements with arr[0..bnd]
     *              being the range of "defined" entries.
     *	dflt	- default value
     *	bnd	- values at indices above !bnd are default for reading
     *)
    datatype array = BLOCK of A.array ref * elem * int ref

    exception Subscript = General.Subscript
    exception Size = General.Size

    fun array (sz, dflt) = BLOCK(ref (A.array (sz, dflt)), dflt, ref (~1))

    (* fromList (l, v) creates an array using the list of values l
     * plus the default value v.
     *)
    fun fromList (initList, dflt) = let
	  val arr = A.fromList initList
	  in
	    BLOCK(ref arr, dflt, ref(A.length arr - 1))
	  end

    fun toList (BLOCK(ref arr, _, bnd)) = let
	  val len = !bnd + 1
	  in
	    List.tabulate (len, fn i => A.sub(arr, i))
	  end

    (* tabulate (sz, fill, dflt) acts like Array.tabulate, plus
     * stores default value dflt.  Raises Size if sz < 0.
     *)
    fun tabulate (sz, fillFn, dflt) =
	  BLOCK(ref(A.tabulate(sz, fillFn)), dflt, ref(sz-1))

    (* create a new dynamic array with the elements from arr[lo..hi] *)
    fun subArray' (BLOCK(arr, dflt, bnd), lo, hi) = let
          val arrval = !arr
          val bnd = !bnd
          (* copy the [lo..top] elements from the source array, where top is
           * the minimum of `bnd` and `hi`.
           *)
          fun make top = BLOCK(
                ref(A.tabulate(top-lo+1, fn i => A.sub(arrval, i+lo))),
                dflt,
                ref(top-lo))
          in
            if hi <= bnd
              (* the new array is a slice of the defined range *)
              then make hi
            else if (lo <= bnd)
              (* the new array includes both the "defined" and default ranges *)
              then make bnd
              (* the new array only includes the default range *)
              else array(0, dflt)
          end

    (* check that the specified bounds are valid and then call subArray' to do
     * the actual work.
     *)
    fun subArray (da, lo, hi) =
          if (lo < 0) orelse (hi < lo-1)
            then raise Size
            else subArray' (da, lo, hi)

    fun default (BLOCK(_, dflt, _)) = dflt

    fun sub (BLOCK(arr, dflt, _), idx) = (A.sub(!arr, idx))
          handle Subscript => if idx < 0 then raise Subscript else dflt

    fun bound (BLOCK(_, _, bnd)) = (!bnd)

    fun expand (arr, oldlen, newlen, dflt) = let
          fun fillfn i = if i < oldlen then A.sub(arr,i) else dflt
          in
            A.tabulate(newlen, fillfn)
          end

    fun update (BLOCK(arr, dflt, bnd), idx, v) = let
          val len = A.length (!arr)
          in
            if idx >= len
              then arr := expand(!arr, len, Int.max(len+len, idx+1), dflt)
              else ();
            A.update(!arr, idx, v);
            if idx > !bnd then bnd := idx else ()
          end

    fun truncate (a as BLOCK(arr, dflt, bndref), sz) = let
          val bnd = !bndref
          val newbnd = sz - 1
          val arr_val = !arr
          val array_sz = A.length arr_val
          fun fillDflt (i, stop) =
                if i = stop then ()
                else (A.update(arr_val, i, dflt); fillDflt(i-1, stop))
          in
            if newbnd < 0 then (bndref := ~1; arr := A.array(0, dflt))
            else if newbnd >= bnd then ()
            else if 3 * sz < array_sz then let
              val BLOCK(arr', _, bnd') = subArray'(a, 0, newbnd)
              in
                (bndref := !bnd'; arr := !arr')
              end
            else (bndref := newbnd; fillDflt(bnd, newbnd))
          end

  end (* DynamicArrayFn *)
