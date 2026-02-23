structure Operators :> OPERATORS =
struct
  val (op +) = fn (x, y) => x + y
  val (op *) = fn (x, y) => x * y
  val (op ++) = fn (x, y) => x + y + 1
  val (op !) = fn r => !r
  val sum = List.foldl (op +) 0
  val x = 1 + 2
end
