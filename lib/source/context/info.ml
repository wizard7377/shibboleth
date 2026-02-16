type path = string list
type name_info = ..
type name_info += ConstructorInfo of { arity : int option }
type name_info += ModuleInfo of { maps_to : path option }
type name = { path : path; root : string }
type t = (name, name_info) Hashtbl.t

let empty : t = Hashtbl.create 0

let create (entries : (name * name_info) list) : t =
  match entries with
  | [] -> empty
  | _ ->
      let table = Hashtbl.create (List.length entries) in
      List.iter (fun (n, info) -> Hashtbl.add table n info) entries;
      table

let merge (t1 : t) (t2 : t) : t =
  let len1 = Hashtbl.length t1 in
  let len2 = Hashtbl.length t2 in
  if len1 = 0 && len2 = 0 then empty
  else if len1 = 0 then Hashtbl.copy t2
  else if len2 = 0 then Hashtbl.copy t1
  else begin
    let merged = Hashtbl.copy t1 in
    Hashtbl.iter (fun k v -> Hashtbl.replace merged k v) t2;
    merged
  end

module PathSet = Set.Make (struct
  type t = string list

  let compare = compare
end)

let find ~(ctx : t) ~(opened : path list) ~(root : string) : name_info list =
  let opened_set = PathSet.of_list opened in
  let results = ref [] in
  Hashtbl.iter
    (fun n info ->
      if n.root = root && PathSet.mem n.path opened_set then
        results := info :: !results)
    ctx;
  !results
