(*  Geometric point with record types and selectors  *);;
(*  Demonstrates SML records -> OCaml objects conversion  *);;
module type POINT = sig
                    type nonrec point = { x: real ; y: real }
                    val origin : point
                    val distance : (point * point -> real)
                    val scale : (point * real -> point)
                    val getX : (point -> real)
                    val getY : (point -> real)
                    end;;(*  Geometric point with record types and selectors  *);;
(*  Demonstrates SML records -> OCaml objects conversion  *);;
module Point : POINT =
  struct
    type nonrec point = { x: real ; y: real };;
    let origin = { x = 0.0; y = 0.0} ;;
    let rec distance (p1, p2) =
      (let dx = (((((fun r -> r.x)) p2)) - ((((fun r -> r.x)) p1)))
       in (let dy = (((((fun r -> r.y)) p2)) - ((((fun r -> r.y)) p1)))
           in (Math.sqrt ((((dx * dx)) + ((dy * dy)))))));;
    let rec scale (p, s) =
      { x = (((((fun r -> r.x)) p)) * s); y = (((((fun r -> r.y)) p)) * s)} ;;
    let getX r = r.x;;
    let getY r = r.y;;
    end;;
