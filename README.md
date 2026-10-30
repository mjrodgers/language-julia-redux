# Julia for Pulsar (modern Tree-sitter)

Julia language support for [Pulsar](https://pulsar-edit.dev), built on the [tree-sitter-julia](https://github.com/tree-sitter/tree-sitter-julia) parser through Pulsar's modern (WASM) Tree-sitter system. It replaces the TextMate-based [`language-julia`](https://github.com/JuliaEditorSupport/atom-language-julia) package.

It works on its own, and pairs with [pulsar-ide-julia](https://github.com/mjrodgers/pulsar-ide-julia) for language-server features (completion, diagnostics, go to definition) and the REPL.

## Features

- **Syntax highlighting** that follows the structure of the code: function and macro names where they are defined, parameters, type annotations and type parameters, supertypes, string interpolation, regex and other prefixed strings, commands, symbols, and `begin`/`end` inside indexing. Keywords stay highlighted while a block is still being typed.
- **Docstrings** are highlighted as Markdown, since Julia docstrings are Markdown: only their quotes are coloured as a string. Code in them is highlighted as Julia: the indented signature at the top, and code blocks marked `julia`, `@example`, `@repl`, `@setup` or `@eval`, or not marked at all. In `jldoctest` and `julia-repl` examples, the input after each `julia>` prompt is highlighted as Julia and the prompts are marked, while the output is left alone. Docstring lines get a faint background and a guide down their left edge. A docstring is a string just before a definition (at the top level of a file, or of a `module`, `begin` or `quote` block) or the string given to `@doc` in any of its forms: `@doc raw"""…""" f`, `Base.@doc "…" f`, `@doc("…", f)`, `@doc "…" ->`.
- `md"..."` strings are highlighted as Markdown and `html"..."` strings as HTML.
- **Indentation** as you type and with **Edit › Lines › Auto Indent**, following the conventions used by Runic and JuliaFormatter: four spaces, module bodies not indented, one extra level for continuation lines.
- **Code folding** for blocks, for each branch of `if`/`elseif`/`else` and `try`/`catch`/`finally`, for multi-line calls, arrays and tuples, and for long strings, docstrings and block comments.
- **Go to Symbol** (`symbols-view`) lists functions with their argument lists, so the methods of a function can be told apart, plus macros, types, modules and constants.
- Fenced ```` ```julia ```` code blocks in Markdown files are highlighted, as are Documenter's ```` ```@example ````, ```` ```@repl ````, ```` ```@setup ```` and ```` ```@eval ```` blocks and the input in ```` ```jldoctest ```` and ```` ```julia-repl ```` blocks.
- URLs in comments and strings are clickable, and `TODO`/`FIXME` in comments are highlighted (with Pulsar's bundled `hyperlink` and `todo` packages).
- **Snippets** (type the prefix, then Tab):
  - definitions: `function`, `functiond` (with a docstring), `macro`, `struct`, `mutable`, `kwdef`, `abstract`, `primitive`, `show` (a `Base.show` method), `main` (a `(@main)` entry point);
  - control flow and blocks: `if`, `ife`, `ifelseif`, `elseif`, `for`, `while`, `try`, `tryf`, `trycf`, `begin`, `let`, `do`, `quote`;
  - modules: `module`, `using`, `usingf` (`using Package: names`), `import`, `include`;
  - tests: `testset`, `test`, `test_throws`;
  - inside docstrings: `examples` (an Examples section with a `jldoctest` block), `jldoctest`, `arguments`, `!!!` (an admonition);
  - and `#!` (shebang), `#=` (block comment).

## Requirements

Pulsar 1.127 or later, with **Use Tree-sitter Parsers** enabled (Settings › Core; on by default).

If the old `language-julia` package is also installed, Pulsar uses this grammar for `.jl` files while Tree-sitter parsers are enabled, but both packages' snippets are offered. Disabling `language-julia` avoids the duplicates.

## Settings

- **Highlight docstrings as Markdown** (on by default). Turn it off to show docstrings as plain strings. Reopen open files after changing it.
- **Highlight Julia in doctests and REPL examples** (on by default): highlight the input in `jldoctest` and `julia-repl` blocks as Julia, and mark the `julia>` prompts. Reopen open files after changing it.
- **Docstring background** and **Docstring guide** (both on by default): the faint background behind docstring lines and the line down their left edge.

The background, guide and prompts take their colours from your syntax theme. To change them, or to style the text of docstrings (scope `meta.docstring.julia`), add rules to your stylesheet (**Edit › Stylesheet…**), for example:

```less
@import "syntax-variables";

// The background and guide of docstring lines
atom-text-editor .line.julia-docstring-background { background-color: rgba(120, 160, 255, 0.06); }
atom-text-editor .line.julia-docstring-guide { box-shadow: inset 3px 0 0 rgba(120, 160, 255, 0.4); }

// Docstring text a little dimmer than code
atom-text-editor .syntax--meta.syntax--docstring { color: fade(@syntax-text-color, 75%); }

// The `julia>` prompts in REPL examples
atom-text-editor .julia-repl-prompt { color: #4c9a2a; }
```

## Commands

- `language-julia:toggle-docstrings`: fold or unfold the docstring under the cursor. Outside a docstring the key press is passed on, so it can share a key with another command.
- `language-julia:toggle-all-docstrings`: fold every docstring in the file, or unfold them all.

These have no key bindings by default. For example, in your `keymap.cson`:

```cson
'atom-text-editor[data-grammar="source julia"]:not([mini])':
  'tab': 'language-julia:toggle-docstrings'
  'shift-tab': 'language-julia:toggle-all-docstrings'
```

## Development

The Tree-sitter queries are in `grammars/tree-sitter-julia`:

| File | Purpose |
| --- | --- |
| `highlights.scm` | syntax highlighting (scope names) |
| `indents.scm` | indentation |
| `folds.scm` | code folding |
| `tags.scm` | symbols for Go to Symbol |

`lib/main.js` adds the injections (Markdown in docstrings, Julia in their code blocks, Markdown/HTML in `md""`/`html""` strings) and the docstring commands; `lib/docstrings.js` finds docstrings and marks their lines, and `lib/doctests.js` finds the inputs and prompts in REPL examples; the marks are styled by `styles/docstrings.less`. The [Pulsar documentation on modern Tree-sitter grammars](https://docs.pulsar-edit.dev/developing-for-pulsar/creating-a-grammar-modern-tree-sitter/) and the [series of posts on the Pulsar blog](https://blog.pulsar-edit.dev/tag/tree-sitter/) explain how these files are used.

Run the specs with `pulsar --test spec`. They cover:

- highlighting: `spec/fixtures/grammar/syntax_test_julia.jl`, where comments like `#   ^ scope` assert the scope at that column of the line above;
- indentation: every file in `spec/fixtures/indentation` is re-indented from scratch and typed out line by line, and must come out unchanged;
- folding and the docstring commands.

`tree-sitter-julia.wasm` is built from tree-sitter-julia v0.25.0 (recorded as `parserSource` in the grammar file). When updating it, rebuild it from the parser with `tree-sitter build --wasm`, update `parserSource`, then run the specs: node names in the queries may change between parser versions.

## Credits

Some snippets and the docstring commands come from [atom-language-julia](https://github.com/JuliaEditorSupport/atom-language-julia) by the JuliaEditorSupport contributors, whose scope names this grammar also reuses, so that syntax themes treat Julia code the same way. The parser is [tree-sitter-julia](https://github.com/tree-sitter/tree-sitter-julia) v0.25.0.
