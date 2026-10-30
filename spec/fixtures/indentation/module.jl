module Foo

using LinearAlgebra
export bar

"""
    bar(x)

Docstring.
"""
function bar(x)
    return x
end

const C = 1

end
