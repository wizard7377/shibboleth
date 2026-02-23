open! Word8VectorSlice;;
open! Array;;
(* 
 * (c) Andreas Rossberg 2002-2025
 *
 * Standard ML Basis Library
  *);;
module Word8ArraySlice : MONO_ARRAY_SLICE =
  struct
    open ArraySlice;;
    type nonrec elem = Word8.word;;
    type nonrec vector = Word8Vector.vector;;
    type nonrec array = elem array;;
    type nonrec slice = elem slice;;
    type nonrec vector_slice = Word8VectorSlice.slice;;
    let rec copyVec { src; dst; di; dst; di; di} = begin
      if
      (di < 0) || ((Array.length dst) < (di + (Word8VectorSlice.length src)))
      then raise Subscript else copyVec' (src, dst, di, 0) end
    and copyVec' (src, dst, di, i) = begin
      if i = (Word8VectorSlice.length src) then () else
      begin
        Array.update (dst, di + i, Word8VectorSlice.sub (src, i));
        copyVec' (src, dst, di, i + 1)
        end
      end;;
    end;;