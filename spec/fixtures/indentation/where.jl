function f(x::T) where {T <: Real}
    return x
end

function g(
    a::Int,
    b::Int,
)
    return a + b
end

h(x::T) where {T} = x

function k(x)::Int
    return x
end
