function last_item(a)
    if a[end] > 0
        return a[end]
    end
    b = a[begin:end]
    for i in eachindex(a)[2:end]
        b[i] = a[i - 1]
    end
    return b
end
