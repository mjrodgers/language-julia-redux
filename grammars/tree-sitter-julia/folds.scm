; Code folding for Julia, for Pulsar's modern Tree-sitter.
;
; A `@fold` starts at the end of the node's first row. By default it ends where
; the node's last child starts, which for a block is its `end` keyword and for
; a bracketed list its closing bracket, so those stay visible. Only one fold can
; start on a row; when several match, the one whose node starts first wins.


; BLOCKS THAT END WITH `end`
; ==========================

[
  (module_definition)
  (struct_definition)
  (function_definition)
  (macro_definition)
  (for_statement)
  (while_statement)
  (let_statement)
  (quote_statement)
  (compound_statement)
  (do_clause)
] @fold


; BLOCKS WITH SEVERAL BRANCHES
; ============================
; `if`/`elseif`/`else` and `try`/`catch`/`finally`: each branch folds on its
; own, up to the line before the next branch (or before `end`).
;
; The first branch has no node of its own, so it is a divided fold: it starts at
; the keyword and ends where the first block ends. The first `@fold.end` after a
; `@fold.start` closes it, and a block always starts before anything nested in
; it, so nested statements cannot steal it.

(if_statement "if" @fold.start alternative: (_))
(if_statement
  (block) @fold.end
  (#set! fold.endAt endPosition)
  (#set! fold.adjustToEndOfPreviousRow true))

; An `if` with no other branches is an ordinary fold.
((if_statement !alternative) @fold)

(try_statement "try" @fold.start)
(try_statement
  (block) @fold.end
  (#set! fold.endAt endPosition)
  (#set! fold.adjustToEndOfPreviousRow true))

; Each later branch ends where its node ends: at the start of the next branch's
; row, so back up to the end of the row before.
([(elseif_clause) (else_clause) (catch_clause) (finally_clause)] @fold
  (#set! fold.endAt endPosition)
  (#set! fold.adjustToEndOfPreviousRow true))


; STRINGS AND COMMENTS
; ====================
; The closing `"""` or `=#` is not a separate node, so end on the row before
; the one it is on.

([(string_literal) (prefixed_string_literal) (command_literal) (block_comment)] @fold
  (#set! fold.endAt endPosition)
  (#set! fold.adjustToEndOfPreviousRow true))


; BRACKETS
; ========
; Calls, arrays, tuples and so on that span several lines, folded up to their
; closing bracket.

[
  (argument_list)
  (vector_expression)
  (matrix_expression)
  (tuple_expression)
  (parenthesized_expression)
  (curly_expression)
  (comprehension_expression)
] @fold

; Long `using`/`import`/`export` lists.
([(using_statement) (import_statement) (export_statement)] @fold
  (#set! fold.endAt endPosition))
