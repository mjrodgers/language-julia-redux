Base.@kwdef mutable struct Options
    verbose::Bool = false
    level::Int = 1
end

@kwdef struct Config
    name::String
end

f = x -> begin
    y = x + 1
    y * 2
end

g = function (x)
    return x
end

try
    work()
catch
    recover()
else
    succeed()
finally
    done()
end

for (i, x) in enumerate(xs)
    global total += x
end

while (a > 0 &&
    b > 0)
    a -= 1
end

export alpha,
    beta,
    gamma

val = cond ?
    1 :
    2

if a &&
    b
    body()
end

ok = a &&
    b &&
    c
next_line = 1

f(
    a,
    b,
) do x
    y
end

f(x) =
    x + 1
after = 2

using A,
    B
import C
