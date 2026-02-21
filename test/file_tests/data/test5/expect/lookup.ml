(*  Symbol table lookup with exceptions  *);;
(*  Demonstrates SML exception handling and andalso/orelse patterns  *);;
module type LOOKUP = sig
                     type nonrec key = int
                     type nonrec 'a table
                     exception NotFound of key
                     exception Duplicate of key
                     val empty : 'a table
                     val insert : ('a table * key * 'a -> 'a table)
                     val lookup : ('a table * key -> 'a)
                     val member : ('a table * key -> bool)
                     end;;(*  Symbol table lookup with exceptions  *);;
(*  Demonstrates SML exception handling and andalso/orelse patterns  *);;
module Lookup : LOOKUP =
  struct
    type nonrec key = int;;
    type nonrec 'a table = key * 'a list;;
    exception NotFound of key ;;
    exception Duplicate of key ;;
    let empty = [];;
    let rec insert (t, k, v) = begin
      if (member (t, k)) then (raise ((Duplicate k))) else ((k, v) :: t) end;;
    let rec member =
      (function
                | ([], _) -> false_
                | (((k_prime, _) :: rest), k)
                    -> (((k = k_prime)) || ((member (rest, k)))));;
    let rec lookup =
      (function
                | ([], k) -> (raise ((NotFound k)))
                | (((k_prime, v) :: rest), k) -> begin
                    if (k = k_prime) then v else (lookup (rest, k)) end);;
    end;;
