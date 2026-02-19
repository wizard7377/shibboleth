(** A name within a package *)
type pkg_path =

  (** A simple name (eg, shibboleth) *)
  Name of string | 

  (** An absolute path (eg, home/.../shibboleth) *)
  Absolute of Fpath.t | 

  (** A path relative to the current working directory *)
  Relative of Fpath.t | 

  (** A logical path (eg, a path in a virtual filesystem) (cm is [$] )*)
  Logical of Fpath.t
[@@deriving show, eq]

(** Group type *)
type group_type = Library | Group | Executable | Test [@@deriving show, eq]
 
(** A package or package group *)
type t = {

  (** The type of the package *)
  group_type : group_type;

  (** Optional specification (ie, everything before [is] in CM *)
  spec : Ast_core.specification option;

  (** The path of the project *)
  name : pkg_path;

  (** Clauses *)
  clauses : clause list;
}
and clause = 

  (** Sub groups of the main package, that are internal to it *)
  Subgroup of t | 

  (** A source file *)
  Source of pkg_path | 

  (** A external dependency (or depency on another part of the package) *)
  Dependency of pkg_path | 

  (** In ML Basis, an alias *)
  Alias of pkg_path * pkg_path | 

  (** Re-Export the given package *)
  Export of pkg_path


   
