type level = [ `Disable | `Embed | `Enable ]
type mangle = [ `MangleOld | `MangleNew | `MangleNone ]
type source = File of string list | StdIn
type target = FileOut of string | StdOut | Silent

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

and _ misc_flag =
  | Concat_output : bool misc_flag
  | Check_ocaml : bool misc_flag
  | Dash_to_underscore : bool misc_flag

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
