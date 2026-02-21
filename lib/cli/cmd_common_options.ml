open Cmdliner
open Cmdliner.Term.Syntax
open Cmdliner.Term

let level_conv : Common.level Cmdliner.Arg.conv =
  let parse = function
    | "enable" -> Ok `Enable
    | "embed" -> Ok `Embed
    | "disable" -> Ok `Disable
    | s ->
        Error
          (`Msg
             (Printf.sprintf
                "Invalid level: %s. Expected one of: enable, embed, disable." s))
  in
  let print fmt v =
    let s =
      match v with
      | `Enable -> "enable"
      | `Embed -> "embed"
      | `Disable -> "disable"
    in
    Format.fprintf fmt "%s" s
  in
  Arg.conv (parse, print)

let level_arg : Common.level -> Cmdliner.Arg.info -> Common.level Cmdliner.Arg.t
    =
 fun d info -> Arg.(opt level_conv d) info

let verb : int Term.t =
  let doc =
    "Control output verbosity level (0-3). 0=errors only (default), \
     1=warnings, 2=progress, 3=debug."
  in
  Arg.(value & opt int 0 & info [ "v"; "verbose" ] ~doc)

let conversion_flags : (bool * Common.t) Term.t =
  let convert_names_doc =
    "Flag identifiers invalid in OCaml with $(b,[@sml.bad_name]) attributes. "
  in
  let convert_names_flag : Common.level Term.t =
    Arg.value
    @@ level_arg `Disable
         (Cmdliner.Arg.info [ "convert-names" ] ~doc:convert_names_doc)
  in
  let convert_keywords_doc =
    "Rename SML identifiers that clash with OCaml keywords by appending an \
     underscore (e.g. method -> method_)."
  in
  let convert_keywords_flag : Common.level Term.t =
    Arg.value
    @@ level_arg `Embed
         (Cmdliner.Arg.info [ "convert-keywords" ] ~doc:convert_keywords_doc)
  in
  let rename_types_doc = {|Rename types to be valid OCaml|} in
  let rename_types_flag : Common.level Term.t =
    Arg.value
    @@ level_arg `Enable
         (Cmdliner.Arg.info [ "rename-types" ] ~doc:rename_types_doc)
  in
  let curry_expressions_doc =
    {|Convert tuple-argument functions to curried form
     (e.g. fun f(x,y) -> let f x y).|}
  in
  let curry_expressions_flag : Common.level Term.t =
    Arg.value
    @@ level_arg `Disable
         (Cmdliner.Arg.info [ "curry-expressions" ] ~doc:curry_expressions_doc)
  in
  let curry_types_doc =
    {|Convert tuple-argument function types to curried form
     (e.g. int * string -> r becomes int -> string -> r).|}
  in
  let curry_types_flag : Common.level Term.t =
    Arg.value
    @@ level_arg `Disable
         (Cmdliner.Arg.info [ "curry-types" ] ~doc:curry_types_doc)
  in
  let pattern_guess_doc =
    {|Control handling of ambiguous patterns (lowercase identifiers that could be variables or constructors).
     embed (default): Generate extension nodes [%sml.pattern "name"] for runtime resolution.
     enable: Trust constructor registry - treat as constructor if registered, variable otherwise.
     disable: Always treat as variables unless in constructor position.|}
  in
  let pattern_guess_flag : Common.level Term.t =
    Arg.value
    @@ level_arg `Embed
         (Cmdliner.Arg.info [ "pattern-guess" ] ~doc:pattern_guess_doc)
  in
  let convert_force_flag : bool Term.t =
    let doc = "Force overwrite of existing output files and directories." in
    Arg.(value & flag & info [ "force" ] ~doc)
  in

  let+ convert_names = convert_names_flag
  and+ convert_keywords = convert_keywords_flag
  and+ rename_types = rename_types_flag
  and+ force = convert_force_flag
  and+ curry_expressions = curry_expressions_flag
  and+ curry_types = curry_types_flag
  and+ pattern_guess = pattern_guess_flag in
  ( force,
    Common.create
      Common.
        [
          set (Convert_flag Convert_names) convert_names;
          set (Convert_flag Convert_keywords) convert_keywords;
          set (Convert_flag Rename_types) rename_types;
          set (Convert_flag Curry_expressions) curry_expressions;
          set (Convert_flag Curry_types) curry_types;
          set (Convert_flag Pattern_guess) pattern_guess;
        ] )

let dash_to_underscore_doc =
  {|Replace dashes with underscores in generated OCaml filenames
   (e.g. parser-utils.sml -> parser_utils.ml).|}

let dash_to_underscore_flag : bool Term.t =
  Arg.(value & flag & info [ "dash-to-underscore" ] ~doc:dash_to_underscore_doc)

let no_embed_lowercase_doc =
  {|When pattern_guess is Embed, treat lowercase names normally instead of
   embedding them as extensions. Uppercase names remain embedded.
   Default: enabled (lowercase names are not embedded).|}

let embed_all_patterns_doc =
  {|When pattern_guess is Embed, embed both uppercase and lowercase patterns
   as extensions. This overrides the default behavior.|}

(* no_embed_lowercase defaults to true; --embed-all-patterns sets it to false *)
let no_embed_lowercase_flag : bool Term.t =
  let embed_all =
    (false, Arg.info [ "embed-all-patterns" ] ~doc:embed_all_patterns_doc)
  in
  Arg.(value & vflag true [ embed_all ])

let concat_output : bool Term.t =
  let doc =
    {|
    Merge sig and fun files into a single ml file, instead of splitting them 
    |}
  in
  Arg.(value & opt bool false & info [ "concat-output" ] ~doc)

let quiet : bool Term.t =
  let doc = {|Suppress all output except errors.|} in
  Arg.(value & flag & info [ "q"; "quiet" ] ~doc)

let debug : string list Term.t =
  let doc = {|Enable debug output for specific subsystems.|} in
  Arg.(value & opt (list string) [] & info [ "debug" ] ~docv:"CATEGORY" ~doc)

let check_ocaml_doc =
  {|Validate generated OCaml syntax via ocamlc.
   Checks syntax only, not types. Requires ocamlc in PATH.|}

let check_ocaml_flag : bool Term.t =
  Arg.(value & flag & info [ "check-ocaml" ] ~doc:check_ocaml_doc)

let context_output_doc =
  {|Write constructor context to a .sctx file for use in subsequent conversions
   via --context-input.|}

let context_output_flag : string option Term.t =
  Arg.(
    value
    & opt (some string) None
    & info [ "context-output" ] ~doc:context_output_doc ~docv:"PATH")

let context_input_doc =
  {|Load constructor context from a .sctx file for cross-module resolution.|}

let context_input_flag : string option Term.t =
  Arg.(
    value
    & opt (some string) None
    & info [ "context-input" ] ~doc:context_input_doc ~docv:"PATH")

let mangle_conv : Common.mangle Cmdliner.Arg.conv =
  let parse = function
    | "new" -> Ok `MangleOld
    | "old" -> Ok `MangleNew
    | "none" -> Ok `MangleNone
    | s ->
        Error
          (`Msg
             (Printf.sprintf
                "Invalid level: %s. Expected one of: new, old, none." s))
  in
  let print fmt v =
    let s =
      match v with
      | `MangleOld -> "new"
      | `MangleNew -> "old"
      | `MangleNone -> "none"
    in
    Format.fprintf fmt "%s" s
  in
  Arg.conv (parse, print)

let mangle_arg :
    Common.mangle -> Cmdliner.Arg.info -> Common.mangle Cmdliner.Arg.t =
 fun d info -> Arg.(opt mangle_conv d) info

let mangle_types_doc = {|Control how types are mangled|}

let mangle_types_flag : Common.mangle Term.t =
  Arg.value
  @@ mangle_arg `MangleNew
       (Cmdliner.Arg.info [ "mangle-types" ] ~doc:mangle_types_doc)

let mangle_constructors_doc = {|Control how constructors are mangled|}

let mangle_constructors_flag : Common.mangle Term.t =
  Arg.value
  @@ mangle_arg `MangleNew
       (Cmdliner.Arg.info [ "mangle-constructors" ] ~doc:mangle_constructors_doc)

let dune_enable : bool Term.t =
  let doc = {|Enable generation of Dune files for converted modules|} in
  Arg.(value & flag & info [ "dune-enable" ] ~doc)

let dune_import : string list Term.t =
  let doc = {|Specify Dune libraries to import in generated Dune files|} in
  Arg.(value & opt (list string) [] & info [ "dune-import" ] ~docv:"LIBS" ~doc)

let dune_package : string option Term.t =
  let doc = {|Specify Dune package name for generated Dune files|} in
  Arg.(
    value & opt (some string) None & info [ "dune-package" ] ~docv:"PKG" ~doc)

let dune_wrapped : bool Term.t =
  let doc = {|Control whether generated Dune files use (wrapped true)|} in
  Arg.(value & flag & info [ "dune-wrapped" ] ~doc)

let dune_include : string list Term.t =
  let doc = {|Specify modules to open in generated OCaml files|} in
  Arg.(value & opt (list string) [] & info [ "dune-open" ] ~docv:"MODS" ~doc)

let common_options : Common.t Cmdliner.Term.t =
  let+ v = verb
  and+ force, c = conversion_flags
  and+ co = concat_output
  and+ q = quiet
  and+ dbg = debug
  and+ check_ocaml = check_ocaml_flag
  and+ dash_to_underscore = dash_to_underscore_flag
  and+ no_embed_lowercase = no_embed_lowercase_flag
  and+ ctx_out = context_output_flag
  and+ ctx_in = context_input_flag
  and+ mangle_types = mangle_types_flag
  and+ mangle_constructors = mangle_constructors_flag in
  Common.create
    Common.
      [
        set (Shell_flag Verbosity) v;
        set (Convert_flag Convert_names)
          (Common.get (Convert_flag Convert_names) c);
        set (Convert_flag Convert_keywords)
          (Common.get (Convert_flag Convert_keywords) c);
        set (Convert_flag Rename_types)
          (Common.get (Convert_flag Rename_types) c);
        set (Convert_flag Curry_expressions)
          (Common.get (Convert_flag Curry_expressions) c);
        set (Convert_flag Curry_types) (Common.get (Convert_flag Curry_types) c);
        set (Convert_flag Pattern_guess)
          (Common.get (Convert_flag Pattern_guess) c);
        set (Misc_flag Concat_output) co;
        set (Shell_flag Force) force;
        set (Shell_flag Quiet) q;
        set (Shell_flag Debug) dbg;
        set (Misc_flag Check_ocaml) check_ocaml;
        set (Misc_flag Dash_to_underscore) dash_to_underscore;
        set (Misc_flag No_embed_lowercase) no_embed_lowercase;
        set (File_flag Context_output) ctx_out;
        set (File_flag Context_input) ctx_in;
        set (Mangle_flag Type_mangle) mangle_types;
        set (Mangle_flag Constructor_mangle) mangle_constructors;
      ]
