using Spells
using SPIRV
using Test

spirv_file(filename) = joinpath(@__DIR__, "resources", filename * ".spv")

@testset "Spells.jl" begin
    ir = IR(SPIRV.Module(spirv_file("unicolor.vert")))
    @test validate(ir)
end
