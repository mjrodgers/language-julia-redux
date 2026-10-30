map(xs) do x
    x + 1
end

open("file.txt") do io
    write(io, "hello")
end

result = map(1:3) do i
    i^2
end

@testset "math" begin
    @test 1 + 1 == 2
    @testset "nested" begin
        @test true
    end
end

@inbounds for i in 1:n
    a[i] = 0
end

Threads.@threads for i in 1:n
    work(i)
end
