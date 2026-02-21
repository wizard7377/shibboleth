(* Symbol table lookup with exceptions *)
(* Demonstrates SML exception handling and andalso/orelse patterns *)

structure Lookup : LOOKUP =
struct
  type key = int
  type 'a table = (key * 'a) list

  exception NotFound of key
  exception Duplicate of key

  val empty = []

  fun insert (t, k, v) =
    if member (t, k)
    then raise Duplicate k
    else (k, v) :: t

  and member ([], _) = false
    | member ((k', _) :: rest, k) =
        k = k' orelse member (rest, k)

  fun lookup ([], k) = raise NotFound k
    | lookup ((k', v) :: rest, k) =
        if k = k'
        then v
        else lookup (rest, k)
end;
