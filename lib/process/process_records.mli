(** Record type expansion pass.

    Expands [[%record_type ...]] extension nodes in the OCaml Parsetree into
    fresh named record type declarations. *)

val expand_record_types :
  Parsetree.toplevel_phrase list -> Parsetree.toplevel_phrase list
(** [expand_record_types phrases] walks the Parsetree looking for
    [[%record_type ...]] extension nodes in type positions. For each one:
    - Generates a fresh [type __N = \{ fields... \}] declaration
    - Replaces the extension node with a reference to [__N]
    - Inserts generated types before the structure item that uses them

    @param phrases The toplevel phrases to process
    @return Transformed phrases with record types expanded *)
