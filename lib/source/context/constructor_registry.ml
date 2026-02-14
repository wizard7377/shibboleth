open Sexplib0.Sexp_conv

type constructor_info = {
  name : string;
  path : string list;
  ocaml_name : string;
}
[@@deriving sexp, eq, ord]

module StringSet = Set.Make(String)

type t = {
  qualified : (string, constructor_info) Hashtbl.t;
  unqualified : (string, constructor_info list) Hashtbl.t;
  by_module : (string, StringSet.t) Hashtbl.t;
}

let join_path path = String.concat "." path

let has_prefix prefix lst =
  let rec go prefix lst =
    match (prefix, lst) with
    | [], _ -> true
    | _, [] -> false
    | p :: ps, l :: ls -> p = l && go ps ls
  in
  go prefix lst

let create () =
  {
    qualified = Hashtbl.create 128;
    unqualified = Hashtbl.create 128;
    by_module = Hashtbl.create 32;
  }

let add_constructor registry ~path ~name ~ocaml_name =
  let info = { name; path; ocaml_name } in
  let key = join_path path in
  Hashtbl.replace registry.qualified key info;

  (* Update module index: map the first path element to this key *)
  (match path with
  | mod_name :: _ when List.length path > 1 ->
      let existing =
        Hashtbl.find_opt registry.by_module mod_name
        |> Option.value ~default:StringSet.empty
      in
      Hashtbl.replace registry.by_module mod_name (StringSet.add key existing)
  | _ -> ());

  (* Also add to unqualified lookup table for local scope access *)
  let existing =
    Hashtbl.find_opt registry.unqualified name |> Option.value ~default:[]
  in
  Hashtbl.replace registry.unqualified name (info :: existing)

let lookup registry ~path name =
  match path with
  | Some module_path ->
      let full_key = join_path (module_path @ [ name ]) in
      Hashtbl.find_opt registry.qualified full_key
  | None -> (
      (* Check unqualified first *)
      match Hashtbl.find_opt registry.unqualified name with
      | Some (info :: _) -> Some info
      | Some [] | None ->
          (* Fall back to qualified with just [name] *)
          Hashtbl.find_opt registry.qualified name)

let open_module registry ~module_path =
  let prefix_len = List.length module_path in
  (* Use module index: look up keys for the first element of module_path *)
  match module_path with
  | [] -> ()
  | mod_name :: _ ->
      let keys =
        Hashtbl.find_opt registry.by_module mod_name
        |> Option.value ~default:StringSet.empty
      in
      StringSet.iter
        (fun key ->
          match Hashtbl.find_opt registry.qualified key with
          | None -> ()
          | Some info ->
              if has_prefix module_path info.path
                 && List.length info.path > prefix_len
              then begin
                let existing =
                  Hashtbl.find_opt registry.unqualified info.name
                  |> Option.value ~default:[]
                in
                Hashtbl.replace registry.unqualified info.name
                  (info :: existing)
              end)
        keys

let add_module_alias registry ~alias ~target =
  let target_len = List.length target in
  (* Use module index to find only constructors in the target module *)
  let keys =
    match target with
    | [] -> StringSet.empty
    | mod_name :: _ ->
        Hashtbl.find_opt registry.by_module mod_name
        |> Option.value ~default:StringSet.empty
  in
  let entries_to_add =
    StringSet.fold
      (fun key acc ->
        match Hashtbl.find_opt registry.qualified key with
        | None -> acc
        | Some info ->
            if has_prefix target info.path then
              let suffix =
                let rec drop n lst =
                  match (n, lst) with
                  | 0, lst -> lst
                  | _, [] -> []
                  | n, _ :: rest -> drop (n - 1) rest
                in
                drop target_len info.path
              in
              let new_path = alias @ suffix in
              (new_path, info) :: acc
            else acc)
      keys []
  in
  List.iter
    (fun (new_path, info) ->
      let new_info = { info with path = new_path } in
      add_constructor registry ~path:new_path ~name:new_info.name
        ~ocaml_name:new_info.ocaml_name)
    entries_to_add

let merge t1 t2 =
  let len1 = Hashtbl.length t1.qualified in
  let len2 = Hashtbl.length t2.qualified in
  let merged = {
    qualified = Hashtbl.create (len1 + len2);
    unqualified = Hashtbl.create (len1 + len2);
    by_module = Hashtbl.create (Hashtbl.length t1.by_module + Hashtbl.length t2.by_module);
  } in
  (* Copy qualified: t2 overwrites t1 on conflict *)
  Hashtbl.iter (fun k v -> Hashtbl.replace merged.qualified k v) t1.qualified;
  Hashtbl.iter (fun k v -> Hashtbl.replace merged.qualified k v) t2.qualified;
  (* Merge unqualified: concatenate info lists *)
  let merge_unqualified src =
    Hashtbl.iter (fun name infos ->
      let existing =
        Hashtbl.find_opt merged.unqualified name
        |> Option.value ~default:[]
      in
      Hashtbl.replace merged.unqualified name (infos @ existing)
    ) src.unqualified
  in
  merge_unqualified t1;
  merge_unqualified t2;
  (* Merge by_module: union the sets *)
  let merge_by_module src =
    Hashtbl.iter (fun mod_name keys ->
      let existing =
        Hashtbl.find_opt merged.by_module mod_name
        |> Option.value ~default:StringSet.empty
      in
      Hashtbl.replace merged.by_module mod_name (StringSet.union existing keys)
    ) src.by_module
  in
  merge_by_module t1;
  merge_by_module t2;
  merged

let get_all_constructors registry =
  let constructors = ref [] in
  Hashtbl.iter
    (fun _key info -> constructors := info :: !constructors)
    registry.qualified;
  !constructors
