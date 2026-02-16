type group_type = Library | Group [@@deriving show, eq]

type t = {
  group_type : group_type;
  sources : string list;
  dependencies : string list;
}
[@@deriving show, eq]

let source_extensions = [ ".sml"; ".sig"; ".fun" ]

let is_source path =
  List.exists (fun ext -> Filename.check_suffix path ext) source_extensions

let is_dependency path = Filename.check_suffix path ".cm"

let module_name path =
  Filename.basename path |> Filename.remove_extension
  |> Containers.String.replace ~sub:"-" ~by:"_"

let library_name path =
  if String.ends_with ~suffix:"sources.cm" path then
    Filename.dirname path |> Filename.basename
    |> Containers.String.replace ~sub:"-" ~by:"_"
  else
    Filename.basename path |> Filename.remove_extension
    |> Containers.String.replace ~sub:"-" ~by:"_"

let parse_group_type word =
  match String.lowercase_ascii word with
  | "library" -> Library
  | "group" -> Group
  | s -> failwith (Printf.sprintf "Unknown CM group type: %s" s)

let strip_comments content =
  let len = String.length content in
  let buf = Buffer.create len in
  let rec loop i =
    if i >= len then ()
    else if i + 1 < len && content.[i] = '(' && content.[i + 1] = '*' then
      skip_comment (i + 2) 1
    else begin
      Buffer.add_char buf content.[i];
      loop (i + 1)
    end
  and skip_comment i depth =
    if i >= len then ()
    else if i + 1 < len && content.[i] = '(' && content.[i + 1] = '*' then
      skip_comment (i + 2) (depth + 1)
    else if i + 1 < len && content.[i] = '*' && content.[i + 1] = ')' then
      if depth = 1 then loop (i + 2) else skip_comment (i + 2) (depth - 1)
    else skip_comment (i + 1) depth
  in
  loop 0;
  Buffer.contents buf

let parse content =
  let content = strip_comments content in
  (* Tokenize by whitespace *)
  let words =
    String.split_on_char '\n' content
    |> List.concat_map (String.split_on_char ' ')
    |> List.concat_map (String.split_on_char '\t')
    |> List.map String.trim
    |> List.filter (fun s -> s <> "")
  in
  match words with
  | [] -> failwith "Empty CM file"
  | first :: rest ->
      let group_type = parse_group_type first in
      (* Drop everything until "is" *)
      let rec skip_to_is = function
        | [] -> []
        | word :: rest ->
            if String.lowercase_ascii word = "is" then rest else skip_to_is rest
      in
      let entries = skip_to_is rest in
      let sources = List.filter is_source entries |> List.map module_name in
      let dependencies =
        List.filter is_dependency entries |> List.map library_name
      in
      { group_type; sources; dependencies }

let to_dune ~(cfg : Common.t) ~dir_name t =
  let pkg_name =
    if String.trim dir_name = "" then "main"
    else begin
      if
        String.for_all
          (fun (chr : char) ->
            chr == '_' || chr = '-'
            || Containers.Char.is_letter_ascii chr
            || Containers.Char.is_digit_ascii chr)
          dir_name
        && Common.(get @@ Misc_flag Dash_to_underscore) cfg
      then Containers.String.replace "-" "_" dir_name
      else dir_name
    end
  in
  let modules =
    match t.sources with
    | [] -> ""
    | mods ->
        " (modules "
        ^ String.concat " " (Containers.List.uniq ~eq:( = ) mods)
        ^ ")"
  in
  let libraries =
    match t.dependencies with
    | [] -> ""
    | libs ->
        " (libraries "
        ^ String.concat " " (Containers.List.uniq ~eq:( = ) libs)
        ^ ")"
  in
  match t.group_type with
  | Library ->
      Printf.sprintf "(library\n (wrapped false)\n (name %s)%s%s)" dir_name
        modules libraries
  | Group ->
      Printf.sprintf "(executable\n (name %s)%s%s)" dir_name modules libraries
