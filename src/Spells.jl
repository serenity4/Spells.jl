module Spells

using AutoHashEquals
using Dictionaries
using MLStyle
using SPIRV
using SPIRV: ID
using Graphs

const Optional{T} = Union{Nothing, T}
const magic_number = 0x12349876

include("utils.jl")
include("types.jl")
include("emit/types.jl")
include("emit/cfg_constructs.jl")
include("emit/functions.jl")

export
        Context,
        Func,
        PrimitiveType,
        CompositeType

end
