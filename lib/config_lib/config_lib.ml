include Config_lib_

let is_flag_enabled : level -> bool = function
  | `Enable | `Embed -> true
  | `Disable -> false

let engaged : level -> bool = is_flag_enabled

type t = {
  convert_names : level; [@default `Enable]
  convert_keywords : level; [@default `Enable]
  rename_types : level; [@default `Enable]
  curry_expressions : level; [@default `Disable]
  curry_types : level; [@default `Disable]
  toplevel_names : level; [@default `Enable]
  verbosity : int; [@default 0]
  concat_output : bool; [@default false]
  force : bool; [@default false]
  quiet : bool; [@default true]
  debug : string list; [@default []]
  check_ocaml : bool; [@default false]
  dash_to_underscore : bool; [@default true]
  input_file : source; [@default StdIn]
  output_file : target; [@default Silent]
  context_output : string option; [@default None]
  context_input : string option; [@default None]
  type_mangle : mangle; [@default `MangleNew]
  constructor_mangle : mangle; [@default `MangleNew]
  dune_enable : bool; [@default true]
  dune_import : string list; [@default []]
  dune_package : string option; [@default None]
  dune_wrapped : bool; [@default false]
  dune_open : string list; [@default []]
}
[@@deriving make]

type arg = t -> t

let get : type a. a flag -> t -> a =
 fun flag cfg ->
  match flag with
  | Convert_flag Convert_names -> cfg.convert_names
  | Convert_flag Convert_keywords -> cfg.convert_keywords
  | Convert_flag Rename_types -> cfg.rename_types
  | Convert_flag Curry_expressions -> cfg.curry_expressions
  | Convert_flag Curry_types -> cfg.curry_types
  | Convert_flag Toplevel_names -> cfg.toplevel_names
  | Shell_flag Verbosity -> cfg.verbosity
  | Shell_flag Force -> cfg.force
  | Shell_flag Quiet -> cfg.quiet
  | Shell_flag Debug -> cfg.debug
  | Misc_flag Concat_output -> cfg.concat_output
  | Misc_flag Check_ocaml -> cfg.check_ocaml
  | Misc_flag Dash_to_underscore -> cfg.dash_to_underscore
  | File_flag Input_file -> cfg.input_file
  | File_flag Output_file -> cfg.output_file
  | File_flag Context_output -> cfg.context_output
  | File_flag Context_input -> cfg.context_input
  | Mangle_flag Type_mangle -> cfg.type_mangle
  | Mangle_flag Constructor_mangle -> cfg.constructor_mangle
  | Dune_flag Dune_enable -> cfg.dune_enable
  | Dune_flag Dune_import -> cfg.dune_import
  | Dune_flag Dune_package -> cfg.dune_package
  | Dune_flag Dune_wrapped -> cfg.dune_wrapped 
  | Dune_flag Dune_open -> cfg.dune_open

let set : type a. a flag -> a -> arg =
 fun flag value cfg ->
  match flag with
  | Convert_flag Convert_names -> { cfg with convert_names = value }
  | Convert_flag Convert_keywords -> { cfg with convert_keywords = value }
  | Convert_flag Rename_types -> { cfg with rename_types = value }
  | Convert_flag Curry_expressions -> { cfg with curry_expressions = value }
  | Convert_flag Curry_types -> { cfg with curry_types = value }
  | Convert_flag Toplevel_names -> { cfg with toplevel_names = value }
  | Shell_flag Verbosity -> { cfg with verbosity = value }
  | Shell_flag Force -> { cfg with force = value }
  | Shell_flag Quiet -> { cfg with quiet = value }
  | Shell_flag Debug -> { cfg with debug = value }
  | Misc_flag Concat_output -> { cfg with concat_output = value }
  | Misc_flag Check_ocaml -> { cfg with check_ocaml = value }
  | Misc_flag Dash_to_underscore -> { cfg with dash_to_underscore = value }
  | File_flag Input_file -> { cfg with input_file = value }
  | File_flag Output_file -> { cfg with output_file = value }
  | File_flag Context_output -> { cfg with context_output = value }
  | File_flag Context_input -> { cfg with context_input = value }
  | Mangle_flag Type_mangle -> { cfg with type_mangle = value }
  | Mangle_flag Constructor_mangle -> { cfg with constructor_mangle = value }
  | Dune_flag Dune_enable -> { cfg with dune_enable = value }
  | Dune_flag Dune_import -> { cfg with dune_import = value }
  | Dune_flag Dune_package -> { cfg with dune_package = value }
  | Dune_flag Dune_wrapped -> { cfg with dune_wrapped = value } 
  | Dune_flag Dune_open -> { cfg with dune_open = value }
let create (args : arg list) : t =
  List.fold_left (fun cfg f -> f cfg) (make ()) args

module type CONFIG = sig
  val config : t
end
