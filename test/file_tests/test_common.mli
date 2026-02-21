module type S = sig
  val test_name : string
  val test_desc : string
  val test_source : Fpath.t list
  val test_expect : Fpath.t
  val test_args : Common.arg list
  val test_context : Fpath.t option
  val expect_context : Fpath.t option
  val actual_dir : Fpath.t option
  val check_comments : bool
end

module Make (M : S) : sig
  include S

  val run : unit -> unit
  val case : unit Alcotest.test_case
end
