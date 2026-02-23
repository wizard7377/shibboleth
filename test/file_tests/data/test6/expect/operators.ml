module type OPERATORS = sig
                        val ( + ) : int -> int -> int
                        val ( * ) : int -> int -> int
                        val ( ++ ) : int -> int -> int
                        val ( ! ) : int ref -> int
                        end;;

open! List ;;
module Operators : OPERATORS =
  struct
    let ( + ) x y = x + y;;
    let ( * ) x y = x * y;;
    let ( ++ ) x y = (x + y) + 1;;
    let ( ! ) = function 
                         | r -> ! r;;
    let sum = List.foldl (fun (x__op, y__op) -> x__op + y__op) 0;;
    let x = 1 + 2;;
    end;;