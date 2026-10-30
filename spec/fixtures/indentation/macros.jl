@testset "outer" begin
    x = 1
    @test x == 1
    @test_throws ErrorException begin
        error("boom")
    end
end

@time begin
    sleep(1)
end

macro twice(ex)
    quote
        $(esc(ex))
        $(esc(ex))
    end
end

expr = :(
    a + b
)
