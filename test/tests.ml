open File_tests
open Unit_tests

let tests : unit Alcotest.test list = [ File_tests.tests; Unit_tests.tests ]
let () = Alcotest.run "Shibboleth" tests
