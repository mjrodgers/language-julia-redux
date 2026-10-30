function process(data)
    results = map(data) do item
        if item > 0
            return [
                item,
                item^2,
            ]
        else
            return Int[]
        end
    end
    filter!(results) do r
        !isempty(r)
    end
    return results
end

total = sum(
    x^2 for x in 1:10 if iseven(x)
)

nt = (
    a = 1,
    b = (
        c = 2,
        d = 3,
    ),
)
