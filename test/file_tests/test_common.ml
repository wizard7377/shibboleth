open Common

module type S = sig
  val test_name : string
  val test_desc : string
  val test_source : Fpath.t list
  val test_expect : Fpath.t
  val test_args : Common.arg list
  val test_context : Fpath.t option
  val expect_context : Fpath.t option
  val actual_dir : Fpath.t option
  val check_comments : bool
end

module Make (M : S) = struct
  include M

  let ensure_data_prefix (path : Fpath.t) : Fpath.t =
    let segments = Fpath.segs path in
    match segments with
    | "test" :: "file_tests" :: "data" :: _ -> path
    | "test" :: "file_tests" :: rest ->
        Fpath.v
          (String.concat Fpath.dir_sep
             ("test" :: "file_tests" :: "data" :: rest))
    | _ ->
        Fpath.v
          (String.concat Fpath.dir_sep
             ("test" :: "file_tests" :: "data" :: segments))

  let resolve_path (path : Fpath.t) : Fpath.t =
    if Fpath.is_abs path then path
    else
      let with_prefix = ensure_data_prefix path in
      match Sys.getenv_opt "DUNE_SOURCEROOT" with
      | None -> with_prefix
      | Some root ->
          Fpath.v (Filename.concat root (Fpath.to_string with_prefix))

  let read_file path =
    let resolved = resolve_path path in
    match Bos.OS.File.read resolved with
    | Ok contents -> contents
    | Error (`Msg msg) -> failwith msg

  let actual_path_from_expected (expected_path : Fpath.t) : Fpath.t =
    match M.actual_dir with
    | Some dir ->
        let resolved_dir = resolve_path dir in
        let filename_path = Fpath.basename expected_path in
        Fpath.(resolved_dir / filename_path)
    | None ->
        let replace_first_expect segments =
          let rec loop acc = function
            | [] -> List.rev acc
            | seg :: rest when seg = "expect" ->
                List.rev acc @ ("actual" :: rest)
            | seg :: rest -> loop (seg :: acc) rest
          in
          loop [] segments
        in
        let resolved = resolve_path expected_path in
        let segments = Fpath.segs resolved in
        let replaced = replace_first_expect segments in
        Fpath.v (String.concat Fpath.dir_sep replaced)

  let write_actual_output ~expected_path ~contents =
    let actual_path = actual_path_from_expected expected_path in
    let parent_dir = Fpath.parent actual_path in
    let _ = Bos.OS.Dir.create ~path:true parent_dir in
    let _ = Bos.OS.File.delete actual_path in
    Bos.OS.File.write actual_path contents |> ignore

  let with_temp_context_file f =
    let path = Fpath.v (Filename.temp_file "shibboleth_context_" ".sctx") in
    Fun.protect
      ~finally:(fun () -> ignore (Bos.OS.File.delete path))
      (fun () -> f path)

  let strip_attributes (input : string) : string =
    let len = String.length input in
    let buf = Buffer.create len in
    let rec skip_attribute i =
      if i >= len then i
      else if input.[i] = ']' then i + 1
      else skip_attribute (i + 1)
    in
    let skip_post_attribute i =
      if i + 1 < len && input.[i] = ';' && input.[i + 1] = ';' then i + 2 else i
    in
    let rec loop i =
      if i >= len then ()
      else if
        i + 2 < len
        && input.[i] = '['
        && input.[i + 1] = '@'
        && input.[i + 2] = '@'
      then
        let next = skip_attribute (i + 3) in
        let after = skip_post_attribute next in
        loop after
      else begin
        Buffer.add_char buf input.[i];
        loop (i + 1)
      end
    in
    loop 0;
    Buffer.contents buf

  let strip_comments (input : string) : string =
    let len = String.length input in
    let buf = Buffer.create len in
    let rec skip_comment i depth =
      if i >= len then i
      else if i + 1 < len && input.[i] = '(' && input.[i + 1] = '*' then
        skip_comment (i + 2) (depth + 1)
      else if i + 1 < len && input.[i] = '*' && input.[i + 1] = ')' then
        if depth = 1 then i + 2 else skip_comment (i + 2) (depth - 1)
      else skip_comment (i + 1) depth
    in
    let rec loop i =
      if i >= len then ()
      else if i + 1 < len && input.[i] = '(' && input.[i + 1] = '*' then
        let next = skip_comment (i + 2) 1 in
        loop next
      else begin
        Buffer.add_char buf input.[i];
        loop (i + 1)
      end
    in
    loop 0;
    Buffer.contents buf

  let is_whitespace = function
    | ' ' | '\t' | '\n' | '\r' | '\x0b' | '\x0c' -> true
    | _ -> false

  let normalize_output ~check_comments (input : string) : string =
    let stripped = strip_attributes input in
    let stripped =
      if check_comments then stripped else strip_comments stripped
    in
    let buf = Buffer.create (String.length stripped) in
    String.iter
      (fun ch -> if not (is_whitespace ch) then Buffer.add_char buf ch)
      stripped;
    Buffer.contents buf

  let build_config ~output_buffer ~context_output =
    let input_files =
      List.map (fun p -> Fpath.to_string (resolve_path p)) M.test_source
    in
    let base_args =
      [
        Common.set (File_flag Input_file) (File input_files);
        Common.set (File_flag Output_file) (BufferOut output_buffer);
        Common.set (Misc_flag Concat_output) true;
      ]
    in
    let args =
      match M.test_context with
      | None -> base_args
      | Some context_path ->
          Common.set (File_flag Context_input)
            (Some (Fpath.to_string context_path))
          :: base_args
    in
    let args =
      match context_output with
      | None -> args
      | Some output_path ->
          Common.set (File_flag Context_output)
            (Some (Fpath.to_string output_path))
          :: args
    in
    Common.create (args @ M.test_args)

  let run () =
    let output_buffer = Buffer.create 16384 in
    let input_files =
      List.map (fun p -> Fpath.to_string (resolve_path p)) M.test_source
    in
    let run_with_context context_output =
      let cfg = build_config ~output_buffer ~context_output in
      let processor = new Process.process cfg in
      let exit_code = processor#run (File input_files) in
      Alcotest.(check int) "exit code" 0 exit_code;
      let actual_raw = Buffer.contents output_buffer in
      write_actual_output ~expected_path:M.test_expect ~contents:actual_raw;
      let expected =
        normalize_output ~check_comments:M.check_comments
          (read_file M.test_expect)
      in
      let actual =
        normalize_output ~check_comments:M.check_comments actual_raw
      in
      Alcotest.(check string) M.test_desc expected actual
    in
    match M.expect_context with
    | None -> run_with_context None
    | Some expected_context ->
        with_temp_context_file (fun context_output ->
            run_with_context (Some context_output);
            let actual_raw = read_file context_output in
            write_actual_output ~expected_path:expected_context
              ~contents:actual_raw;
            let expected =
              normalize_output ~check_comments:M.check_comments
                (read_file expected_context)
            in
            let actual =
              normalize_output ~check_comments:M.check_comments actual_raw
            in
            Alcotest.(check string) "context output" expected actual)

  let case = Alcotest.test_case M.test_name `Quick run
end
