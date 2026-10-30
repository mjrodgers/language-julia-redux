; Syntax highlighting for Julia, for Pulsar's modern Tree-sitter.
;
; How Pulsar reads this file (see the "Modern Tree-sitter" posts on the Pulsar
; blog for the long version):
;
; * Every capture name is a scope name. Scopes on the same text accumulate, in
;   the order the patterns appear here.
; * `(#set! capture.final true)` stops any later pattern from adding a scope to
;   exactly the same range. `(#set! capture.shy true)` applies a scope only if
;   nothing has been applied to that range yet. So the specific rules come
;   first and the catch-all rules last.
; * `_TYPE_` in a capture name is replaced by the node's type; for keywords
;   (anonymous nodes) that is the keyword itself: `"if" @a._TYPE_` gives `a.if`.
; * `#is?`/`#is-not?` run Pulsar's scope tests, e.g. `test.descendantOfType`
;   ("has an ancestor of this type").
;
; Scope names follow TextMate conventions so that existing syntax themes work,
; and reuse the names from the TextMate Julia grammar (atom-language-julia)
; where that grammar had one, so highlighting looks the same after switching.
;
; Keywords are matched as bare tokens rather than through their statements, so
; that they keep their colour while a block is still being typed (until its
; `end` exists the statement is an ERROR node, but its tokens are still there).


; DEFINITIONS
; ===========
; These come first, with `capture.final`, so that a name being defined is not
; also highlighted as a call, a builtin or a type reference.

; Function names. A signature can be wrapped in a return type, a `where`, or
; both: `function f(x)::T where {T}`. Names can be qualified: `Base.show`.
(signature
  [
    (identifier) @entity.name.function.julia
    (call_expression
      . [(identifier) @entity.name.function.julia
         (field_expression (identifier) @entity.name.function.julia .)])
    (typed_expression
      . (call_expression
        . [(identifier) @entity.name.function.julia
           (field_expression (identifier) @entity.name.function.julia .)]))
    (where_expression
      . [(call_expression
          . [(identifier) @entity.name.function.julia
             (field_expression (identifier) @entity.name.function.julia .)])
         (typed_expression
           . (call_expression
             . [(identifier) @entity.name.function.julia
                (field_expression (identifier) @entity.name.function.julia .)]))])
  ]
  (#is-not? test.descendantOfType macro_definition)
  (#set! capture.final true))

(macro_definition
  (signature
    (call_expression . (identifier) @entity.name.function.macro.julia))
  (#set! capture.final true))

; Short-form definitions: `f(x) = ...`. A call on the left of `=` always
; defines a method.
(assignment
  . [(call_expression
      . [(identifier) @entity.name.function.julia
         (field_expression (identifier) @entity.name.function.julia .)])
     (typed_expression
       . (call_expression
         . [(identifier) @entity.name.function.julia
            (field_expression (identifier) @entity.name.function.julia .)]))
     (where_expression
       . [(call_expression
           . [(identifier) @entity.name.function.julia
              (field_expression (identifier) @entity.name.function.julia .)])
          (typed_expression
            . (call_expression
              . [(identifier) @entity.name.function.julia
                 (field_expression (identifier) @entity.name.function.julia .)]))])]
  (operator)
  (#set! capture.final true))

; Parameters, in the argument list of a definition (long or short form):
; `x`, `x::T`, `x = 1`, `x::T = 1`, `xs...`.
(signature
  [
    (call_expression
      (argument_list
        [(identifier) @variable.parameter.function.julia
         (typed_expression . (identifier) @variable.parameter.function.julia)
         (assignment . [(identifier) @variable.parameter.function.julia
                        (typed_expression . (identifier) @variable.parameter.function.julia)])
         (splat_expression . (identifier) @variable.parameter.function.julia)]))
    (typed_expression
      . (call_expression
        (argument_list
          [(identifier) @variable.parameter.function.julia
           (typed_expression . (identifier) @variable.parameter.function.julia)
           (assignment . [(identifier) @variable.parameter.function.julia
                          (typed_expression . (identifier) @variable.parameter.function.julia)])
           (splat_expression . (identifier) @variable.parameter.function.julia)])))
    (where_expression
      . [(call_expression
          (argument_list
            [(identifier) @variable.parameter.function.julia
             (typed_expression . (identifier) @variable.parameter.function.julia)
             (assignment . [(identifier) @variable.parameter.function.julia
                            (typed_expression . (identifier) @variable.parameter.function.julia)])
             (splat_expression . (identifier) @variable.parameter.function.julia)]))
         (typed_expression
           . (call_expression
             (argument_list
               [(identifier) @variable.parameter.function.julia
                (typed_expression . (identifier) @variable.parameter.function.julia)
                (assignment . [(identifier) @variable.parameter.function.julia
                               (typed_expression . (identifier) @variable.parameter.function.julia)])
                (splat_expression . (identifier) @variable.parameter.function.julia)])))])
  ]
  (#set! capture.final true))

(assignment
  . [(call_expression
      (argument_list
        [(identifier) @variable.parameter.function.julia
         (typed_expression . (identifier) @variable.parameter.function.julia)
         (assignment . [(identifier) @variable.parameter.function.julia
                        (typed_expression . (identifier) @variable.parameter.function.julia)])
         (splat_expression . (identifier) @variable.parameter.function.julia)]))
     (typed_expression
       . (call_expression
         (argument_list
           [(identifier) @variable.parameter.function.julia
            (typed_expression . (identifier) @variable.parameter.function.julia)
            (assignment . [(identifier) @variable.parameter.function.julia
                           (typed_expression . (identifier) @variable.parameter.function.julia)])
            (splat_expression . (identifier) @variable.parameter.function.julia)])))
     (where_expression
       . [(call_expression
           (argument_list
             [(identifier) @variable.parameter.function.julia
              (typed_expression . (identifier) @variable.parameter.function.julia)
              (assignment . [(identifier) @variable.parameter.function.julia
                             (typed_expression . (identifier) @variable.parameter.function.julia)])
              (splat_expression . (identifier) @variable.parameter.function.julia)]))
          (typed_expression
            . (call_expression
              (argument_list
                [(identifier) @variable.parameter.function.julia
                 (typed_expression . (identifier) @variable.parameter.function.julia)
                 (assignment . [(identifier) @variable.parameter.function.julia
                                (typed_expression . (identifier) @variable.parameter.function.julia)])
                 (splat_expression . (identifier) @variable.parameter.function.julia)])))])]
  (operator)
  (#set! capture.final true))

; Anonymous functions and do-blocks: `x -> ...`, `(x, y) -> ...`, `do a, b`.
(arrow_function_expression
  . [(identifier) @variable.parameter.function.julia
     (typed_expression . (identifier) @variable.parameter.function.julia)
     (argument_list
       [(identifier) @variable.parameter.function.julia
        (typed_expression . (identifier) @variable.parameter.function.julia)])]
  (#set! capture.final true))
(do_clause
  [(identifier) @variable.parameter.function.julia
   (typed_expression . (identifier) @variable.parameter.function.julia)]
  (#set! capture.final true))

; Type names in `struct`, `abstract type` and `primitive type`, and the
; supertype after `<:`: `struct Foo{T} <: AbstractFoo{T}`.
(type_head
  [(identifier) @entity.name.type.julia
   (parametrized_type_expression . (identifier) @entity.name.type.julia)
   (binary_expression
     . [(identifier) @entity.name.type.julia
        (parametrized_type_expression . (identifier) @entity.name.type.julia)])]
  (#set! capture.final true))
(type_head
  (binary_expression
    (operator)
    . [(identifier) @entity.other.inherited-class.julia
       (parametrized_type_expression . (identifier) @entity.other.inherited-class.julia)
       (field_expression (identifier) @entity.other.inherited-class.julia .)])
  (#set! capture.final true))

(module_definition
  name: (identifier) @entity.name.type.module.julia
  (#set! capture.final true))


; MODULES AND IMPORTS
; ===================

(using_statement [(identifier) (import_path)] @support.other.namespace.julia)
(import_statement [(identifier) (import_path)] @support.other.namespace.julia)
(selected_import . [(identifier) (import_path)] @support.other.namespace.julia)
(selected_import ":" @punctuation.separator.colon.julia)

["using" "import"] @keyword.control.import.julia
"export" @keyword.control.export.julia
"public" @keyword.control.public.julia
"as" @keyword.control.as.julia


; COMMENTS
; ========

(line_comment) @comment.line.number-sign.julia
((line_comment) @punctuation.definition.comment.julia
  (#set! adjust.endAfterFirstMatchOf "^#"))

(block_comment) @comment.block.number-sign-equals.julia
((block_comment) @punctuation.definition.comment.begin.julia
  (#set! adjust.endAfterFirstMatchOf "^#="))
((block_comment) @punctuation.definition.comment.end.julia
  (#set! adjust.startBeforeFirstMatchOf "=#$"))


; STRINGS
; =======
; The closing delimiter of a string is not a node of its own in this parser,
; so the end punctuation is the part of the string after its last child.

; Docstrings: a string just before a definition, at the top level of a file or
; of a `module`, `begin` or `quote` block; or the string given to `@doc`, in
; any of its forms: `@doc raw"""…""" f`, `Base.@doc "…" f`, `@doc("…", f)`,
; `@doc "…" ->` (lib/docstrings.js recognises the same ones).
;
; With "Highlight docstrings as Markdown" on (the default), lib/main.js injects
; Markdown into the text of a docstring. Then only the quotes are scoped as a
; string, so that the text is not also coloured as a string underneath the
; Markdown. The whole docstring gets `meta.docstring.julia`, for themes and
; user stylesheets. With the setting off, a docstring is one string.
;
; Docstrings are `string.quoted.triple.docstring` or
; `string.quoted.double.docstring`, by their quotes (`"""` or `"`).
;
; Each pattern is an alternation (`[ … ]`) of the places a docstring can be.

; Setting off: the whole docstring.
([
   (source_file
     (string_literal) @string.quoted.triple.docstring.julia
     .
     [(function_definition) (macro_definition) (struct_definition)
      (abstract_definition) (primitive_definition) (module_definition)
      (const_statement) (assignment) (identifier) (macrocall_expression)
      (call_expression) (field_expression)])
   (module_definition
     (block
       (string_literal) @string.quoted.triple.docstring.julia
       .
       [(function_definition) (macro_definition) (struct_definition)
        (abstract_definition) (primitive_definition) (module_definition)
        (const_statement) (assignment) (identifier) (macrocall_expression)
        (call_expression) (field_expression)]))
   (compound_statement
     (block
       (string_literal) @string.quoted.triple.docstring.julia
       .
       [(function_definition) (macro_definition) (struct_definition)
        (abstract_definition) (primitive_definition) (module_definition)
        (const_statement) (assignment) (identifier) (macrocall_expression)
        (call_expression) (field_expression)]))
   (quote_statement
     (block
       (string_literal) @string.quoted.triple.docstring.julia
       .
       [(function_definition) (macro_definition) (struct_definition)
        (abstract_definition) (primitive_definition) (module_definition)
        (const_statement) (assignment) (identifier) (macrocall_expression)
        (call_expression) (field_expression)]))
 ]
  (#match? @string.quoted.triple.docstring.julia "^[A-Za-z_]*\"\"\"")
  (#is-not? test.config language-julia-redux.markdownInDocstrings)
  (#set! capture.final true))
([
   (macrocall_expression
     [(macro_identifier (identifier) @_IGNORE_.doc)
      (field_expression (macro_identifier (identifier) @_IGNORE_.doc) .)]
     [(macro_argument_list . [(string_literal) (prefixed_string_literal)] @string.quoted.triple.docstring.julia)
      (macro_argument_list . (binary_expression . [(string_literal) (prefixed_string_literal)] @string.quoted.triple.docstring.julia))
      (argument_list . [(string_literal) (prefixed_string_literal)] @string.quoted.triple.docstring.julia)])
 ]
  (#eq? @_IGNORE_.doc "doc")
  (#match? @string.quoted.triple.docstring.julia "^[A-Za-z_]*\"\"\"")
  (#is-not? test.config language-julia-redux.markdownInDocstrings)
  (#set! capture.final true))
([
   (source_file
     (string_literal) @string.quoted.double.docstring.julia
     .
     [(function_definition) (macro_definition) (struct_definition)
      (abstract_definition) (primitive_definition) (module_definition)
      (const_statement) (assignment) (identifier) (macrocall_expression)
      (call_expression) (field_expression)])
   (module_definition
     (block
       (string_literal) @string.quoted.double.docstring.julia
       .
       [(function_definition) (macro_definition) (struct_definition)
        (abstract_definition) (primitive_definition) (module_definition)
        (const_statement) (assignment) (identifier) (macrocall_expression)
        (call_expression) (field_expression)]))
   (compound_statement
     (block
       (string_literal) @string.quoted.double.docstring.julia
       .
       [(function_definition) (macro_definition) (struct_definition)
        (abstract_definition) (primitive_definition) (module_definition)
        (const_statement) (assignment) (identifier) (macrocall_expression)
        (call_expression) (field_expression)]))
   (quote_statement
     (block
       (string_literal) @string.quoted.double.docstring.julia
       .
       [(function_definition) (macro_definition) (struct_definition)
        (abstract_definition) (primitive_definition) (module_definition)
        (const_statement) (assignment) (identifier) (macrocall_expression)
        (call_expression) (field_expression)]))
 ]
  (#not-match? @string.quoted.double.docstring.julia "^[A-Za-z_]*\"\"\"")
  (#is-not? test.config language-julia-redux.markdownInDocstrings)
  (#set! capture.final true))
([
   (macrocall_expression
     [(macro_identifier (identifier) @_IGNORE_.doc)
      (field_expression (macro_identifier (identifier) @_IGNORE_.doc) .)]
     [(macro_argument_list . [(string_literal) (prefixed_string_literal)] @string.quoted.double.docstring.julia)
      (macro_argument_list . (binary_expression . [(string_literal) (prefixed_string_literal)] @string.quoted.double.docstring.julia))
      (argument_list . [(string_literal) (prefixed_string_literal)] @string.quoted.double.docstring.julia)])
 ]
  (#eq? @_IGNORE_.doc "doc")
  (#not-match? @string.quoted.double.docstring.julia "^[A-Za-z_]*\"\"\"")
  (#is-not? test.config language-julia-redux.markdownInDocstrings)
  (#set! capture.final true))

; Setting on: the whole docstring…
([
   (source_file
     (string_literal) @meta.docstring.julia
     .
     [(function_definition) (macro_definition) (struct_definition)
      (abstract_definition) (primitive_definition) (module_definition)
      (const_statement) (assignment) (identifier) (macrocall_expression)
      (call_expression) (field_expression)])
   (module_definition
     (block
       (string_literal) @meta.docstring.julia
       .
       [(function_definition) (macro_definition) (struct_definition)
        (abstract_definition) (primitive_definition) (module_definition)
        (const_statement) (assignment) (identifier) (macrocall_expression)
        (call_expression) (field_expression)]))
   (compound_statement
     (block
       (string_literal) @meta.docstring.julia
       .
       [(function_definition) (macro_definition) (struct_definition)
        (abstract_definition) (primitive_definition) (module_definition)
        (const_statement) (assignment) (identifier) (macrocall_expression)
        (call_expression) (field_expression)]))
   (quote_statement
     (block
       (string_literal) @meta.docstring.julia
       .
       [(function_definition) (macro_definition) (struct_definition)
        (abstract_definition) (primitive_definition) (module_definition)
        (const_statement) (assignment) (identifier) (macrocall_expression)
        (call_expression) (field_expression)]))
 ]
  (#is? test.config language-julia-redux.markdownInDocstrings)
  (#set! capture.final true))
([
   (macrocall_expression
     [(macro_identifier (identifier) @_IGNORE_.doc)
      (field_expression (macro_identifier (identifier) @_IGNORE_.doc) .)]
     [(macro_argument_list . [(string_literal) (prefixed_string_literal)] @meta.docstring.julia)
      (macro_argument_list . (binary_expression . [(string_literal) (prefixed_string_literal)] @meta.docstring.julia))
      (argument_list . [(string_literal) (prefixed_string_literal)] @meta.docstring.julia)])
 ]
  (#eq? @_IGNORE_.doc "doc")
  (#is? test.config language-julia-redux.markdownInDocstrings)
  (#set! capture.final true))

; …its opening quotes…
([
   (source_file
     (string_literal ["\"" @string.quoted.double.docstring.julia "\"\"\"" @string.quoted.triple.docstring.julia])
     .
     [(function_definition) (macro_definition) (struct_definition)
      (abstract_definition) (primitive_definition) (module_definition)
      (const_statement) (assignment) (identifier) (macrocall_expression)
      (call_expression) (field_expression)])
   (module_definition
     (block
       (string_literal ["\"" @string.quoted.double.docstring.julia "\"\"\"" @string.quoted.triple.docstring.julia])
       .
       [(function_definition) (macro_definition) (struct_definition)
        (abstract_definition) (primitive_definition) (module_definition)
        (const_statement) (assignment) (identifier) (macrocall_expression)
        (call_expression) (field_expression)]))
   (compound_statement
     (block
       (string_literal ["\"" @string.quoted.double.docstring.julia "\"\"\"" @string.quoted.triple.docstring.julia])
       .
       [(function_definition) (macro_definition) (struct_definition)
        (abstract_definition) (primitive_definition) (module_definition)
        (const_statement) (assignment) (identifier) (macrocall_expression)
        (call_expression) (field_expression)]))
   (quote_statement
     (block
       (string_literal ["\"" @string.quoted.double.docstring.julia "\"\"\"" @string.quoted.triple.docstring.julia])
       .
       [(function_definition) (macro_definition) (struct_definition)
        (abstract_definition) (primitive_definition) (module_definition)
        (const_statement) (assignment) (identifier) (macrocall_expression)
        (call_expression) (field_expression)]))
 ]
  (#is? test.config language-julia-redux.markdownInDocstrings))
([
   (macrocall_expression
     [(macro_identifier (identifier) @_IGNORE_.doc)
      (field_expression (macro_identifier (identifier) @_IGNORE_.doc) .)]
     [(macro_argument_list . [(string_literal ["\"" @string.quoted.double.docstring.julia "\"\"\"" @string.quoted.triple.docstring.julia]) (prefixed_string_literal ["\"" @string.quoted.double.docstring.julia "\"\"\"" @string.quoted.triple.docstring.julia])])
      (macro_argument_list . (binary_expression . [(string_literal ["\"" @string.quoted.double.docstring.julia "\"\"\"" @string.quoted.triple.docstring.julia]) (prefixed_string_literal ["\"" @string.quoted.double.docstring.julia "\"\"\"" @string.quoted.triple.docstring.julia])]))
      (argument_list . [(string_literal ["\"" @string.quoted.double.docstring.julia "\"\"\"" @string.quoted.triple.docstring.julia]) (prefixed_string_literal ["\"" @string.quoted.double.docstring.julia "\"\"\"" @string.quoted.triple.docstring.julia])])])
 ]
  (#eq? @_IGNORE_.doc "doc")
  (#is? test.config language-julia-redux.markdownInDocstrings))

; …and its closing quotes (everything after its last child).
([
   (source_file
     (string_literal) @string.quoted.triple.docstring.julia
     .
     [(function_definition) (macro_definition) (struct_definition)
      (abstract_definition) (primitive_definition) (module_definition)
      (const_statement) (assignment) (identifier) (macrocall_expression)
      (call_expression) (field_expression)])
   (module_definition
     (block
       (string_literal) @string.quoted.triple.docstring.julia
       .
       [(function_definition) (macro_definition) (struct_definition)
        (abstract_definition) (primitive_definition) (module_definition)
        (const_statement) (assignment) (identifier) (macrocall_expression)
        (call_expression) (field_expression)]))
   (compound_statement
     (block
       (string_literal) @string.quoted.triple.docstring.julia
       .
       [(function_definition) (macro_definition) (struct_definition)
        (abstract_definition) (primitive_definition) (module_definition)
        (const_statement) (assignment) (identifier) (macrocall_expression)
        (call_expression) (field_expression)]))
   (quote_statement
     (block
       (string_literal) @string.quoted.triple.docstring.julia
       .
       [(function_definition) (macro_definition) (struct_definition)
        (abstract_definition) (primitive_definition) (module_definition)
        (const_statement) (assignment) (identifier) (macrocall_expression)
        (call_expression) (field_expression)]))
 ]
  (#match? @string.quoted.triple.docstring.julia "^[A-Za-z_]*\"\"\"")
  (#is? test.config language-julia-redux.markdownInDocstrings)
  (#set! adjust.startAt lastChild.endPosition))
([
   (macrocall_expression
     [(macro_identifier (identifier) @_IGNORE_.doc)
      (field_expression (macro_identifier (identifier) @_IGNORE_.doc) .)]
     [(macro_argument_list . [(string_literal) (prefixed_string_literal !suffix)] @string.quoted.triple.docstring.julia)
      (macro_argument_list . (binary_expression . [(string_literal) (prefixed_string_literal !suffix)] @string.quoted.triple.docstring.julia))
      (argument_list . [(string_literal) (prefixed_string_literal !suffix)] @string.quoted.triple.docstring.julia)])
 ]
  (#eq? @_IGNORE_.doc "doc")
  (#match? @string.quoted.triple.docstring.julia "^[A-Za-z_]*\"\"\"")
  (#is? test.config language-julia-redux.markdownInDocstrings)
  (#set! adjust.startAt lastChild.endPosition))
([
   (source_file
     (string_literal) @string.quoted.double.docstring.julia
     .
     [(function_definition) (macro_definition) (struct_definition)
      (abstract_definition) (primitive_definition) (module_definition)
      (const_statement) (assignment) (identifier) (macrocall_expression)
      (call_expression) (field_expression)])
   (module_definition
     (block
       (string_literal) @string.quoted.double.docstring.julia
       .
       [(function_definition) (macro_definition) (struct_definition)
        (abstract_definition) (primitive_definition) (module_definition)
        (const_statement) (assignment) (identifier) (macrocall_expression)
        (call_expression) (field_expression)]))
   (compound_statement
     (block
       (string_literal) @string.quoted.double.docstring.julia
       .
       [(function_definition) (macro_definition) (struct_definition)
        (abstract_definition) (primitive_definition) (module_definition)
        (const_statement) (assignment) (identifier) (macrocall_expression)
        (call_expression) (field_expression)]))
   (quote_statement
     (block
       (string_literal) @string.quoted.double.docstring.julia
       .
       [(function_definition) (macro_definition) (struct_definition)
        (abstract_definition) (primitive_definition) (module_definition)
        (const_statement) (assignment) (identifier) (macrocall_expression)
        (call_expression) (field_expression)]))
 ]
  (#not-match? @string.quoted.double.docstring.julia "^[A-Za-z_]*\"\"\"")
  (#is? test.config language-julia-redux.markdownInDocstrings)
  (#set! adjust.startAt lastChild.endPosition))
([
   (macrocall_expression
     [(macro_identifier (identifier) @_IGNORE_.doc)
      (field_expression (macro_identifier (identifier) @_IGNORE_.doc) .)]
     [(macro_argument_list . [(string_literal) (prefixed_string_literal !suffix)] @string.quoted.double.docstring.julia)
      (macro_argument_list . (binary_expression . [(string_literal) (prefixed_string_literal !suffix)] @string.quoted.double.docstring.julia))
      (argument_list . [(string_literal) (prefixed_string_literal !suffix)] @string.quoted.double.docstring.julia)])
 ]
  (#eq? @_IGNORE_.doc "doc")
  (#not-match? @string.quoted.double.docstring.julia "^[A-Za-z_]*\"\"\"")
  (#is? test.config language-julia-redux.markdownInDocstrings)
  (#set! adjust.startAt lastChild.endPosition))

((string_literal) @string.quoted.triple.double.julia
  (#match? @string.quoted.triple.double.julia "^\"\"\"")
  (#set! capture.final true))
(string_literal) @string.quoted.double.julia

(string_literal ["\"" "\"\"\""] @punctuation.definition.string.begin.julia)
((string_literal) @punctuation.definition.string.end.julia
  (#set! adjust.startAt lastChild.endPosition))

; Non-standard string literals: `r"..."`, `raw"..."`, `b"..."`, `md"..."`...
; The prefix is the name of the string macro that handles the string.
(prefixed_string_literal
  prefix: (identifier) @storage.type.string.julia
  (#set! capture.final true))
((prefixed_string_literal) @string.regexp.julia
  (#match? @string.regexp.julia "^r\"")
  (#set! capture.final true))
(prefixed_string_literal) @string.quoted.other.julia
(prefixed_string_literal
  suffix: (identifier) @keyword.other.option-toggle.regexp.julia
  (#set! capture.final true))

(prefixed_string_literal ["\"" "\"\"\""] @punctuation.definition.string.begin.julia)
((prefixed_string_literal !suffix) @punctuation.definition.string.end.julia
  (#set! adjust.startAt lastChild.endPosition))
((prefixed_string_literal suffix: (_)) @punctuation.definition.string.end.julia
  (#set! adjust.startAt lastChild.previousSibling.endPosition)
  (#set! adjust.endAt lastChild.startPosition))

; Commands: `ls $dir`
[(command_literal) (prefixed_command_literal)] @string.interpolated.backtick.julia
(prefixed_command_literal
  prefix: (identifier) @storage.type.string.julia
  (#set! capture.final true))
(command_literal ["`" "```"] @punctuation.definition.string.begin.julia)
(prefixed_command_literal ["`" "```"] @punctuation.definition.string.begin.julia)
((command_literal) @punctuation.definition.string.end.julia
  (#set! adjust.startAt lastChild.endPosition))

(character_literal) @string.quoted.single.julia
(escape_sequence) @constant.character.escape.julia

; Interpolation: `$x` and `$(expr)` inside strings and commands.
(string_interpolation) @meta.embedded.line.interpolation.julia
(string_interpolation "$" @punctuation.section.embedded.begin.julia
  (#set! capture.final true))
(string_interpolation "(" @punctuation.section.embedded.begin.julia
  (#set! capture.final true))
(string_interpolation ")" @punctuation.section.embedded.end.julia
  (#set! capture.final true))
(string_interpolation "$" . (identifier) @variable.other.interpolation.julia)

; `$x` inside a quoted expression.
(interpolation_expression "$" @keyword.operator.interpolation.julia
  (#set! capture.final true))


; LITERALS AND CONSTANTS
; ======================

(boolean_literal) @constant.language.boolean.julia

((integer_literal) @constant.numeric.integer.hexadecimal.julia
  (#match? @constant.numeric.integer.hexadecimal.julia "^0x")
  (#set! capture.final true))
((integer_literal) @constant.numeric.integer.binary.julia
  (#match? @constant.numeric.integer.binary.julia "^0b")
  (#set! capture.final true))
((integer_literal) @constant.numeric.integer.octal.julia
  (#match? @constant.numeric.integer.octal.julia "^0o")
  (#set! capture.final true))
(integer_literal) @constant.numeric.integer.decimal.julia
(float_literal) @constant.numeric.float.julia

((identifier) @constant.numeric.float.julia
  (#match? @constant.numeric.float.julia "^(Inf|NaN)(16|32|64)?$")
  (#set! capture.final true))
((identifier) @constant.language.julia
  (#any-of? @constant.language.julia "nothing" "missing" "undef")
  (#set! capture.final true))
((identifier) @support.constant.julia
  (#any-of? @support.constant.julia "π" "ℯ" "im" "ARGS" "ENV" "stdin" "stdout" "stderr" "devnull" "VERSION" "C_NULL" "PROGRAM_FILE" "DEPOT_PATH" "LOAD_PATH")
  (#set! capture.final true))

; Symbols: `:name`, `:+`, `:(+)`.
(quote_expression ":" @punctuation.definition.symbol.julia
  (#set! capture.final true))
(quote_expression
  [(identifier) (operator)] @constant.other.symbol.julia
  (#set! capture.final true))
(quote_expression
  (parenthesized_expression [(identifier) (operator)] @constant.other.symbol.julia)
  (#set! capture.final true))

; `begin` and `end` inside brackets mean the first and last index: `a[end]`.
((identifier) @variable.language.julia
  (#any-of? @variable.language.julia "begin" "end")
  (#is? test.descendantOfType index_expression)
  (#set! capture.final true))
; Anywhere else an identifier `begin` is a `begin` block whose `end` has not
; been typed yet.
((identifier) @keyword.control.begin.julia
  (#eq? @keyword.control.begin.julia "begin")
  (#set! capture.final true))


; MACROS
; ======

; `@time`, `Base.@kwdef`: the `@` and the name together.
(macro_identifier) @support.function.macro.julia
(macro_identifier (identifier) @_IGNORE_
  (#set! capture.final true))


; TYPES
; =====

; Exceptions and builtins are listed explicitly; these lists only add scopes
; to names that the definition rules above have not already claimed.
((identifier) @support.type.exception.julia
  (#any-of? @support.type.exception.julia
    "ArgumentError" "AssertionError" "BoundsError" "CanonicalIndexError" "CapturedException" "CompositeException" "ConcurrencyViolationError" "DimensionMismatch" "DivideError" "DomainError" "EOFError" "ErrorException" "Exception" "InexactError" "InitError" "InterruptException" "InvalidStateException" "KeyError" "LoadError" "MethodError" "MissingException" "OutOfMemoryError" "OverflowError" "ProcessFailedException" "ReadOnlyMemoryError" "SegmentationFault" "StackOverflowError" "StringIndexError" "SystemError" "TaskFailedException" "TypeError" "UndefKeywordError" "UndefRefError" "UndefVarError")
  (#set! capture.final true))

; filter(n -> isconcretetype(…) || …, names(Core) ∪ names(Base)), roughly.
((identifier) @support.type.builtin.julia
  (#any-of? @support.type.builtin.julia
    "AbstractArray" "AbstractChannel" "AbstractChar" "AbstractDict" "AbstractDisplay" "AbstractFloat" "AbstractIrrational" "AbstractMatch" "AbstractMatrix" "AbstractPattern" "AbstractRange" "AbstractSet" "AbstractSlices" "AbstractString" "AbstractUnitRange" "AbstractVecOrMat" "AbstractVector" "Any" "Array" "BigFloat" "BigInt" "BitArray" "BitMatrix" "BitSet" "BitVector" "Bool" "CartesianIndex" "CartesianIndices" "Cchar" "Cdouble" "Cfloat" "Channel" "Char" "Cint" "Cintmax_t" "Clong" "Clonglong" "Cmd" "Colon" "ColumnSlices" "Complex" "ComplexF16" "ComplexF32" "ComplexF64" "ComposedFunction" "Condition" "Cptrdiff_t" "Cshort" "Csize_t" "Cssize_t" "Cstring" "Cuchar" "Cuint" "Cuintmax_t" "Culong" "Culonglong" "Cushort" "Cvoid" "Cwchar_t" "Cwstring" "DataType" "DenseArray" "DenseMatrix" "DenseVecOrMat" "DenseVector" "Dict" "Dims" "Enum" "Expr" "Float16" "Float32" "Float64" "Function" "GlobalRef" "HTML" "IO" "IOBuffer" "IOContext" "IOStream" "IdDict" "IndexCartesian" "IndexLinear" "IndexStyle" "Int" "Int128" "Int16" "Int32" "Int64" "Int8" "Integer" "Irrational" "LazyString" "LinRange" "LineNumberNode" "LinearIndices" "MIME" "Matrix" "Method" "Missing" "Module" "NTuple" "NamedTuple" "Nothing" "Number" "OrdinalRange" "Pair" "PartialQuickSort" "PermutedDimsArray" "Pipe" "Ptr" "QuoteNode" "Rational" "RawFD" "Real" "ReentrantLock" "Ref" "Regex" "RegexMatch" "Returns" "RoundingMode" "RowSlices" "Set" "Signed" "Slices" "Some" "StepRange" "StepRangeLen" "StridedArray" "StridedMatrix" "StridedVecOrMat" "StridedVector" "String" "SubArray" "SubString" "SubstitutionString" "Symbol" "Task" "Text" "TextDisplay" "Timer" "Tuple" "Type" "TypeVar" "UInt" "UInt128" "UInt16" "UInt32" "UInt64" "UInt8" "UndefInitializer" "Union" "UnionAll" "UnitRange" "Unsigned" "Val" "VecElement" "VecOrMat" "Vector" "VersionNumber" "WeakKeyDict" "WeakRef")
  (#set! capture.final true))

; Type annotations: `x::T`, `::T`, `x::Vector{T}`, `x::Base.T`.
(typed_expression
  "::"
  .
  [(identifier) @support.other.type.julia
   (parametrized_type_expression . (identifier) @support.other.type.julia)
   (field_expression (identifier) @support.other.type.julia .)])
(unary_typed_expression
  [(identifier) @support.other.type.julia
   (parametrized_type_expression . (identifier) @support.other.type.julia)
   (field_expression (identifier) @support.other.type.julia .)])

; Type parameters: `Vector{T}`, `{T<:Real}`, `where T`, `where {T, S}`.
(parametrized_type_expression . (identifier) @support.other.type.julia)
(curly_expression
  [(identifier) @support.other.type.julia
   (binary_expression (identifier) @support.other.type.julia)])
(where_expression
  "where"
  .
  [(identifier) @support.other.type.julia
   (binary_expression (identifier) @support.other.type.julia)])


; CALLS
; =====

; Core's builtin functions.
(call_expression
  . (identifier) @support.function.builtin.julia
  (#any-of? @support.function.builtin.julia
    "applicable" "fieldtype" "getfield" "getglobal" "invoke" "isa" "isdefined" "modifyfield!" "nfields" "replacefield!" "setfield!" "setglobal!" "swapfield!" "throw" "tuple" "typeassert" "typeof")
  (#set! capture.final true))

; A name that starts with a capital letter is called as a constructor.
(call_expression
  . [(identifier) @support.other.type.julia
     (field_expression (identifier) @support.other.type.julia .)]
  (#match? @support.other.type.julia "^[A-Z]")
  (#set! capture.final true))
(broadcast_call_expression
  . [(identifier) @support.other.type.julia
     (field_expression (identifier) @support.other.type.julia .)]
  (#match? @support.other.type.julia "^[A-Z]")
  (#set! capture.final true))
(call_expression
  . [(identifier) @support.other.function.julia
     (field_expression (identifier) @support.other.function.julia .)]
  (#set! capture.final true))
(broadcast_call_expression
  . [(identifier) @support.other.function.julia
     (field_expression (identifier) @support.other.function.julia .)]
  (#set! capture.final true))


; KEYWORDS
; ========

["if" "elseif" "else"] @keyword.control.conditional._TYPE_.julia
["for" "while"] @keyword.control.loop._TYPE_.julia
["try" "catch" "finally"] @keyword.control.exception._TYPE_.julia
["begin" "let" "quote" "do"] @keyword.control._TYPE_.julia
"end" @keyword.control.end.julia

(break_statement) @keyword.control.flow.break.julia
(continue_statement) @keyword.control.flow.continue.julia
"return" @keyword.control.flow.return.julia

["function" "macro"] @storage.type._TYPE_.julia
"struct" @storage.type.struct.julia
"type" @storage.type.type.julia
["module" "baremodule"] @storage.type.module.julia
["mutable" "abstract" "primitive"] @storage.modifier._TYPE_.julia
["const" "global" "local"] @storage.modifier._TYPE_.julia
"outer" @storage.modifier.outer.julia

"where" @keyword.other.where.julia


; OPERATORS
; =========
; Most operators are `(operator)` nodes, so they are told apart by their text.
; An optional leading `.` is the broadcasting form: `.+`, `.==`.

((operator) @keyword.operator.assignment.julia
  (#eq? @keyword.operator.assignment.julia "="))
[".=" ":="] @keyword.operator.assignment.julia
(compound_assignment_expression (operator) @keyword.operator.assignment.compound.julia)
"$=" @keyword.operator.assignment.compound.julia

((operator) @keyword.operator.relation.in.julia
  (#any-of? @keyword.operator.relation.in.julia "in" "∈" "∉" "∋" "∌"))
((operator) @keyword.operator.isa.julia
  (#eq? @keyword.operator.isa.julia "isa"))
((operator) @keyword.operator.relation.types.julia
  (#any-of? @keyword.operator.relation.types.julia "<:" ">:"))
((operator) @keyword.operator.comparison.julia
  (#match? @keyword.operator.comparison.julia "^\\.?(==|!=|===|!==|<|<=|>|>=|≠|≤|≥|≡|≢|≈|≉)$"))
((operator) @keyword.operator.logical.julia
  (#match? @keyword.operator.logical.julia "^\\.?(&&|\\|\\||!)$"))
((operator) @keyword.operator.arithmetic.julia
  (#match? @keyword.operator.arithmetic.julia "^\\.?(\\+|-|\\*|/|//|\\\\|\\^|%|÷|×|⋅|±|∓)$"))
((operator) @keyword.operator.bitwise.julia
  (#match? @keyword.operator.bitwise.julia "^\\.?(&|\\||~|⊻|⊼|⊽|<<|>>|>>>)$"))
((operator) @keyword.operator.pair.julia
  (#eq? @keyword.operator.pair.julia "=>"))
((operator) @keyword.operator.applies.julia
  (#match? @keyword.operator.applies.julia "^\\.?(\\|>|<\\|)$"))
((operator) @keyword.operator.compose.julia
  (#eq? @keyword.operator.compose.julia "∘"))

(range_expression ":" @keyword.operator.range.julia)
(ternary_expression ["?" ":"] @keyword.operator.ternary.julia)
"->" @keyword.operator.arrow.julia
"..." @keyword.operator.splat.julia
"::" @keyword.operator.type.annotation.julia
(adjoint_expression "'" @keyword.operator.transpose.julia)
(field_expression "." @keyword.operator.accessor.julia)
(broadcast_call_expression "." @keyword.operator.broadcast.julia)

; Any other operator.
((operator) @keyword.operator.julia
  (#set! capture.shy true))


; PUNCTUATION
; ===========

"," @punctuation.separator.comma.julia
";" @punctuation.separator.semicolon.julia

"(" @punctuation.definition.begin.bracket.round.julia
")" @punctuation.definition.end.bracket.round.julia
"[" @punctuation.definition.begin.bracket.square.julia
"]" @punctuation.definition.end.bracket.square.julia
"{" @punctuation.definition.begin.bracket.curly.julia
"}" @punctuation.definition.end.bracket.curly.julia
