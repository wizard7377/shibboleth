open Cmdliner
open Cmdliner.Term.Syntax
include Cmd_common_options
include Process

module type Command_S = sig
  val run_cmd : int Cmd.t
end

module Convert_File : Command_S = struct
  let output : string option Term.t =
    let doc =
      "Output path for converted OCaml file. Writes to stdout if omitted."
    in
    Arg.(
      value
      & opt (some string) None
      & info [ "o"; "output" ] ~doc ~docv:"OUTPUT")

  let input : string list Term.t =
    let doc =
      "SML source file(s) to convert. For multi-file modules, \
       provide in order: %.sig %.fun %.sml."
    in
    Arg.(non_empty (pos_all string [] & info [] ~doc ~docv:"INPUT"))

  let run_cmd : int Cmd.t =
    let doc =
      "Convert one or more Standard ML source files to OCaml. \
       Inputs are concatenated by default (see --concat-output)."
    in
    Cmd.v
      (Cmd.info "file" ~doc ~docs:"SML Converter"
         ~man:
           [
             `S "EXAMPLES";
             `P "Convert a single file to stdout:";
             `Pre "  shibboleth file input.sml";
             `P "Convert to a specific output file:";
             `Pre "  shibboleth file input.sml -o output.ml";
             `P "Convert multiple related files in recommended order:";
             `Pre
               "  shibboleth file types.sig module.fun impl.sml -o combined.ml";
             `P "Convert with all name warnings enabled:";
             `Pre
               "  shibboleth file input.sml --convert-names=embed -o output.ml";
             `P "Quiet conversion with syntax checking:";
             `Pre
               "  shibboleth file input.sml -o output.ml --quiet --check-ocaml";
             `S "FILE ORDERING";
             `P
               "When providing multiple files that form a single logical \
                module, use this order:";
             `Pre
               "  1. Signature files (%.sig)\n\
               \  2. Functor files (%.fun)\n\
               \  3. Structure files (%.sml)";
             `P
               "This ensures proper name resolution and type information flow \
                during conversion.";
             `S "OUTPUT CONTROL";
             `P "Control output behavior with these flags:";
             `I
               ( "--concat-output=true",
                 "Merge all inputs into one file (default)" );
             `I ("--concat-output=false", "Generate separate output files");
             `I ("--quiet", "Suppress progress messages, show only errors");
             `I ("--check-ocaml", "Validate generated OCaml with the compiler");
           ])
    @@ let+ output = output
       and+ input = input
       and+ common_options = common_options in
       Toplevel.convert_file ~options:common_options
         ?output_file:(Option.map Toplevel.string_to_path output)
         ~input_files:(List.map Toplevel.string_to_path input)
         ?store:None
end

module Group_Convert : Command_S = struct
  let output_dir : string Term.t =
    let doc =
      "Output directory for converted OCaml files. \
       Created if it doesn't exist; use --force to overwrite."
    in
    Arg.(
      required
      & opt (some string) None
      & info [ "output" ] ~doc ~docv:"OUTPUT_DIR")

  let input_dir : string Term.t =
    let doc =
      "Input directory of SML source files. Recursively discovers \
       .sml, .sig, and .fun files, grouping related modules."
    in
    Arg.(
      required
      & opt (some string) None
      & info [ "input" ] ~doc ~docv:"INPUT_DIR")

  let run_cmd : int Cmd.t =
    let doc =
      "Batch convert a directory of SML files to OCaml. \
       Preserves directory structure. Use --force to overwrite."
    in
    Cmd.v
      (Cmd.info "group" ~doc ~docs:"SML Converter"
         ~man:
           [
             `S "EXAMPLES";
             `P "Convert an entire SML project directory:";
             `Pre
               "  shibboleth group --input ./twelf-src --output ./twelf-ocaml";
             `P "Force overwrite existing output directory:";
             `Pre "  shibboleth group --input ./src --output ./out --force";
             `P "Convert with filename normalization:";
             `Pre
               "  shibboleth group --input ./src --output ./out \
                --dash-to-underscore";
             `P "Batch convert with custom conversion flags:";
             `Pre
               "  shibboleth group --input ./src --output ./out \\\n\
               \    --convert-names=enable";
             `P "Silent batch conversion with syntax validation:";
             `Pre
               "  shibboleth group --input ./src --output ./out --quiet \
                --check-ocaml";
             `S "FILE DISCOVERY";
             `P
               "The converter recursively searches for files with these \
                extensions:";
             `I (".sml", "Standard ML structure implementations");
             `I (".sig", "Standard ML signatures");
             `I (".fun", "Standard ML functors");
             `P
               "Files with the same base name are automatically grouped for \
                conversion.";
             `S "OUTPUT CONTROL";
             `P "Control directory and file creation:";
             `I ("--force", "Overwrite existing output directory");
             `I
               ( "--dash-to-underscore",
                 "Replace dashes with underscores in filenames" );
             `I
               ( "--concat-output=true/false",
                 "Combine grouped files or keep separate" );
             `S "NOTES";
             `P
               "Large codebases may take significant time to convert. Use \
                --quiet to reduce output verbosity, or -v to increase it for \
                debugging failed conversions.";
           ])
    @@ let+ output_dir = output_dir
       and+ input_dir = input_dir
       and+ common_options = common_options in
       Toplevel.convert_group ~options:common_options
         ~output_dir:(Toplevel.string_to_path output_dir)
         ~input_dir:(Toplevel.string_to_path input_dir)
end

let cmd_convert_file : int Cmd.t = Convert_File.run_cmd
let cmd_convert_group : int Cmd.t = Group_Convert.run_cmd
