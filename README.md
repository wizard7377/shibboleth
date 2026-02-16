# Shibboleth

A source-to-source converter from Standard ML (SML '97) to OCaml, written in OCaml.

Shibboleth performs **syntactic conversion** — it translates SML source code into structurally equivalent OCaml, preserving as much of the original layout as possible. The generated code will typically need manual review for type errors and semantic differences between the languages. It has been primarily tested against the [Twelf](http://twelf.org/) project but aims to support any valid SML '97.

## Features

- Converts SML expressions, patterns, types, declarations, and module structures to OCaml
- **Batch-converts entire directory trees** with automatic file grouping (`shibboleth group`)
- Handles constructor capitalization (SML allows lowercase constructors; OCaml requires uppercase)
- Resolves SML operator precedence into proper OCaml AST structure
- Converts SML Basis library names (`SOME` -> `Some`, `NONE` -> `None`, etc.)
- Renames identifiers that conflict with OCaml reserved keywords
- Preserves comments through conversion
- Validates generated output with the OCaml compiler (`--check-ocaml`)
- Supports cross-module constructor resolution via context files (`.sctx`)

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

**Convert an entire project** (recommended for most use cases):

```bash
shibboleth group --input ./sml_src --output ./ocaml_src
```

Convert a single SML file:

```bash
shibboleth file input.sml -o output.ml
```

## Usage

### Batch Directory Conversion (`group`)

The `group` command is the recommended way to convert SML projects. It recursively discovers all `.sml`, `.sig`, and `.fun` files, automatically groups related files by base name, and preserves the directory structure in the output.

```bash
shibboleth group --input <DIR> --output <DIR> [OPTIONS]
```

**How grouping works**: Files that share the same base name (e.g., `parser.sig`, `parser.fun`, `parser.sml`) are automatically combined into a single `.ml` file. Signatures are processed first, then functors, then structures — ensuring proper name resolution.

**Examples**:

```bash
# Convert a full project
shibboleth group --input ./twelf-src --output ./twelf-ocaml

# Overwrite existing output directory
shibboleth group --input ./src --output ./out --force

# Normalize filenames (parser-utils.sml -> parser_utils.ml)
shibboleth group --input ./src --output ./out --dash-to-underscore

# Silent conversion with syntax validation
shibboleth group --input ./src --output ./out --quiet --check-ocaml

# Convert with name conflict detection
shibboleth group --input ./src --output ./out --convert-names=enable
```

A **shared context** is accumulated across all files in a group run, so constructor information discovered in earlier files is available when converting later ones. This makes `group` more accurate than converting files individually.

### Single File / Multi-File Conversion (`file`)

```bash
shibboleth file [OPTIONS] INPUT...
```

By default, output goes to stdout. Use `-o` / `--output` to write to a file.

When providing multiple files, list them in dependency order: signatures first, then functors, then structures:

```bash
shibboleth file module.sig module.fun module.sml -o module.ml
```

> [!TIP]
> When converting related files (`A.sig`, `A.fun`, `A.sml`), combine them into a single output with `--concat-output`, since OCaml's module system expects one file per module.

### Recommended Workflow

1. **Convert** your SML project using `shibboleth group` (or `shibboleth file` for individual files)
2. **Review** the generated OCaml for type errors and semantic issues
3. **Adjust flags** (see below) to handle naming conventions specific to your codebase
4. **Manually refine** areas where SML and OCaml semantics diverge (e.g., module system, equality types)

## Conversion Flags

Most conversion features use a **three-level flag system**: `enable`, `embed`, `disable`.

- **`enable`** — Apply the conversion silently
- **`embed`** — Apply the conversion and embed annotations/warnings in the output
- **`disable`** — Skip the conversion entirely

| Flag | Default | Description |
|------|---------|-------------|
| `--convert-names` | `disable` | Flag identifiers invalid in OCaml with `[@sml.bad_name]` attributes |
| `--convert-keywords` | `embed` | Rename identifiers that conflict with OCaml keywords (e.g., `method` -> `method_`) |
| `--rename-types` | `enable` | Transform type names to follow OCaml conventions |
| `--curry-expressions` | `disable` | Convert tuple-argument functions to curried form |
| `--curry-types` | `disable` | Convert tuple-argument function types to curried form |

### Name Mangling

Control how identifiers are transformed during conversion:

| Flag | Default | Values | Description |
|------|---------|--------|-------------|
| `--mangle-types` | `new` | `new`, `old`, `none` | Control how type names are mangled |
| `--mangle-constructors` | `new` | `new`, `old`, `none` | Control how constructor names are mangled |

### Additional Options

| Flag | Description |
|------|-------------|
| `--check-ocaml` | Validate generated OCaml syntax with `ocamlc` (syntax only, not types) |
| `--dash-to-underscore` | Replace dashes with underscores in output filenames |
| `--concat-output` | Merge multiple input files into a single output (used with `file` command) |
| `--force` | Overwrite existing output files and directories |
| `--context-input=<PATH>` | Load constructor context from a `.sctx` file |
| `--context-output=<PATH>` | Export constructor context to a `.sctx` file |
| `--debug=<CATEGORY>` | Enable debug output for specific subsystems |
| `-v <0-3>` | Verbosity level (0 = errors only, 3 = full debug) |
| `-q` / `--quiet` | Suppress all non-error output |

### Cross-Module Constructor Resolution

When converting a large project incrementally (using `file` rather than `group`), use context files to share constructor information between runs:

```bash
# First pass: export context
shibboleth file base.sml -o base.ml --context-output=base.sctx

# Second pass: import context from first pass
shibboleth file app.sml -o app.ml --context-input=base.sctx
```

> [!NOTE]
> The `group` command handles this automatically — it accumulates a shared context across all files, making context files unnecessary for whole-project conversions.

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
dune build                                  # Build the project
dune exec shibboleth -- file <path>         # Run against an SML file
dune exec shibboleth -- group --input <dir> --output <dir>  # Batch convert
make test                                   # Run all tests
dune exec test/unit_tests/unit_tests.exe    # Run unit tests only
dune exec test/file_tests/file_tests.exe    # Run file tests only
dune fmt                                    # Format code
dune build @doc                             # Generate API documentation
```

## License

BSD-2-Clause