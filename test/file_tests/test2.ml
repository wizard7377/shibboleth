open Test_common 

module Info = 
  struct 
    let test_name = "test2"
    let test_desc = "Test description for test2"
    let test_source =
      [
        Fpath.v "test/file_tests/test2/input/intsyn.sig";
        Fpath.v "test/file_tests/test2/input/insyn.fun";
      ]
    let test_expect = Fpath.v "test/file_tests/test2/expect/intsyn.ml"
    let test_args = []
    let actual_dir = Some (Fpath.v "test/file_tests/test2/actual")
    let test_context = None
    let expect_context = None
  end
include Make(Info)