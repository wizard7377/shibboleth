type level = [ `Disable | `Embed | `Enable ]
type mangle = [ `MangleOld | `MangleNew | `MangleNone ]
type source = File of string list | StdIn | BufferIn of Buffer.t
type target = FileOut of string | StdOut | Silent | BufferOut of Buffer.t

type _ flag =
  | Misc_flag : 'a misc_flag -> 'a flag
  | Mangle_flag : 'a mangle_flag -> 'a flag
  | Convert_flag : 'a convert_flag -> 'a flag
  | Shell_flag : 'a shell_flag -> 'a flag
  | File_flag : 'a file_flag -> 'a flag
  | Dune_flag : 'a dune_flag -> 'a flag

and _ file_flag =
  | Input_file : source file_flag
  | Output_file : target file_flag
  | Context_output : string option file_flag
  | Context_input : string option file_flag

and _ shell_flag =
  | Force : bool shell_flag
  | Verbosity : int shell_flag
  | Debug : string list shell_flag
  | Quiet : bool shell_flag

and _ convert_flag =
  | Convert_names : level convert_flag
  | Convert_keywords : level convert_flag
  | Rename_types : level convert_flag
  | Curry_expressions : level convert_flag
  | Curry_types : level convert_flag
  | Toplevel_names : level convert_flag
  | Pattern_guess : level convert_flag

  (* 
  Whether or not to, whenever a module `M` qualifies a value, `M.x` to add an `open! M` within the module.
  This is effective because a module with the name `M` will already be in scope. However, because with SML, its common for a module to contain only just another module (ie, Bool.Bool), it is very likely that the name is duplicated.
  If not, there is no harm in adding an open statement, and it can be helpful for readability to avoid the extra qualification.
  *)
  | Echo_module_open : bool convert_flag

  (*
  Whether or not to convert some basis structures to simpler OCaml equivalents. 
  This should include `f o g` becoming `fun x -> f (g x)` and `x before y` becoming `let _ = x in y`
  *)
  | Basis_simple : bool convert_flag

and _ misc_flag =
  | Concat_output : bool misc_flag
  | Check_ocaml : bool misc_flag
  | Dash_to_underscore : bool misc_flag
  | No_embed_lowercase : bool misc_flag

and _ mangle_flag =
  | Type_mangle : mangle mangle_flag
  | Constructor_mangle : mangle mangle_flag

and _ dune_flag =
  | Dune_enable : bool dune_flag
  | Dune_import : string list dune_flag
  | Dune_package : string option dune_flag
  | Dune_wrapped : bool dune_flag
  | Dune_open : string list dune_flag

(* Strictly, this isn't specific to dune, but it will likely only see use with libraries *)
