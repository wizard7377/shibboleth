(** Parse SMLNJ CM files and convert them to dune stanzas. *)

(** The type of CM group (Library, Group, etc.) *)
type group_type = Library | Group [@@deriving show, eq]

type t = {
  group_type : group_type;
  sources : string list;
  dependencies : string list;
}
[@@deriving show, eq]
(** A parsed CM file. *)

val parse : string -> t
(** [parse content] parses the text content of a CM file into {!t}. Lines before
    [is] (after the group type keyword) are discarded. Source files ([.sml],
    [.sig], [.fun]) become {!t.sources}. Dependency files ([.cm]) become
    {!t.dependencies}. *)

val to_dune : cfg:Common.t -> dir_name:string -> t -> string
(** [to_dune ~dir_name t] converts a parsed CM file to a dune stanza string.
    [dir_name] is used as the library name. *)
