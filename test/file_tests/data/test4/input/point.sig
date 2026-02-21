(* Geometric point with record types and selectors *)
(* Demonstrates SML records -> OCaml objects conversion *)

signature POINT =
sig
  type point = { x : real, y : real }

  val origin   : point
  val distance : point * point -> real
  val scale    : point * real -> point
  val getX     : point -> real
  val getY     : point -> real
end;
