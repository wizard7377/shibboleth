open Sexplib0.Sexp_conv

type constructor_info = {
  name : string;
  path : string list;
  ocaml_name : string;
}
[@@deriving sexp, eq, ord]

type t = {
  qualified : (string, constructor_info) Hashtbl.t;
  unqualified : (string, constructor_info list) Hashtbl.t;
  by_module : (string, string list) Hashtbl.t;
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
        |> Option.value ~default:[]
      in
      if not (List.mem key existing) then
        Hashtbl.replace registry.by_module mod_name (key :: existing)
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
        |> Option.value ~default:[]
      in
      List.iter
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
    | [] -> []
    | mod_name :: _ ->
        Hashtbl.find_opt registry.by_module mod_name
        |> Option.value ~default:[]
  in
  let entries_to_add =
    List.filter_map
      (fun key ->
        match Hashtbl.find_opt registry.qualified key with
        | None -> None
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
              Some (new_path, info)
            else None)
      keys
  in
  List.iter
    (fun (new_path, info) ->
      let new_info = { info with path = new_path } in
      add_constructor registry ~path:new_path ~name:new_info.name
        ~ocaml_name:new_info.ocaml_name)
    entries_to_add

let merge t1 t2 =
  let merged = create () in
  (* Copy all entries from t1, then t2, using add_constructor to keep
     all three tables (qualified, unqualified, by_module) consistent *)
  Hashtbl.iter
    (fun _key info ->
      add_constructor merged ~path:info.path ~name:info.name
        ~ocaml_name:info.ocaml_name)
    t1.qualified;
  Hashtbl.iter
    (fun _key info ->
      add_constructor merged ~path:info.path ~name:info.name
        ~ocaml_name:info.ocaml_name)
    t2.qualified;
  merged

let get_all_constructors registry =
  let constructors = ref [] in
  Hashtbl.iter
    (fun _key info -> constructors := info :: !constructors)
    registry.qualified;
  !constructors
