; Symbols for Pulsar's symbols-view (Go to Symbol), via symbol-provider-tree-sitter.
; See that package's README for the `symbol.*` settings.
;
; A function's symbol is its (possibly qualified) name, with the argument list
; as its context, so that the methods of a function can be told apart.

; function f(x) / function f(x)::T / function f(x) where T / function Base.f(x)
(function_definition
  (signature
    [(call_expression
       . [(identifier) (field_expression)] @name)
     (typed_expression
       . (call_expression
         . [(identifier) (field_expression)] @name))
     (where_expression
       . [(call_expression
           . [(identifier) (field_expression)] @name)
          (typed_expression
            . (call_expression
              . [(identifier) (field_expression)] @name))])])
  (#set! symbol.contextNode "nextSibling")) @definition.function

; Short form: f(x) = ...
(assignment
  . [(call_expression
      . [(identifier) (field_expression)] @name)
     (typed_expression
       . (call_expression
         . [(identifier) (field_expression)] @name))
     (where_expression
       . [(call_expression
           . [(identifier) (field_expression)] @name)
          (typed_expression
            . (call_expression
              . [(identifier) (field_expression)] @name))])]
  (operator)
  (#set! symbol.contextNode "nextSibling")) @definition.function

; function f end
(function_definition
  (signature . (identifier) @name .)) @definition.function

(macro_definition
  (signature
    (call_expression . (identifier) @name))
  (#set! symbol.prepend "@")
  (#set! symbol.contextNode "nextSibling")) @definition.macro

(module_definition
  name: (identifier) @name) @definition.module

(struct_definition
  (type_head
    [(identifier) @name
     (parametrized_type_expression . (identifier) @name)
     (binary_expression
       . [(identifier) @name
          (parametrized_type_expression . (identifier) @name)])])) @definition.struct

(abstract_definition
  (type_head
    [(identifier) @name
     (parametrized_type_expression . (identifier) @name)
     (binary_expression
       . [(identifier) @name
          (parametrized_type_expression . (identifier) @name)])])
  (#set! symbol.tag "abstract")) @definition.interface

(primitive_definition
  (type_head
    [(identifier) @name
     (binary_expression . (identifier) @name)])
  (#set! symbol.tag "primitive")) @definition.struct

(const_statement
  (assignment . (identifier) @name)) @definition.constant
