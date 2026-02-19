open Test1

let file_test : unit Alcotest.test = "File tests", [
  Test1.case
]
let () =
	Alcotest.run "File tests" [ file_test ] 
  