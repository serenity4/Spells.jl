module Spells

using AutoHashEquals
using Dictionaries
using MLStyle
using SPIRV
using SPIRV: ID
using Graphs
import SPIRV_Tools_jll

const Optional{T} = Union{Nothing, T}
const spirv_val = SPIRV_Tools_jll.spirv_val(identity)

include("utils.jl")
include("types.jl")
include("emit.jl")
include("validate.jl")

export
        validate,
        Context,
        Func,
        PrimitiveType,
        CompositeType

end
