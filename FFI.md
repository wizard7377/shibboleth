---
generator: Asciidoctor 2.0.26
lang: en
title: ForeignFunctionInterfaceSyntax
viewport: width=device-width, initial-scale=1.0
---

:::: {#mlton-header}
::: {#mlton-header-text}
## [MLton](http://www.mlton.org/Home)
:::
::::

::: {#header}
# ForeignFunctionInterfaceSyntax
:::

:::::::::::::::::::::::::::::::::::::::::::::: {#content}
:::::: {#preamble}
::::: sectionbody
::: paragraph
MLton extends the syntax of SML with expressions that enable a
[ForeignFunctionInterface](http://www.mlton.org/ForeignFunctionInterface)
to C. The following description of the syntax uses some abbreviations.
:::

+----------------------+----------------------+-----------------------+
| C base type          | *cBaseTy*            | [Foreign Function     |
|                      |                      | Interface             |
|                      |                      | types](http://ww      |
|                      |                      | w.mlton.org/ForeignFu |
|                      |                      | nctionInterfaceTypes) |
+======================+======================+=======================+
| C argument type      | *cArgTy*             | *`cBaseTy`*~`1`~` *   |
|                      |                      | …​ * `*`cBaseTy`*~`n`~ |
|                      |                      | or `unit`             |
+----------------------+----------------------+-----------------------+
| C return type        | *cRetTy*             | *`cBaseTy`* or `unit` |
+----------------------+----------------------+-----------------------+
| C function type      | *cFuncTy*            | *`cAr                 |
|                      |                      | gTy`*` -> `*`cRetTy`* |
+----------------------+----------------------+-----------------------+
| C pointer type       | *cPtrTy*             | `MLton.Pointer.t`     |
+----------------------+----------------------+-----------------------+

::: paragraph
The type annotation and the semicolon are not optional in the syntax of
[ForeignFunctionInterface](http://www.mlton.org/ForeignFunctionInterface)
expressions. However, the type is lexed, parsed, and elaborated as an
SML type, so any type (including type abbreviations) may be used, so
long as it elaborates to a type of the correct form.
:::
:::::
::::::

:::::::::: sect1
## Address {#_address}

::::::::: sectionbody
:::: listingblock
::: content
    _address "CFunctionOrVariableName" attr... : cPtrTy;
:::
::::

::: paragraph
Denotes the address of the C function or variable.
:::

::: paragraph
`attr…​` denotes a (possibly empty) sequence of attributes. The following
attributes are recognized:
:::

::: ulist
-   `external` : import with external symbol scope (see
    [LibrarySupport](http://www.mlton.org/LibrarySupport)) (default).

-   `private` : import with private symbol scope (see
    [LibrarySupport](http://www.mlton.org/LibrarySupport)).

-   `public` : import with public symbol scope (see
    [LibrarySupport](http://www.mlton.org/LibrarySupport)).
:::

::: paragraph
See [MLtonPointer](http://www.mlton.org/MLtonPointer) for functions that
manipulate C pointers.
:::
:::::::::
::::::::::

:::::::::::: sect1
## Symbol {#_symbol}

::::::::::: sectionbody
:::: listingblock
::: content
    _symbol "CVariableName" attr... : (unit -> cBaseTy) * (cBaseTy -> unit);
:::
::::

::: paragraph
Denotes the *getter* and *setter* for a C variable. The *cBaseTy*s must
be identical.
:::

::: paragraph
`attr…​` denotes a (possibly empty) sequence of attributes. The following
attributes are recognized:
:::

::: ulist
-   `alloc` : allocate storage (and export a symbol) for the C variable.

-   `external` : import or export with external symbol scope (see
    [LibrarySupport](http://www.mlton.org/LibrarySupport)) (default if
    not `alloc`).

-   `private` : import or export with private symbol scope (see
    [LibrarySupport](http://www.mlton.org/LibrarySupport)).

-   `public` : import or export with public symbol scope (see
    [LibrarySupport](http://www.mlton.org/LibrarySupport)) (default if
    `alloc`).
:::

:::: listingblock
::: content
    _symbol * : cPtrTy -> (unit -> cBaseTy) * (cBaseTy -> unit);
:::
::::

::: paragraph
Denotes the *getter* and *setter* for a C pointer to a variable. The
*cBaseTy*s must be identical.
:::
:::::::::::
::::::::::::

::::::::::::::: sect1
## Import {#_import}

:::::::::::::: sectionbody
:::: listingblock
::: content
    _import "CFunctionName" attr... : cFuncTy;
:::
::::

::: paragraph
Denotes an SML function whose behavior is implemented by calling the C
function. See [Calling from SML to
C](http://www.mlton.org/CallingFromSMLToC) for more details.
:::

::: paragraph
`attr…​` denotes a (possibly empty) sequence of attributes. The following
attributes are recognized:
:::

::: ulist
-   `cdecl` : call with the `cdecl` calling convention (default).

-   `external` : import with external symbol scope (see
    [LibrarySupport](http://www.mlton.org/LibrarySupport)) (default).

-   `impure`: assert that the function depends upon state and/or
    performs side effects (default).

-   `private` : import with private symbol scope (see
    [LibrarySupport](http://www.mlton.org/LibrarySupport)).

-   `public` : import with public symbol scope (see
    [LibrarySupport](http://www.mlton.org/LibrarySupport)).

-   `pure`: assert that the function does not depend upon state or
    perform any side effects; such functions are subject to various
    optimizations (e.g.,
    [CommonSubexp](http://www.mlton.org/CommonSubexp),
    [RemoveUnused](http://www.mlton.org/RemoveUnused))

-   `reentrant`: assert that the function (directly or indirectly) calls
    an `_export`-ed SML function.

-   `stdcall` : call with the `stdcall` calling convention (ignored
    except on Cygwin and MinGW).
:::

:::: listingblock
::: content
    _import * attr... : cPtrTy -> cFuncTy;
:::
::::

::: paragraph
Denotes an SML function whose behavior is implemented by calling a C
function through a C function pointer.
:::

::: paragraph
`attr…​` denotes a (possibly empty) sequence of attributes. The following
attributes are recognized:
:::

::: ulist
-   `cdecl` : call with the `cdecl` calling convention (default).

-   `impure`: assert that the function depends upon state and/or
    performs side effects (default).

-   `pure`: assert that the function does not depend upon state or
    perform any side effects; such functions are subject to various
    optimizations (e.g.,
    [CommonSubexp](http://www.mlton.org/CommonSubexp),
    [RemoveUnused](http://www.mlton.org/RemoveUnused))

-   `reentrant`: assert that the function (directly or indirectly) calls
    an `_export`-ed SML function.

-   `stdcall` : call with the `stdcall` calling convention (ignored
    except on Cygwin and MinGW).
:::

::: paragraph
See [Calling from SML to C function
pointer](http://www.mlton.org/CallingFromSMLToCFunctionPointer) for more
details.
:::
::::::::::::::
:::::::::::::::

:::::::::: sect1
## Export {#_export}

::::::::: sectionbody
:::: listingblock
::: content
    _export "CFunctionName" attr... : cFuncTy -> unit;
:::
::::

::: paragraph
Exports a C function with the name `CFunctionName` that can be used to
call an SML function of the type *cFuncTy*. When the function denoted by
the export expression is applied to an SML function `f`, subsequent C
calls to `CFunctionName` will call `f`. It is an error to call
`CFunctionName` before the export has been applied. The export may be
applied more than once, with each application replacing any previous
definition of `CFunctionName`.
:::

::: paragraph
`attr…​` denotes a (possibly empty) sequence of attributes. The following
attributes are recognized:
:::

::: ulist
-   `cdecl` : call with the `cdecl` calling convention (default).

-   `private` : export with private symbol scope (see
    [LibrarySupport](http://www.mlton.org/LibrarySupport)).

-   `public` : export with public symbol scope (see
    [LibrarySupport](http://www.mlton.org/LibrarySupport)) (default).

-   `stdcall` : call with the `stdcall` calling convention (ignored
    except on Cygwin and MinGW).
:::

::: paragraph
See [Calling from C to SML](http://www.mlton.org/CallingFromCToSML) for
more details.
:::
:::::::::
::::::::::
::::::::::::::::::::::::::::::::::::::::::::::

::::: {#mlton-footer}
:::: {#mlton-footer-text}
<div>

Last updated Thu Oct 21 15:53:06 2021 -0400 by Matthew Fluet.
[Log](https://github.com/MLton/mlton/commits/master/doc/guide/src/ForeignFunctionInterfaceSyntax.adoc)
[Edit](https://github.com/MLton/mlton/edit/master/doc/guide/src/ForeignFunctionInterfaceSyntax.adoc)

</div>
::::
:::::