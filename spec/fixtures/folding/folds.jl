"""
Docstring
"""
function f(x)
    if x > 0
        1
    elseif x < 0
        -1
    else
        0
    end
end

function g(
        a,
        b,
    )
    try
        a
    catch e
        b
    finally
        nothing
    end
end

v = [
    1,
    2,
]
d = Dict(
    :a => 1,
)
#=
block comment
=#
s = """
    triple
    """
struct S
    a::Int
end
for i in 1:2
    i
end
x = begin
    1
end
let y = 1
    y
end
map(1:2) do i
    i
end
if a
    1
end
quote
    x
end
macro m(e)
    e
end
module M
z = 1
end
abstract type T end
function h(x)
    if x
        if y
            1
        end
    elseif z
        2
    end
    try
        f()
    catch
        g()
    end
end
export a,
    b
@testset "t" begin
    @test true
end
m = [1 2
     3 4]
