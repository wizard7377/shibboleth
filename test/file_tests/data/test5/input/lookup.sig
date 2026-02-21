(* Symbol table lookup with exceptions *)
(* Demonstrates SML exception handling and andalso/orelse patterns *)

signature LOOKUP =
sig
  type key = int
  type 'a table

  exception NotFound of key
  exception Duplicate of key

  val empty  : 'a table
  val insert : 'a table * key * 'a -> 'a table
  val lookup : 'a table * key -> 'a
  val member : 'a table * key -> bool
end;
