# Shibboleth

A source-to-source converter from Standard ML (SML '97) to OCaml, written in OCaml.

Shibboleth performs **syntactic conversion** — it translates SML source code into structurally equivalent OCaml, preserving as much of the original layout as possible. The generated code will typically need manual review for type errors and semantic differences between the languages.

## Features

- Converts SML expressions, patterns, types, declarations, and module structures to OCaml
- Handles constructor capitalization (SML allows lowercase constructors; OCaml requires uppercase)
- Resolves SML operator precedence into proper OCaml AST structure
- Converts SML Basis library names (`SOME` -> `Some`, `NONE` -> `None`, etc.)
- Curries tuple-argument functions and types to idiomatic OCaml style
- Renames identifiers that conflict with OCaml reserved keywords
- Preserves comments through conversion
- Supports batch conversion of entire directory trees
- Validates generated output with the OCaml compiler (`--check-ocaml`)

## Prerequisites

- OCaml (>= 4.14)
- [opam](https://opam.ocaml.org/) (OCaml package manager)
- [Dune](https://dune.build/) (>= 3.20)

## Installation

```bash
git clone https://github.com/wizard7377/sml-ocaml-converter.git
cd sml-ocaml-converter
opam install . --deps-only
make install
```

After installation, the `shibboleth` command is available in your PATH.

## Quick Start

Convert a single SML file:

```bash
shibboleth file input.sml -o output.ml
```

Convert a module split across multiple files (recommended order):

```bash
shibboleth file types.sig module.fun impl.sml -o module.ml
```

Convert an entire project directory:

```bash
shibboleth group --input ./sml_src --output ./ocaml_src
```

## Usage

### Single File / Multi-File Conversion

```bash
shibboleth file [OPTIONS] INPUT...
```

By default, output goes to stdout. Use `-o` / `--output` to write to a file.

> [!TIP]
> It is **highly recommended** to combine related files (`A.sig`, `A.fun`, `A.sml`) into a single `A.ml`, because OCaml's module system requires one module per file. This is the default behavior — all input files are concatenated into one output. Use `--concat-output=false` to disable this.

When providing multiple files, list them in dependency order: signatures first, then functors, then structures:

```bash
shibboleth file module.sig module.fun module.sml -o module.ml
```

### Batch Directory Conversion

```bash
shibboleth group --input <DIR> --output <DIR> [OPTIONS]
```

Recursively discovers all `.sml`, `.sig`, and `.fun` files, groups related files automatically, and preserves directory structure in the output. Use `--force` to overwrite an existing output directory.

### Recommended Workflow

1. **Convert** your SML files using `shibboleth file` or `shibboleth group`
2. **Review** the generated OCaml for type errors and semantic issues
3. **Adjust flags** (see below) to handle naming conventions specific to your codebase
4. **Manually refine** areas where SML and OCaml semantics diverge (e.g., module system, equality types)

## Conversion Flags

Most conversion features use a **four-level flag system**: `enable`, `warn`, `note`, `disable`.

| Flag | Default | Description |
|------|---------|-------------|
| `--convert-names` | `disable` | Attach `[@sml.bad_name]` attributes to invalid OCaml identifiers |
| `--convert-keywords` | `warn` | Rename identifiers that conflict with OCaml keywords (e.g., `method` -> `method_`) |
| `--guess-pattern` | `warn` | Use heuristics to classify pattern identifiers as constructors vs. variables |
| `--rename-types` | `warn` | Transform type names to follow OCaml conventions |
| `--curry-expressions` | `enable` | Convert tuple-argument functions to curried form |
| `--curry-types` | `enable` | Convert tuple-argument function types to curried form |
| `--make-make-functor` | `note` | Rename SML functors to OCaml's idiomatic `Make` naming |

### Additional Options

| Flag | Description |
|------|-------------|
| `--guess-var=<REGEX>` | Convert matching uppercase variable names to `__<NAME>` format |
| `--check-ocaml` | Validate generated OCaml syntax with `ocamlc` |
| `--dash-to-underscore` | Replace dashes with underscores in output filenames |
| `--context-input=<PATH>` | Load constructor context from a `.sctx` file |
| `--context-output=<PATH>` | Export constructor context to a `.sctx` file |
| `--debug=<CATEGORY>` | Enable debug output (`parser`, `lexer`, `backend`, `names`, `types`) |
| `-v <0-3>` | Verbosity level (0 = errors only, 3 = full debug) |
| `-q` / `--quiet` | Suppress all non-error output |

### Variable Guessing

If your SML codebase uses uppercase single-letter variables (common in formal developments), use `--guess-var` to convert them:

```bash
# Convert X, Y, X', Y1, etc. to __X, __Y, __X', __Y1
shibboleth file input.sml --guess-var="[A-Z]s?[0-9]?'?" -o output.ml
```

### Cross-Module Constructor Resolution

When converting a large project incrementally, use context files to share constructor information between runs:

```bash
# First pass: export context
shibboleth file base.sml -o base.ml --context-output=base.sctx

# Second pass: import context from first pass
shibboleth file app.sml -o app.ml --context-input=base.sctx
```

## Architecture

```
SML source -> Lexer (ocamllex) -> Parser (Menhir) -> SML AST -> Backend -> OCaml Parsetree -> Pretty-printed OCaml
```

| Component | Location | Role |
|-----------|----------|------|
| AST types | `lib/source/ast/` | Complete SML abstract syntax tree |
| Frontend | `lib/source/frontend/` | Lexer + Menhir parser producing `Ast.prog` |
| Backend | `lib/source/backend/` | SML AST -> OCaml `Parsetree` via Ppxlib |
| Context | `lib/source/context/` | Name resolution and constructor registry |
| Polish | `lib/source/polish/` | Post-processing transformations on OCaml AST |
| Process | `lib/process/` | Orchestration of the full pipeline |
| CLI | `lib/cli/` | Cmdliner-based command-line interface |

The backend uses a **functor-based architecture** parameterized on context (name resolution state) and configuration (conversion flags).

For detailed architecture documentation, see [CLAUDE.md](CLAUDE.md) or generate API docs with `dune build @doc`.

## Development

```bash
dune build              # Build the project
dune exec shibboleth -- file <path>   # Run against an SML file
make test               # Run all tests
dune fmt                # Format code
dune build @doc         # Generate API documentation
```

### Testing

- **Unit tests** (`test/unit_tests/`): Alcotest tests for individual backend conversion functions
- **File tests** (`test/file_tests/`): End-to-end tests converting SML files and comparing against expected OCaml output
- **Precedence tests** (`test/precedence_tests/`): Tests for operator precedence resolution

## License

BSD-2-Clause