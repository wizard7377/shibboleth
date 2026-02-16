(lang dune 3.20)

(name shibboleth)

(version 0.0.5)

(generate_opam_files true)

(source
 (github wizard7377/sml-ocaml-converter))

(authors "Asher Frost <wizardishlike@gmail.com>")

(maintainers "Asher Frost <wizardishlike@gmail.com>")

(license BSD-2-Clause)

(using menhir 3.0)

(package
 (name shibboleth)
 (synopsis "An SML to OCaml converter")
 (description
  "A tool that converts Standard ML code to OCaml, facilitating interoperability between the two languages.")
 (depends
  (ocaml
   (>= 4.14))
  (menhirLib
   (>= 20250912))
  (fpath
   (>= 0.7.3))
  (bos
   (>= 0.2.1))
  (ppxlib
   (>= 0.33.0))
  (cmdliner
   (>= 1.2.0))
  (menhir
   (>= 20250912))
  (ppx_import
   (>= 1.11.0))
  (ppx_deriving
   (>= 6.0.0))
  (ppx_sexp_conv
   (>= 0.16.0))
  (sexplib
   (>= 0.16.0))
  (sexplib0
   (>= 0.16.0))
  (containers
   (>= 3.0))
  (re
   (>= 1.10.0))
  (ez_file
   (>= 0.3.0))
  (fmt
   (>= 0.9.0))
  (yojson
   (>= 2.0.0))
  (alcotest
   (and
    :with-test
    (>= 1.7.0))))
 (tags
  (ocaml sml)))