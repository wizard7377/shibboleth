open Test_common

module Test7 = struct
  module Info = struct
    let test_name = "Mutual Recursion"
    let test_desc = "Whether mutally recursive functions are handled correctly (eg, `let rec f = ... and g = ...`)"

    let test_source =
      [
        Fpath.v "test/file_tests/test7/input/input.sml";
      ]

    let test_expect = Fpath.v "test/file_tests/test7/expect/output.ml"
    let test_args = []
    let actual_dir = Some (Fpath.v "test/file_tests/test7/actual")
    let test_context = None
    let expect_context = None
    let check_comments = false
  end

  include Make (Info)
end 

let cases = [ Test7.case ]

