function f(x)
    if x > 0
        return 1
    elseif x < 0
        return -1
    else
        return 0
    end
end

for i in 1:10
    println(i)
end

while true
    break
end

let a = 1, b = 2
    a + b
end

begin
    x = 1
end

quote
    x + 1
end

try
    risky()
catch err
    @warn "failed" err
finally
    cleanup()
end

macro m(ex)
    return esc(ex)
end

struct Point
    x::Float64
    y::Float64
end

mutable struct Counter
    n::Int
end

abstract type Shape end

primitive type Byte 8 end
