(* Geometric point with record types and selectors *)
(* Demonstrates SML records -> OCaml objects conversion *)

structure Point : POINT =
struct
  type point = { x : real, y : real }

  val origin = { x = 0.0, y = 0.0 }

  fun distance (p1, p2) =
    let
      val dx = #x p2 - #x p1
      val dy = #y p2 - #y p1
    in
      Math.sqrt (dx * dx + dy * dy)
    end

  fun scale (p, s) = { x = #x p * s, y = #y p * s }

  val getX = #x
  val getY = #y
end;
