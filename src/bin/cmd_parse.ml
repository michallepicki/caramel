open Cmdliner

let name = "parse"

let doc = "Helper command to parse sources and dump ASTs"

let description =
  {| The Caramel compiler can take as input Erlang, Core Erlang, and OCaml files.
  |}

let info = Info.make ~name ~doc ~description

let pp_erlang_parsetree source =
  ( match Erlang.Parse.from_file source with
  | Ok structure ->
      Sexplib.Sexp.pp_hum_indent 2 Format.std_formatter
        (Erlang.Ast.sexp_of_structure structure)
  | Error (`Parser_error err) ->
      Format.fprintf Format.std_formatter "ERROR: %s%!\n" err );
  Format.fprintf Format.std_formatter "\n%!"

let pp_ocaml_parsetree source_file =
  let tool_name = "caramelc-" ^ name in
  Clflags.dump_parsetree := true;
  Compile_common.with_info ~native:false ~tool_name ~source_file
    ~output_prefix:".none" ~dump_ext:"cmo" (fun info ->
      let parsetree = Compile_common.parse_impl info in
      ignore parsetree)

let pp_ocaml_typedtree ~stdlib_path source_file =
  let tool_name = "caramelc-" ^ name in
  Compile_common.with_info ~native:false ~tool_name ~source_file
    ~output_prefix:".none" ~dump_ext:"cmo" (fun i ->
      try
        Caramel_compiler.Compiler.initialize_compiler ~stdlib_path ();
        Compile_common.parse_impl i
        |> Typemod.type_implementation i.source_file i.output_prefix
             i.module_name i.env
        |> Printtyped.implementation_with_coercion i.ppf_dump
      with Env.Error err -> Env.report_error i.ppf_dump err)

let run stdlib_path sources language tree =
  let parser =
    match (language, tree) with
    | `Erlang, _ -> pp_erlang_parsetree
    | `OCaml, `Parsetree -> pp_ocaml_parsetree
    | `OCaml, `Typedtree -> pp_ocaml_typedtree ~stdlib_path
  in
  List.iter parser sources

let cmd =
  let sources =
    Arg.(
      non_empty & pos_all string []
      & info [] ~docv:"SOURCES" ~doc:"A list of source files to parse")
  in
  let tree =
    let trees = Arg.enum [ ("parse", `Parsetree); ("typed", `Typedtree) ] in
    Arg.(
      value
      & opt ~vopt:`Parsetree trees `Parsetree
      & info [ "t"; "tree" ] ~docv:"tree" ~doc:"Which stage AST to print")
  in
  let language =
    let languages = Arg.enum [ ("erl", `Erlang); ("ml", `OCaml) ] in
    Arg.(
      value
      & opt ~vopt:`Erlang languages `Erlang
      & info [ "l"; "lang" ] ~docv:"language"
          ~doc:"The source language to parse")
  in
  (Term.(pure run $ Common_flags.stdlib_path $ sources $ language $ tree), info)
