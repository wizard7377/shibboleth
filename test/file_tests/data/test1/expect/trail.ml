(*  Trailing Abstract Operations  *);;
(*  Author: Roberto Virga  *);;
module type TRAIL = sig
                    type nonrec 'a trail
                    val trail : (unit -> 'a trail)
                    val suspend : ('a trail * ('a -> 'b) -> 'b trail)
                    val resume : ('b trail * 'a trail * ('b -> 'a) -> unit)
                    val reset : ('a trail -> unit)
                    val mark : ('a trail -> unit)
                    val unwind : ('a trail * ('a -> unit) -> unit)
                    val log : ('a trail * 'a -> unit)
                    end;;
(*  signature TRAIL  *);;(*  Trailing Abstract Operations  *);;
(*  Author: Roberto Virga  *);;
module Trail : TRAIL =
  struct
    module Local_1_ = struct
                        type 'a trail_ =
                          | Cons of 'a * 'a trail_ 
                          | Mark of ('a trail_) 
                          | Nil ;;
                        type nonrec 'a trail = ('a trail_) ref;;
                        let rec trail () = (ref Nil);;
                        let rec reset trail = (trail := Nil);;
                        let rec suspend (trail, copy) =
                          (let rec suspend_prime =
                             (function 
                                       | Nil -> Nil
                                       | (Mark trail)
                                           -> (suspend_prime trail)
                                       | (Cons (action, trail))
                                           -> (Cons
                                               ((copy action),
                                                (suspend_prime trail))))
                           in (let ftrail = (suspend_prime ((! trail)))
                               in (ref ftrail)));;
                        let rec resume (ftrail, trail, reset) =
                          (let rec resume_prime =
                             (function 
                                       | Nil -> Nil
                                       | (Mark ftrail)
                                           -> (resume_prime ftrail)
                                       | (Cons (faction, ftrail))
                                           -> (Cons
                                               ((reset faction),
                                                (resume_prime ftrail))))
                           in (let trail_prime = (resume_prime ((! ftrail)))
                               in (trail := trail_prime)));;
                        let rec mark trail = (trail := ((Mark ((! trail)))));;
                        let rec unwind (trail, undo) =
                          (let rec unwind_prime =
                             (function 
                                       | Nil -> Nil
                                       | (Mark trail) -> trail
                                       | (Cons (action, trail))
                                           -> begin
                                                (undo action);
                                                (unwind_prime trail)
                                                end)
                           in (trail := ((unwind_prime ((! trail))))));;
                        let rec log (trail, action) =
                          (trail := ((Cons (action, (! trail)))));;
                        end;;
    open! Local_1_;;
    (* 	  | suspend' (Mark trail) = (Mark (suspend' trail)) *);;
    (* 	  | resume' (Mark ftrail) = (Mark (resume' ftrail))  *);;
    type nonrec 'a trail = 'a trail;;
    let trail = trail;;
    let suspend = suspend;;
    let resume = resume;;
    let reset = reset;;
    let mark = mark;;
    let unwind = unwind;;
    let log = log;;
    end;;
(*  local ...  *);;
(*  structure Trail  *);;