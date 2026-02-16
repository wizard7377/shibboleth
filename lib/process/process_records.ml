(** Record type expansion pass.

    Walks the OCaml Parsetree looking for [[%record_type ...]] extension nodes
    in type positions. For each one found:
    - Generates a fresh [type __N = \{ fields... \}] type declaration
    - Replaces the extension node with [__N] (a [Ptyp_constr])
    - The generated type declarations are collected and must be inserted before
      the structure item that uses them. *)

open Ppxlib

module Builder = Ast_builder.Make (struct
  let loc = Location.none
end)

let ghost s = { Location.loc = Location.none; txt = s }

(** Extract label declarations from a [[%record_type ...]] payload. *)
let extract_record_fields (payload : Parsetree.payload) :
    Parsetree.label_declaration list option =
  match payload with
  | PStr
      [
        {
          pstr_desc = Pstr_type (_, [ { ptype_kind = Ptype_record labels; _ } ]);
          _;
        };
      ] ->
      Some labels
  | _ -> None

type state = {
  mutable counter : int;
  mutable pending_types : Parsetree.structure_item list;
}
(** State for the record expansion pass. *)

let fresh_name state =
  let n = state.counter in
  state.counter <- state.counter + 1;
  Printf.sprintf "__%d" n

module StringSet = Set.Make (String)

(** Collect all type variable names from a core type. *)
let rec collect_type_vars (acc : StringSet.t) (ct : Parsetree.core_type) :
    StringSet.t =
  match ct.ptyp_desc with
  | Ptyp_var name -> StringSet.add name acc
  | Ptyp_arrow (_, t1, t2) -> collect_type_vars (collect_type_vars acc t1) t2
  | Ptyp_tuple ts | Ptyp_constr (_, ts) ->
      List.fold_left collect_type_vars acc ts
  | Ptyp_alias (t, _) | Ptyp_poly (_, t) -> collect_type_vars acc t
  | Ptyp_extension ({ txt = "record_type"; _ }, payload) -> (
      match extract_record_fields payload with
      | Some labels ->
          List.fold_left
            (fun acc ld -> collect_type_vars acc ld.Parsetree.pld_type)
            acc labels
      | None -> acc)
  | _ -> acc

(** Collect type variables from a list of label declarations, returning a
    deduplicated list of [(core_type, variance)] pairs suitable for [~params] in
    a type declaration, plus corresponding [core_type] args. *)
let collect_label_type_vars (labels : Parsetree.label_declaration list) :
    (Parsetree.core_type * (Asttypes.variance * Asttypes.injectivity)) list
    * Parsetree.core_type list =
  let vars =
    List.fold_left
      (fun acc ld -> collect_type_vars acc ld.Parsetree.pld_type)
      StringSet.empty labels
  in
  let sorted = List.sort String.compare (StringSet.elements vars) in
  let params =
    List.map
      (fun v ->
        (Builder.ptyp_var v, (Asttypes.NoVariance, Asttypes.NoInjectivity)))
      sorted
  in
  let args = List.map (fun v -> Builder.ptyp_var v) sorted in
  (params, args)

(** Expand [[%record_type ...]] in a core type, collecting generated types. *)
let rec expand_core_type (state : state) (ct : Parsetree.core_type) :
    Parsetree.core_type =
  match ct.ptyp_desc with
  | Ptyp_extension ({ txt = "record_type"; _ }, payload) -> (
      match extract_record_fields payload with
      | Some labels ->
          let name = fresh_name state in
          let labels' = List.map (expand_label_declaration state) labels in
          let params, args = collect_label_type_vars labels' in
          let td =
            Builder.type_declaration ~name:(ghost name) ~params ~cstrs:[]
              ~kind:(Parsetree.Ptype_record labels') ~private_:Asttypes.Public
              ~manifest:None
          in
          let str_item = Builder.pstr_type Nonrecursive [ td ] in
          state.pending_types <- state.pending_types @ [ str_item ];
          Builder.ptyp_constr (ghost (Longident.Lident name)) args
      | None -> ct)
  | Ptyp_arrow (lbl, t1, t2) ->
      let t1' = expand_core_type state t1 in
      let t2' = expand_core_type state t2 in
      { ct with ptyp_desc = Ptyp_arrow (lbl, t1', t2') }
  | Ptyp_tuple ts ->
      let ts' = List.map (expand_core_type state) ts in
      { ct with ptyp_desc = Ptyp_tuple ts' }
  | Ptyp_constr (lid, args) ->
      let args' = List.map (expand_core_type state) args in
      { ct with ptyp_desc = Ptyp_constr (lid, args') }
  | Ptyp_alias (t, s) ->
      let t' = expand_core_type state t in
      { ct with ptyp_desc = Ptyp_alias (t', s) }
  | Ptyp_poly (vars, t) ->
      let t' = expand_core_type state t in
      { ct with ptyp_desc = Ptyp_poly (vars, t') }
  | _ -> ct

and expand_label_declaration (state : state) (ld : Parsetree.label_declaration)
    : Parsetree.label_declaration =
  { ld with pld_type = expand_core_type state ld.pld_type }

(** Expand record types in constructor arguments. *)
let expand_constructor_arguments (state : state)
    (args : Parsetree.constructor_arguments) : Parsetree.constructor_arguments =
  match args with
  | Pcstr_tuple cts -> Pcstr_tuple (List.map (expand_core_type state) cts)
  | Pcstr_record lds ->
      Pcstr_record (List.map (expand_label_declaration state) lds)

(** Expand record types in a constructor declaration. *)
let expand_constructor_declaration (state : state)
    (cd : Parsetree.constructor_declaration) : Parsetree.constructor_declaration
    =
  {
    cd with
    pcd_args = expand_constructor_arguments state cd.pcd_args;
    pcd_res = Option.map (expand_core_type state) cd.pcd_res;
  }

(** Expand record types in a type declaration. *)
let expand_type_declaration (state : state) (td : Parsetree.type_declaration) :
    Parsetree.type_declaration =
  let kind =
    match td.ptype_kind with
    | Ptype_abstract -> Ptype_abstract
    | Ptype_variant cds ->
        Ptype_variant (List.map (expand_constructor_declaration state) cds)
    | Ptype_record lds ->
        Ptype_record (List.map (expand_label_declaration state) lds)
    | Ptype_open -> Ptype_open
  in
  let manifest = Option.map (expand_core_type state) td.ptype_manifest in
  let params =
    List.map (fun (ct, v) -> (expand_core_type state ct, v)) td.ptype_params
  in
  {
    td with
    ptype_kind = kind;
    ptype_manifest = manifest;
    ptype_params = params;
  }

(** Expand record types in an expression. *)
let rec expand_expression (state : state) (expr : Parsetree.expression) :
    Parsetree.expression =
  match expr.pexp_desc with
  | Pexp_constraint (e, ct) ->
      let ct' = expand_core_type state ct in
      let e' = expand_expression state e in
      { expr with pexp_desc = Pexp_constraint (e', ct') }
  | Pexp_coerce (e, ct1, ct2) ->
      let ct1' = Option.map (expand_core_type state) ct1 in
      let ct2' = expand_core_type state ct2 in
      let e' = expand_expression state e in
      { expr with pexp_desc = Pexp_coerce (e', ct1', ct2') }
  | Pexp_fun (lbl, def, pat, body) ->
      let pat' = expand_pattern state pat in
      let body' = expand_expression state body in
      let def' = Option.map (expand_expression state) def in
      { expr with pexp_desc = Pexp_fun (lbl, def', pat', body') }
  | Pexp_let (rf, vbs, body) ->
      let vbs' = List.map (expand_value_binding state) vbs in
      let body' = expand_expression state body in
      { expr with pexp_desc = Pexp_let (rf, vbs', body') }
  | Pexp_function cases ->
      let cases' = List.map (expand_case state) cases in
      { expr with pexp_desc = Pexp_function cases' }
  | Pexp_match (e, cases) ->
      let e' = expand_expression state e in
      let cases' = List.map (expand_case state) cases in
      { expr with pexp_desc = Pexp_match (e', cases') }
  | Pexp_try (e, cases) ->
      let e' = expand_expression state e in
      let cases' = List.map (expand_case state) cases in
      { expr with pexp_desc = Pexp_try (e', cases') }
  | Pexp_apply (f, args) ->
      let f' = expand_expression state f in
      let args' =
        List.map (fun (lbl, e) -> (lbl, expand_expression state e)) args
      in
      { expr with pexp_desc = Pexp_apply (f', args') }
  | Pexp_tuple es ->
      let es' = List.map (expand_expression state) es in
      { expr with pexp_desc = Pexp_tuple es' }
  | Pexp_construct (lid, eopt) ->
      let eopt' = Option.map (expand_expression state) eopt in
      { expr with pexp_desc = Pexp_construct (lid, eopt') }
  | Pexp_record (fields, eopt) ->
      let fields' =
        List.map (fun (lid, e) -> (lid, expand_expression state e)) fields
      in
      let eopt' = Option.map (expand_expression state) eopt in
      { expr with pexp_desc = Pexp_record (fields', eopt') }
  | Pexp_field (e, lid) ->
      let e' = expand_expression state e in
      { expr with pexp_desc = Pexp_field (e', lid) }
  | Pexp_setfield (e1, lid, e2) ->
      let e1' = expand_expression state e1 in
      let e2' = expand_expression state e2 in
      { expr with pexp_desc = Pexp_setfield (e1', lid, e2') }
  | Pexp_ifthenelse (e1, e2, e3) ->
      let e1' = expand_expression state e1 in
      let e2' = expand_expression state e2 in
      let e3' = Option.map (expand_expression state) e3 in
      { expr with pexp_desc = Pexp_ifthenelse (e1', e2', e3') }
  | Pexp_sequence (e1, e2) ->
      let e1' = expand_expression state e1 in
      let e2' = expand_expression state e2 in
      { expr with pexp_desc = Pexp_sequence (e1', e2') }
  | _ -> expr

and expand_pattern (state : state) (pat : Parsetree.pattern) : Parsetree.pattern
    =
  match pat.ppat_desc with
  | Ppat_constraint (p, ct) ->
      let ct' = expand_core_type state ct in
      let p' = expand_pattern state p in
      { pat with ppat_desc = Ppat_constraint (p', ct') }
  | Ppat_tuple ps ->
      let ps' = List.map (expand_pattern state) ps in
      { pat with ppat_desc = Ppat_tuple ps' }
  | Ppat_construct (lid, arg) ->
      let arg' = Option.map (fun (vs, p) -> (vs, expand_pattern state p)) arg in
      { pat with ppat_desc = Ppat_construct (lid, arg') }
  | Ppat_or (p1, p2) ->
      let p1' = expand_pattern state p1 in
      let p2' = expand_pattern state p2 in
      { pat with ppat_desc = Ppat_or (p1', p2') }
  | Ppat_alias (p, lid) ->
      let p' = expand_pattern state p in
      { pat with ppat_desc = Ppat_alias (p', lid) }
  | _ -> pat

and expand_case (state : state) (c : Parsetree.case) : Parsetree.case =
  {
    c with
    pc_lhs = expand_pattern state c.pc_lhs;
    pc_guard = Option.map (expand_expression state) c.pc_guard;
    pc_rhs = expand_expression state c.pc_rhs;
  }

and expand_value_binding (state : state) (vb : Parsetree.value_binding) :
    Parsetree.value_binding =
  {
    vb with
    pvb_pat = expand_pattern state vb.pvb_pat;
    pvb_expr = expand_expression state vb.pvb_expr;
  }

(** Expand record types in a structure item, returning the item plus any
    generated type declarations that should precede it. *)
and expand_structure_item (state : state) (si : Parsetree.structure_item) :
    Parsetree.structure_item list =
  state.pending_types <- [];
  let si' =
    match si.pstr_desc with
    | Pstr_type (rf, tds) ->
        let tds' = List.map (expand_type_declaration state) tds in
        { si with pstr_desc = Pstr_type (rf, tds') }
    | Pstr_value (rf, vbs) ->
        let vbs' = List.map (expand_value_binding state) vbs in
        { si with pstr_desc = Pstr_value (rf, vbs') }
    | Pstr_module mb ->
        let mb' = expand_module_binding state mb in
        { si with pstr_desc = Pstr_module mb' }
    | Pstr_recmodule mbs ->
        let mbs' = List.map (expand_module_binding state) mbs in
        { si with pstr_desc = Pstr_recmodule mbs' }
    | Pstr_eval (e, attrs) ->
        let e' = expand_expression state e in
        { si with pstr_desc = Pstr_eval (e', attrs) }
    | Pstr_exception ec ->
        let ec' = expand_type_exception state ec in
        { si with pstr_desc = Pstr_exception ec' }
    | Pstr_modtype mtd ->
        let mtd' = expand_module_type_declaration state mtd in
        { si with pstr_desc = Pstr_modtype mtd' }
    | Pstr_include incl ->
        let incl' =
          { incl with pincl_mod = expand_module_expr state incl.pincl_mod }
        in
        { si with pstr_desc = Pstr_include incl' }
    | _ -> si
  in
  state.pending_types @ [ si' ]

and expand_module_binding (state : state) (mb : Parsetree.module_binding) :
    Parsetree.module_binding =
  { mb with pmb_expr = expand_module_expr state mb.pmb_expr }

and expand_module_expr (state : state) (me : Parsetree.module_expr) :
    Parsetree.module_expr =
  match me.pmod_desc with
  | Pmod_structure str ->
      let str' = expand_structure state str in
      { me with pmod_desc = Pmod_structure str' }
  | Pmod_functor (fp, body) ->
      let fp' = expand_functor_parameter state fp in
      let body' = expand_module_expr state body in
      { me with pmod_desc = Pmod_functor (fp', body') }
  | Pmod_constraint (me', mt) ->
      let me'' = expand_module_expr state me' in
      let mt' = expand_module_type state mt in
      { me with pmod_desc = Pmod_constraint (me'', mt') }
  | _ -> me

and expand_type_exception (state : state) (te : Parsetree.type_exception) :
    Parsetree.type_exception =
  let ec = te.ptyexn_constructor in
  let kind' =
    match ec.pext_kind with
    | Pext_decl (vars, args, res) ->
        let args' = expand_constructor_arguments state args in
        let res' = Option.map (expand_core_type state) res in
        Pext_decl (vars, args', res')
    | Pext_rebind _ as k -> k
  in
  let ec' = { ec with pext_kind = kind' } in
  { te with ptyexn_constructor = ec' }

and expand_structure (state : state) (str : Parsetree.structure) :
    Parsetree.structure =
  List.concat_map (expand_structure_item state) str

(** Convert a generated [Pstr_type] structure item to a [Psig_type] signature
    item for use in signature contexts. *)
and str_type_to_sig_type (si : Parsetree.structure_item) :
    Parsetree.signature_item =
  match si.pstr_desc with
  | Pstr_type (rf, tds) -> Builder.psig_type rf tds
  | _ -> failwith "process_records: expected Pstr_type in pending_types"

(** Expand [[%record_type ...]] in a module type. *)
and expand_module_type (state : state) (mt : Parsetree.module_type) :
    Parsetree.module_type =
  match mt.pmty_desc with
  | Pmty_signature sg ->
      let sg' = expand_signature state sg in
      { mt with pmty_desc = Pmty_signature sg' }
  | Pmty_functor (fp, body) ->
      let fp' = expand_functor_parameter state fp in
      let body' = expand_module_type state body in
      { mt with pmty_desc = Pmty_functor (fp', body') }
  | Pmty_with (mt', cstrs) ->
      let mt'' = expand_module_type state mt' in
      let cstrs' = List.map (expand_with_constraint state) cstrs in
      { mt with pmty_desc = Pmty_with (mt'', cstrs') }
  | _ -> mt

(** Expand [[%record_type ...]] in a functor parameter. *)
and expand_functor_parameter (state : state) (fp : Parsetree.functor_parameter)
    : Parsetree.functor_parameter =
  match fp with
  | Unit -> Unit
  | Named (name, mt) ->
      let mt' = expand_module_type state mt in
      Named (name, mt')

(** Expand [[%record_type ...]] in a [with] constraint. *)
and expand_with_constraint (state : state) (wc : Parsetree.with_constraint) :
    Parsetree.with_constraint =
  match wc with
  | Pwith_type (lid, td) -> Pwith_type (lid, expand_type_declaration state td)
  | Pwith_typesubst (lid, td) ->
      Pwith_typesubst (lid, expand_type_declaration state td)
  | _ -> wc

(** Expand record types in a signature item, returning the item plus any
    generated type declarations that should precede it. *)
and expand_signature_item (state : state) (si : Parsetree.signature_item) :
    Parsetree.signature_item list =
  state.pending_types <- [];
  let si' =
    match si.psig_desc with
    | Psig_value vd ->
        let vd' = expand_value_description state vd in
        { si with psig_desc = Psig_value vd' }
    | Psig_type (rf, tds) ->
        let tds' = List.map (expand_type_declaration state) tds in
        { si with psig_desc = Psig_type (rf, tds') }
    | Psig_typesubst tds ->
        let tds' = List.map (expand_type_declaration state) tds in
        { si with psig_desc = Psig_typesubst tds' }
    | Psig_exception te ->
        let te' = expand_type_exception state te in
        { si with psig_desc = Psig_exception te' }
    | Psig_module md ->
        let md' = expand_module_declaration state md in
        { si with psig_desc = Psig_module md' }
    | Psig_recmodule mds ->
        let mds' = List.map (expand_module_declaration state) mds in
        { si with psig_desc = Psig_recmodule mds' }
    | Psig_modtype mtd ->
        let mtd' = expand_module_type_declaration state mtd in
        { si with psig_desc = Psig_modtype mtd' }
    | Psig_modtypesubst mtd ->
        let mtd' = expand_module_type_declaration state mtd in
        { si with psig_desc = Psig_modtypesubst mtd' }
    | Psig_include incl ->
        let incl' =
          { incl with pincl_mod = expand_module_type state incl.pincl_mod }
        in
        { si with psig_desc = Psig_include incl' }
    | _ -> si
  in
  let sig_types = List.map str_type_to_sig_type state.pending_types in
  sig_types @ [ si' ]

(** Expand record types in a value description. *)
and expand_value_description (state : state) (vd : Parsetree.value_description)
    : Parsetree.value_description =
  { vd with pval_type = expand_core_type state vd.pval_type }

(** Expand record types in a module declaration. *)
and expand_module_declaration (state : state)
    (md : Parsetree.module_declaration) : Parsetree.module_declaration =
  { md with pmd_type = expand_module_type state md.pmd_type }

(** Expand record types in a module type declaration. *)
and expand_module_type_declaration (state : state)
    (mtd : Parsetree.module_type_declaration) :
    Parsetree.module_type_declaration =
  { mtd with pmtd_type = Option.map (expand_module_type state) mtd.pmtd_type }

(** Expand record types in a signature. *)
and expand_signature (state : state) (sg : Parsetree.signature) :
    Parsetree.signature =
  List.concat_map (expand_signature_item state) sg

(** Main entry point: expand all [[%record_type ...]] nodes in a list of
    toplevel phrases. *)
let expand_record_types (phrases : Parsetree.toplevel_phrase list) :
    Parsetree.toplevel_phrase list =
  let state = { counter = 0; pending_types = [] } in
  List.map
    (fun phrase ->
      match phrase with
      | Parsetree.Ptop_def str ->
          Parsetree.Ptop_def (expand_structure state str)
      | other -> other)
    phrases
