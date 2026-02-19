open Test_common 

module Info =
  struct 
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
  end
include Make(Info)