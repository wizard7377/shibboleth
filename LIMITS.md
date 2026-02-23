# Limitations of the Project

There are a number of limitations in this project's ability to correctly (or simply) convert SML to OCaml.
Here, we go over those cases, with the most difficult cases to reason about and/or the hardest to fix listed first.

---

## Uniquifying Algorithm

To "uniquify" a name, the following process is done:

1. If the name is "preserved" (unchanged), then if it ends in an underscore, we replace that with two underscores
2. If a name is changed, do (1), *then* append an underscore

This exploits the fact that OCaml allows double underscores in identifiers, which is *real* helpful.

---

## Extremely Difficult / Extremely Inelegant

These are changes that either greatly obfuscate the source code or would be quite difficult to do.

### 1. MLton/CM Build Files

We already have a passable conversion, but a truly *correct* version would be nearly impossible without a much more in-depth build system. CM files describe complex dependency graphs with path variables, conditional compilation, and library imports that have no direct OCaml/Dune equivalent.

### 2. MLLex and MLYacc

For obvious reasons. These are entirely separate tool ecosystems; SML's `*.grm` and `*.lex` files have no mechanical conversion to `ocamlyacc`/`menhir` and `ocamllex`.

### 3. Multi-Clause Functions

This is actually somewhat easy to *fix*, and we implement it here without a flag to turn it off... the problem is the fix is absolutely hideous. Namely, for any function with more than one argument, we change:

```sml
fun f P00 P01 ... = E0
  | f P10 P11 ... = E1
  | ...
```

into:

```ocaml
let rec f arg__0 arg__1 ... =
  match (arg__0, arg__1, ...) with
  | (P00, P01, ...) -> E0
  | (P10, P11, ...) -> E1
  | ...
```

This can be avoided in only two cases:
1. If the function only has one clause
2. If the function's clauses have only one parameter

This is only made slightly easier by the fact that there must be a consistent number of parameters across clauses. Note also that the synthetic `arg__N` names come from a global mutable counter, so deeply nested multi-clause functions could theoretically produce confusing (though not colliding) names.

### 4. Pattern Aliases

SML `as` patterns in complex positions don't always have a clean OCaml equivalent, particularly when nested inside constructor patterns.

### 5. Constructor Pattern Wrappers

Converting the implicit constructor/variable distinction in SML patterns requires wrapping and unwrapping that can obscure the original code's intent.

### 6. User-Defined Fixity Declarations

`infix`, `infixr`, and `nonfix` declarations are **silently dropped**. The precedence resolver only knows about hardcoded SML standard operators:

| Precedence | Assoc | Operators            |
|------------|-------|----------------------|
| 7          | Left  | `*`, `/`, `div`, `mod` |
| 6          | Left  | `+`, `-`, `^`        |
| 5          | Right | `::`, `@`            |
| 4          | Left  | `=`, `<>`, `>`, `>=`, `<`, `<=` |
| 3          | Left  | `:=`, `o`            |
| 0          | Left  | `before`             |

Any user-defined operator not in this table is treated as a value, not an infix operator. For example, `infix 5 ++ ; x ++ y` would be mis-parsed as function application rather than infix use.

### 7. `where type` Clauses

`where type` refinements on signatures are **silently dropped**. SML `sig S end where type t = int` produces only `sig S end` with no `with type` constraint in the output. The `process_typ_refine` function exists but is never called. Functors relying on `where type` for type sharing will not typecheck correctly.

### 8. `sharing type` and `sharing` (Structure Sharing)

Both `sharing type` and structure `sharing` constraints are **silently dropped**. These are fundamental SML module system features with no direct OCaml equivalent at the signature level. The base specification is emitted, but the sharing constraint is lost.

### 9. Transparent vs. Opaque Sealing

Both `:` (transparent) and `:>` (opaque) sealing produce the same OCaml output: `(M : SIG)`. OCaml *does* distinguish between `: SIG` (transparent, type equalities visible) and `:> SIG` (opaque, abstract types hidden), but the formatter always emits `:`. This means opaque sealing loses its abstraction guarantees.

### 10. `abstype` Declarations

SML's `abstype` hides constructors behind an abstract type. The converter discards the datatype binding entirely, processing only the `with` declarations. The type itself may be missing from the output, and the abstraction boundary is not preserved.

---

## Difficult / Inelegant

Things that are possible, but still difficult:

### 1. Constructor Capitalization

The reason this isn't in the above "impossible" section is because it actually is done here... it just takes a lot of work. Not only did it take up a fair bit of this project, it also takes up a lot of runtime. The way we end up doing it is as follows:

1. During the phase where we convert SML ASTs to Parsetrees, we also pick up every constructor named in a file
2. We collect all of these, combined with their scope, in a `context` (output in S-expressions as `sctx`)
3. We then use these, combined with hopes and prayers, to fix the names in patterns and expressions when cleaning up the Parsetrees
4. When I say hopes and prayers, here are some of the heuristics I went to:
   - Only the root parts of a pattern (those not applied to anything) may be variables (e.g., in `Pi f`, `Pi` is not considered a possible variable)
   - Anything qualified is assumed to be a constructor in a pattern
   - If a name starts uppercase and is either qualified or applied to arguments, it's assumed to be a constructor even without a registry entry (this can misclassify module-level functions)
   - All-caps names get title-cased: `SOME` -> `Some`, `NONE` -> `None`, but also `EOF` -> `Eof`, `HTTP` -> `Http` (which may not be desired)

### 2. Anonymous Record Types

OCaml doesn't have anonymous record types, so we convert SML `{x: int, y: int}` into generated type declarations named `__0`, `__1`, etc. (you sensing a pattern? OCaml allows double underscores, which is *real* helpful). These generated names can potentially clash with user-defined names, and the record type/expression/selector conversions use inconsistent mechanisms (see below).

### 3. Record Expression/Type/Selector Inconsistency

Three different mechanisms are used for records:
- Record **expressions** (`{x = 1, y = 2}`) become OCaml record literals (`{x = 1; y = 2}`)
- Record **types** in signatures become `[%record_type ...]` extension nodes, expanded to generated declarations
- Record **selectors** (`#x`) become object-method syntax (`fun r -> r#x`)

These don't always typecheck together, since they mix OCaml record and object semantics.

### 4. First-Class Constructors

SML allows passing constructors as values (e.g., `map SOME xs`). OCaml requires wrapping these in a function (`fun x -> Some x`). The conversion handles common cases but edge cases involving partially-applied constructors in higher-order contexts can be tricky.

### 5. Equality Type Variables

Both `'a` and `''a` (equality type variables) produce the same OCaml type variable `'a`. The equality constraint is silently lost. Similarly, `eqtype` in signatures is converted to a plain abstract type.

### 6. Word Literals

SML `0w42` (word literal, type `word`) becomes the plain integer `42`. SML `0wx1F` (hex word) becomes `0x1F`. OCaml has no `word` type, and no conversion to a library like `Unsigned` is made.

### 7. Open Record Patterns

The wildcard row in SML record patterns (`{x = a, ...}`) is dropped. SML `{x = a, ...}` matches a record with any additional fields, but the OCaml output `{x = a}` produces a closed pattern. This is a semantic difference for polymorphic record patterns.

### 8. Tuple Selector Arity

`#1` becomes `fun (r, _) -> r`, `#2` becomes `fun (_, r) -> r`, etc. The generated tuple pattern always has `max 2 n` elements, so `#1` generates a 2-tuple pattern `(r, _)` which would fail on 3-tuples or larger. This is an approximation that works for the most common case (pairs) but is not generally correct.

### 9. Manifest Search Paths

When processing `open M`, the converter tries to load constructor information from a manifest file, but always searches only `.` (the current directory). There is no way to configure additional search paths, so in any non-trivial project layout, cross-module constructor resolution may fail silently.

---

## Easy / Simple

### 1. Type Name Capitalization

Type names may not be capitalized in OCaml. This is easy because types are always syntactically separate from values, so we can do this freely without fear of converting incorrectly.

### 2. `local ... in ... end`

Becomes `open! struct ... end`. Note that this is a semantic approximation: `open!` brings names into scope for the rest of the module, whereas SML `local` strictly scopes `dec1` to be visible only within `dec2`.

### 3. First-Class Labels

`#f` becomes `fun r -> r#f` (using object-method syntax, consistent with the record-as-object representation).

### 4. File Extension Merging

`*.sig`, `*.fun`, and `*.sml` get merged into `*.ml`.

### 5. Type Variable Quantifiers in `val`

Explicit type variable quantification in `val` declarations (e.g., `val 'a f = ...`) is silently dropped. OCaml infers these, so this is usually harmless.

---

## Trivial / Elegant

1. `datatype` vs `type` becomes `type` vs `type nonrec`

---

## Stylistic

In large part, we avoid any stylistic changes and leave those up to the programmer. Of note:

1. **Snake case vs. camel case** -- No automatic conversion is attempted
2. **`Name.S` vs `NAME`** -- Module naming conventions are preserved as-is
3. **`Make_Name` vs `Name`** -- Functor/module naming distinctions are not introduced

---

## Operator Mangling

SML operators like `>>` become `op_gt_gt`, `<|` becomes `op_lt_pipe`, etc. While necessary (OCaml's identifier rules differ from SML's), the generated names are unreadable and there is no way to recover the original operator semantics without manual intervention.

Additionally, any SML operator starting with `::` (e.g., a hypothetical `::+`) gets an `@` prefix to produce `@::+`, because OCaml always tokenizes `::` as the cons constructor.

---

## Formatting Quirks

1. **`while`/`for` expressions** are always wrapped in parentheses, producing `(while ... do ... done)` even when not necessary. Valid but noisy.
2. **`Pexp_poly` nodes** emit `(!poly! ...)` in the formatter -- a debugging artifact that should never appear in production output, but will produce invalid OCaml if it does.

---

## Something Else / Annoying / Funny

Things that don't fit anywhere else:

1. **Constructor order** doesn't actually matter in SML, but it does in OCaml :P
2. **Generative functors** with no annotation (`functor F() = struct ... end`) get an empty signature `sig end` as their parameter type, which is technically valid but loses any implicit type information
3. **`FctBindOpen`** (opened-parameter functors) currently generates the functor's own name as the parameter name, which is almost certainly wrong
4. **The `process_dir` module** has methods that are `assert false` -- it's dead code, with `process_group` handling directory conversion instead
