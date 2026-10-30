; Indentation for Julia, for Pulsar's modern Tree-sitter (see `IndentResolver` in Pulsar's
; src/wasm-tree-sitter-language-mode.js for how these captures are used).
;
; In short: when you press Enter, the new line's indent is the previous line's,
; plus one level if that line has more openers (`@indent`) than closers
; (`@dedent`) after its first opener. A line that *starts* with a closer is then
; dedented one level. `@match.next` / `@match` override both with the indent of a
; specific earlier line. Captures with empty text (nodes Tree-sitter inserts to
; recover from errors, such as a missing `end`) are ignored.
;
; Module bodies are not indented (the Julia convention, which Runic and
; JuliaFormatter follow), so `module`/`baremodule` are deliberately absent.

; KEYWORDS THAT DO NOT OPEN A BLOCK
; =================================

; `for` and `if` inside comprehensions and generators: `[x for x in xs if x > 0]`.
(for_clause "for" @_IGNORE_
  (#set! capture.final true))
(if_clause "if" @_IGNORE_
  (#set! capture.final true))


; CLOSING A SIGNATURE THAT SPANS SEVERAL LINES
; ============================================

; function g(
;     a,
; )               <- the body that follows is one level deeper than `function`,
;     a + 1          whichever style the arguments use (JuliaFormatter's above,
; end                or Runic's arguments at two levels with `)` at one).
;
; Listed per shape of signature (plain, with `where`, with a return type), and
; again for a definition still being typed, which has no `end` yet and so is
; parsed as an ERROR node. `indent.match` points at the `function`/`macro`
; keyword just before the signature.
(function_definition
  (signature (call_expression (argument_list ")" @match.next)))
  (#is? test.firstTextOnRow)
  (#set! indent.match parent.parent.parent.previousSibling.startPosition)
  (#set! indent.offset 1))
(function_definition
  (signature (where_expression (call_expression (argument_list ")" @match.next))))
  (#is? test.firstTextOnRow)
  (#set! indent.match parent.parent.parent.parent.previousSibling.startPosition)
  (#set! indent.offset 1))
(function_definition
  (signature (typed_expression (call_expression (argument_list ")" @match.next))))
  (#is? test.firstTextOnRow)
  (#set! indent.match parent.parent.parent.parent.previousSibling.startPosition)
  (#set! indent.offset 1))
(macro_definition
  (signature (call_expression (argument_list ")" @match.next)))
  (#is? test.firstTextOnRow)
  (#set! indent.match parent.parent.parent.previousSibling.startPosition)
  (#set! indent.offset 1))

(ERROR
  ["function" "macro"] .
  (signature (call_expression (argument_list ")" @match.next)))
  (#is? test.firstTextOnRow)
  (#set! indent.match parent.parent.parent.previousSibling.startPosition)
  (#set! indent.offset 1))
(ERROR
  "function" .
  (signature (where_expression (call_expression (argument_list ")" @match.next))))
  (#is? test.firstTextOnRow)
  (#set! indent.match parent.parent.parent.parent.previousSibling.startPosition)
  (#set! indent.offset 1))
(ERROR
  "function" .
  (signature (typed_expression (call_expression (argument_list ")" @match.next))))
  (#is? test.firstTextOnRow)
  (#set! indent.match parent.parent.parent.parent.previousSibling.startPosition)
  (#set! indent.offset 1))


; A CONDITION THAT SPANS SEVERAL LINES
; ====================================

; while (a > 0 &&
;     b > 0)      <- the block's body follows, one level deeper than `while`.
;     a -= 1
; end
;
; Comes before the rules below, which would otherwise send the next line back to
; the `while` row: the first `@match.next` on a row wins, and the condition starts
; before anything inside it.
(if_statement
  condition: (_) @match.next
  (#is? test.lastTextOnRow)
  (#is-not? test.startsOnSameRowAs endPosition)
  (#set! indent.match parent.startPosition)
  (#set! indent.offset 1))
(elseif_clause
  condition: (_) @match.next
  (#is? test.lastTextOnRow)
  (#is-not? test.startsOnSameRowAs endPosition)
  (#set! indent.match parent.startPosition)
  (#set! indent.offset 1))
(while_statement
  condition: (_) @match.next
  (#is? test.lastTextOnRow)
  (#is-not? test.startsOnSameRowAs endPosition)
  (#set! indent.match parent.startPosition)
  (#set! indent.offset 1))


; While the block is still being typed (no `end` yet) it is an ERROR node, with
; the condition right after its keyword.
((ERROR ["if" "elseif" "while"] . (_) @match.next)
  (#is? test.lastTextOnRow)
  (#is-not? test.startsOnSameRowAs endPosition)
  (#set! indent.match previousSibling.startPosition)
  (#set! indent.offset 1))


; A CLOSING BRACKET AFTER OTHER TEXT
; ==================================

; w = h(a,
;     b)          <- the bracket closes something opened on an earlier row, so
; next = 1           the next line goes back to that row's indent.
(
  [")" "]" "}"] @match.next
  (#is-not? test.firstTextOnRow)
  (#is-not? test.startsOnSameRowAs parent.startPosition)
  (#set! indent.match parent.startPosition)
)


; CONTINUATION LINES
; ==================

; An expression that continues onto the next line without brackets is indented
; one level from its first line, and the line after it goes back:
;
; total = a +
;     b +
;     c
; export alpha,
;     beta
; x = cond ?
;     1 :
;     2
; f(x) =
;     x + 1
;
; The first line ends in an operator (or `?`, `:`, `,`, `=`) that belongs to an
; expression starting on that line. Operators on later lines belong to an
; expression that started earlier, so they add nothing.
(binary_expression
  (operator) @indent
  (#is? test.lastTextOnRow)
  (#is? test.startsOnSameRowAs parent.startPosition))
(ternary_expression
  ["?" ":"] @indent
  (#is? test.lastTextOnRow)
  (#is? test.startsOnSameRowAs parent.startPosition))
(export_statement
  "," @indent
  (#is? test.lastTextOnRow)
  (#is? test.startsOnSameRowAs parent.startPosition))
(using_statement
  "," @indent
  (#is? test.lastTextOnRow)
  (#is? test.startsOnSameRowAs parent.startPosition))
(import_statement
  "," @indent
  (#is? test.lastTextOnRow)
  (#is? test.startsOnSameRowAs parent.startPosition))
(assignment
  (operator) @indent
  (#is? test.lastTextOnRow)
  (#is? test.startsOnSameRowAs parent.startPosition))

; While typing, a line ending in `,`, `?`, `:` or an operator has nothing after
; it yet, so that token sits alone in an ERROR node right after the statement it
; continues. Indent when that statement starts on the same row (the first line of
; the continuation), as above.
((ERROR [(operator) "," "?" ":"] @indent)
  (#is? test.lastTextOnRow)
  (#is? test.startsOnSameRowAs parent.previousSibling.startPosition))

; The line holding the expression's last part: the next line returns to the
; indent of the row the expression started on.
((binary_expression (_) @match.next .)
  (#is? test.lastTextOnRow)
  (#is-not? test.startsOnSameRowAs parent.startPosition)
  (#set! indent.match parent.startPosition))
((ternary_expression (_) @match.next .)
  (#is? test.lastTextOnRow)
  (#is-not? test.startsOnSameRowAs parent.startPosition)
  (#set! indent.match parent.startPosition))
((export_statement (_) @match.next .)
  (#is? test.lastTextOnRow)
  (#is-not? test.startsOnSameRowAs parent.startPosition)
  (#set! indent.match parent.startPosition))
((using_statement (_) @match.next .)
  (#is? test.lastTextOnRow)
  (#is-not? test.startsOnSameRowAs parent.startPosition)
  (#set! indent.match parent.startPosition))
((import_statement (_) @match.next .)
  (#is? test.lastTextOnRow)
  (#is-not? test.startsOnSameRowAs parent.startPosition)
  (#set! indent.match parent.startPosition))
((assignment (_) @match.next .)
  (#is? test.lastTextOnRow)
  (#is-not? test.startsOnSameRowAs parent.startPosition)
  (#set! indent.match parent.startPosition))


; OPENERS
; =======

[
  "function"
  "macro"
  "struct"
  "begin"
  "quote"
  "let"
  "if"
  "elseif"
  "else"
  "for"
  "while"
  "try"
  "catch"
  "finally"
  "do"
  "("
  "["
  "{"
] @indent


; Julia allows `begin` as a name (`a[begin]`), so a `begin` whose `end` has not
; been typed yet is parsed as an identifier. At the end of a line it can only be
; opening a block.
(
  (identifier) @indent
  (#eq? @indent "begin")
  (#is? test.lastTextOnRow)
)


; CLOSERS
; =======

; `end` in `a[end]` is an identifier, not this keyword, so indexing is safe.
[
  "end"
  "elseif"
  "else"
  "catch"
  "finally"
  ")"
  "]"
  "}"
] @dedent
