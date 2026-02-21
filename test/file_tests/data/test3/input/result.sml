(* Result type with lowercase constructors *)
(* Inspired by Twelf error-handling patterns *)

structure Result : RESULT =
struct
  datatype 'a result =
      ok of 'a
    | err of string

  fun isOk (ok _)  = true
    | isOk (err _) = false

  fun isErr (ok _)  = false
    | isErr (err _) = true

  fun getOk (ok x)  = x
    | getOk (err s) = raise Fail s
end;
