# SYNTAX TEST "source.julia"
# Assertions refer to the last line above them that is not an assertion:
# `# <- scope` checks the column of the `#`, `#  ^ scope` the column of the `^`,
# and `!scope` means that scope must NOT be there.

module Geometry
# <- storage.type.module.julia
#      ^ entity.name.type.module.julia

using LinearAlgebra, Base.Iterators
# <- keyword.control.import.julia
#     ^ support.other.namespace.julia
#                  ^ punctuation.separator.comma.julia
#                    ^ support.other.namespace.julia
import Base: show, +
# <- keyword.control.import.julia
#      ^ support.other.namespace.julia
#          ^ punctuation.separator.colon.julia
#            ^ !support.other.namespace.julia
using Base.Iterators: take as tk
#                          ^ keyword.control.as.julia
export area, Shape
# <- keyword.control.export.julia

"""
    area(s)

The area of `s`. (Docstrings are checked in docstrings-spec.js: an assertion
comment here would separate the docstring from the function.)
"""
function area(s::Square{T}, scale = 1; digits::Int = 2, rest...)::Float64 where {T<:Real}
# <- storage.type.function.julia
#        ^ entity.name.function.julia
#             ^ variable.parameter.function.julia
#              ^ keyword.operator.type.annotation.julia
#                ^ support.other.type.julia
#                       ^ support.other.type.julia
#                           ^ variable.parameter.function.julia
#                                 ^ keyword.operator.assignment.julia
#                                    ^ punctuation.separator.semicolon.julia
#                                      ^ variable.parameter.function.julia
#                                              ^ support.type.builtin.julia
#                                                         ^ variable.parameter.function.julia
#                                                             ^ keyword.operator.splat.julia
#                                                                    ^ support.type.builtin.julia
#                                                                            ^ keyword.other.where.julia
#                                                                                 ^ keyword.operator.relation.types.julia
    a = s.side^2 * scale
#     ^ keyword.operator.assignment.julia
#        ^ keyword.operator.accessor.julia
#             ^ keyword.operator.arithmetic.julia
#              ^ constant.numeric.integer.decimal.julia
    return round(a; digits)
#   ^ keyword.control.flow.return.julia
#          ^ support.other.function.julia
#          ^ !entity.name.function.julia
end
# <- keyword.control.end.julia

function Base.show(io::IO, s::Square)
#        ^ !entity.name.function.julia
#             ^ entity.name.function.julia
    print(io, "Square($(s.side), $s)\n")
#   ^ support.other.function.julia
#             ^ string.quoted.double.julia
#             ^ punctuation.definition.string.begin.julia
#                     ^ meta.embedded.line.interpolation.julia
#                     ^ punctuation.section.embedded.begin.julia
#                      ^ punctuation.section.embedded.begin.julia
#                             ^ punctuation.section.embedded.end.julia
#                                ^ punctuation.section.embedded.begin.julia
#                                 ^ variable.other.interpolation.julia
#                                  ^ !meta.embedded.line.interpolation.julia
#                                   ^ constant.character.escape.julia
#                                     ^ punctuation.definition.string.end.julia
end

perimeter(s::Square) = 4s.side
# <- entity.name.function.julia
#         ^ variable.parameter.function.julia
#            ^ support.other.type.julia
scaled(s, k)::Square where {T} = Square(s.side * k)
# <- entity.name.function.julia
#      ^ variable.parameter.function.julia
#                                ^ support.other.type.julia
#                                ^ !entity.name.function.julia

abstract type Shape end
# <- storage.modifier.abstract.julia
#        ^ storage.type.type.julia
#             ^ entity.name.type.julia
#                   ^ keyword.control.end.julia
mutable struct Square{T<:Real} <: Shape
# <- storage.modifier.mutable.julia
#       ^ storage.type.struct.julia
#              ^ entity.name.type.julia
#                     ^ support.other.type.julia
#                        ^ support.type.builtin.julia
#                                 ^ entity.other.inherited-class.julia
    side::T
#         ^ support.other.type.julia
end
primitive type Flags8 8 end
# <- storage.modifier.primitive.julia
#              ^ entity.name.type.julia

macro twice(ex)
# <- storage.type.macro.julia
#     ^ entity.name.function.macro.julia
#           ^ variable.parameter.function.julia
    quote
#   ^ keyword.control.quote.julia
        $(esc(ex)); $(esc(ex))
#       ^ keyword.operator.interpolation.julia
    end
end
@twice println("hi")
# <- support.function.macro.julia
#      ^ support.other.function.julia
Base.@kwdef struct Opts end
#    ^ support.function.macro.julia

const LIMIT = 0x1f + 0b101 + 0o17 + 1_000 + 1.5e-3 + 2.0f0
# <- storage.modifier.const.julia
#             ^ constant.numeric.integer.hexadecimal.julia
#                    ^ constant.numeric.integer.binary.julia
#                            ^ constant.numeric.integer.octal.julia
#                                   ^ constant.numeric.integer.decimal.julia
#                                           ^ constant.numeric.float.julia
x = (true, nothing, missing, Inf, NaN32, π, stdout)
#    ^ constant.language.boolean.julia
#          ^ constant.language.julia
#                   ^ constant.language.julia
#                            ^ constant.numeric.float.julia
#                                 ^ constant.numeric.float.julia
#                                        ^ support.constant.julia
#                                           ^ support.constant.julia
c = 'x'; sym = :name; op = :+
#   ^ string.quoted.single.julia
#              ^ punctuation.definition.symbol.julia
#               ^ constant.other.symbol.julia
#                           ^ constant.other.symbol.julia
re = r"^a+b$"i
#    ^ storage.type.string.julia
#    ^ string.regexp.julia
#     ^ punctuation.definition.string.begin.julia
#       ^ string.regexp.julia
#           ^ punctuation.definition.string.end.julia
#            ^ keyword.other.option-toggle.regexp.julia
path = raw"C:\temp"
#      ^ storage.type.string.julia
#         ^ string.quoted.other.julia
cmd = `ls -l $dir`
#     ^ string.interpolated.backtick.julia
#     ^ punctuation.definition.string.begin.julia
#            ^ punctuation.section.embedded.begin.julia
#                ^ punctuation.definition.string.end.julia
text = """
#      ^ string.quoted.triple.double.julia
#      ^ punctuation.definition.string.begin.julia
    triple
    """
#   ^ punctuation.definition.string.end.julia
#     ^ punctuation.definition.string.end.julia

v = [i^2 for i in 1:10 if isodd(i)]
#        ^ keyword.control.loop.for.julia
#              ^ keyword.operator.relation.in.julia
#                  ^ keyword.operator.range.julia
#                      ^ keyword.control.conditional.if.julia
w = v[begin:end-1]'
#     ^ variable.language.julia
#           ^ variable.language.julia
#                 ^ keyword.operator.transpose.julia
y = x isa Tuple ? x .+ 1 : x => 2
#     ^ keyword.operator.isa.julia
#         ^ support.type.builtin.julia
#               ^ keyword.operator.ternary.julia
#                   ^ keyword.operator.arithmetic.julia
#                        ^ keyword.operator.ternary.julia
#                            ^ keyword.operator.pair.julia
z = x |> f ∘ g
#     ^ keyword.operator.applies.julia
#          ^ keyword.operator.compose.julia
ok = a == b && !c || d <: e
#      ^ keyword.operator.comparison.julia
#           ^ keyword.operator.logical.julia
#              ^ keyword.operator.logical.julia
#                 ^ keyword.operator.logical.julia
#                      ^ keyword.operator.relation.types.julia
n += 1
# ^ keyword.operator.assignment.compound.julia
d = Dict(:a => 1)
#   ^ support.type.builtin.julia
s = Square(2)
#   ^ support.other.type.julia
#   ^ !support.other.function.julia
t = sqrt.(v)
#   ^ support.other.function.julia
#       ^ keyword.operator.broadcast.julia
throw(ArgumentError("bad"))
# <- support.function.builtin.julia
#     ^ support.type.exception.julia

if x > 0
# <- keyword.control.conditional.if.julia
elseif x < 0
# <- keyword.control.conditional.elseif.julia
else
# <- keyword.control.conditional.else.julia
end
for i in 1:3
# <- keyword.control.loop.for.julia
    i == 2 && continue
#             ^ keyword.control.flow.continue.julia
    i == 3 && break
#             ^ keyword.control.flow.break.julia
end
while false end
# <- keyword.control.loop.while.julia
try
# <- keyword.control.exception.try.julia
catch err
# <- keyword.control.exception.catch.julia
finally
# <- keyword.control.exception.finally.julia
end
map(v) do a, b
#      ^ keyword.control.do.julia
#         ^ variable.parameter.function.julia
#            ^ variable.parameter.function.julia
    a
end
f = (a, b) -> a + b
#    ^ variable.parameter.function.julia
#       ^ variable.parameter.function.julia
#          ^ keyword.operator.arrow.julia
let k = 1
# <- keyword.control.let.julia
end
x = begin
#   ^ keyword.control.begin.julia
end
global g = 1; local l = 2
# <- storage.modifier.global.julia
#             ^ storage.modifier.local.julia

#= a block
   comment =#
# <- comment.block.number-sign-equals.julia
#          ^ punctuation.definition.comment.end.julia
# a line comment
# <- punctuation.definition.comment.julia
#  ^ comment.line.number-sign.julia

end # module
# <- keyword.control.end.julia
