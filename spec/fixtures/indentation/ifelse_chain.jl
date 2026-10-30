if a
    1
elseif b
    2
elseif c
    3
else
    4
end

x = if a
    1
else
    2
end

y = let
    z = 3
    z + 1
end

function outer()
    function inner()
        return 1
    end
    return inner()
end
