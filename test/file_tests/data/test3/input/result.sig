(* Result type with lowercase constructors *)
(* Inspired by Twelf error-handling patterns *)

signature RESULT =
sig
  datatype 'a result =
      ok of 'a
    | err of string

  val isOk  : 'a result -> bool
  val isErr : 'a result -> bool
  val getOk : 'a result -> 'a
end;
