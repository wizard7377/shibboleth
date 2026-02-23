open Test_common

module Test1 = struct
  module Info = struct
    let test_name = "test1"
    let test_desc = "Test description for test1"

    let test_source =
      [
        Fpath.v "test/file_tests/test1/input/trail.sig";
        Fpath.v "test/file_tests/test1/input/trail.sml";
      ]

    let test_expect = Fpath.v "test/file_tests/test1/expect/trail.ml"
    let test_args = []
    let actual_dir = Some (Fpath.v "test/file_tests/test1/actual")
    let test_context = None
    let expect_context = None
    let check_comments = false
  end

  include Make (Info)
end

module Test2 = struct
  module Info = struct
    let test_name = "test2"
    let test_desc = "Test description for test2"

    let test_source =
      [
        Fpath.v "test/file_tests/test2/input/intsyn.sig";
        Fpath.v "test/file_tests/test2/input/intsyn.fun";
      ]

    let test_expect = Fpath.v "test/file_tests/test2/expect/intsyn.ml"
    let test_args = []
    let actual_dir = Some (Fpath.v "test/file_tests/test2/actual")
    let test_context = None
    let expect_context = None
    let check_comments = false
  end

  include Make (Info)
end

module Test3 = struct
  module Info = struct
    let test_name = "test3"

    let test_desc =
      "Datatype with lowercase constructors: ok/err -> Ok_/Err_ capitalization"

    let test_source =
      [
        Fpath.v "test/file_tests/test3/input/result.sig";
        Fpath.v "test/file_tests/test3/input/result.sml";
      ]

    let test_expect = Fpath.v "test/file_tests/test3/expect/result.ml"
    let test_args = []
    let actual_dir = Some (Fpath.v "test/file_tests/test3/actual")
    let test_context = None
    let expect_context = None
    let check_comments = false
  end

  include Make (Info)
end

module Test4 = struct
  module Info = struct
    let test_name = "test4"

    let test_desc =
      "Record types and selectors: {x:real,y:real} -> OCaml record, #x -> fun \
       r -> r#x"

    let test_source =
      [
        Fpath.v "test/file_tests/test4/input/point.sig";
        Fpath.v "test/file_tests/test4/input/point.sml";
      ]

    let test_expect = Fpath.v "test/file_tests/test4/expect/point.ml"
    let test_args = []
    let actual_dir = Some (Fpath.v "test/file_tests/test4/actual")
    let test_context = None
    let expect_context = None
    let check_comments = false
  end

  include Make (Info)
end

module Test5 = struct
  module Info = struct
    let test_name = "test5"

    let test_desc =
      "Exceptions, orelse->||, and multi-clause fun with prime renaming"

    let test_source =
      [
        Fpath.v "test/file_tests/test5/input/lookup.sig";
        Fpath.v "test/file_tests/test5/input/lookup.sml";
      ]

    let test_expect = Fpath.v "test/file_tests/test5/expect/lookup.ml"
    let test_args = []
    let actual_dir = Some (Fpath.v "test/file_tests/test5/actual")
    let test_context = None
    let expect_context = None
    let check_comments = false
  end

  include Make (Info)
end

let cases = [ Test1.case; Test2.case; Test3.case; Test4.case; Test5.case ]
