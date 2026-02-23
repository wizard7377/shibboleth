(*  Result type with lowercase constructors  *)
(*  Inspired by Twelf error-handling patterns  *)
module type RESULT = sig
  type 'a result = | Ok_ of 'a | Err_ of string

  val isOk : 'a result -> bool
  val isErr : 'a result -> bool
  val getOk : 'a result -> 'a
end

(*  Result type with lowercase constructors  *)
(*  Inspired by Twelf error-handling patterns  *)
module Result : RESULT = struct
  type 'a result = | Ok_ of 'a | Err_ of string

  let rec isOk = function | Ok_ _ -> true | Err_ _ -> false
  let rec isErr = function | Ok_ _ -> false | Err_ _ -> true
  let rec getOk = function | Ok_ x -> x | Err_ s -> raise ((Fail s))
end
