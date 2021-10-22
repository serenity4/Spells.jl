struct Variable{T}
    type::T
end

struct Call
    op
    args::Vector{Any}
end

function Call(ex::Expr)
    @match ex begin
        :($f($(args...))) => Call(f, args)
        _ => error("Expected an expression of the form `f(args...)`, got $ex")
    end
end

macro call(ex)
    :(Call($ex))
end

struct Assign
    var::Variable
    expr::Call
end

@auto_hash_equals struct Signature
    name::Symbol
    argtypes::Vector{ID}
end

struct Func
    sig::Signature
    body::Vector{Any}
end

mutable struct Context
    ir::IR
    ssacounter::ID
    "Mapping from signatures (function + argument types) to function types."
    sigs::Dictionary{Signature,ID}
    variables::Dictionary{Variable,ID}
end

Context() = Context(IR(), )

Base.broadcastable(ctx::Context) = Ref(ctx)

function new_ssavalue!(ctx::Context)
    ctx.ssacounter += 1
end

function require_function(ctx::Context, op)
    op in ctx.ir.fdefs
end

SPIRV.Block(ctx::Context) = SPIRV.Block(new_ssavalue!(ctx), [])

mutable struct FunctionContext
    ctx::Context
    variables::Dictionary{Variable,ID}
    cfg::SPIRV.ControlFlowGraph
    blk::SPIRV.Block
end

function FunctionContext(ctx)
    cfg = SPIRV.ControlFlowGraph()
    blk = SPIRV.Block(ctx)
    push!(cfg.blocks, blk)
    FunctionContext(ctx, Dictionary(), cfg, blk)
end

emit(fctx::FunctionContext, inst::Instruction) = push!(fctx.blk.insts, inst)

function new_block!(fctx::FunctionContext)
    fctx.blk = SPIRV.Block(fctx)
    emit(fctx, @inst fctx.blk.id = OpLabel())
    fctx.blk
end

function current_block!(fctx::FunctionContext, blk::SPIRV.Block)
    fctx.blk = blk
end

@forward FunctionContext.ctx new_ssavalue!, require_function, SPIRV.Block

abstract type TypeSpec end

struct PrimitiveType <: TypeSpec
    name::Symbol
end

struct CompositeType <: TypeSpec
    name::Symbol
    fields::Dictionary{Symbol,TypeSpec}
end

struct If
    cond # expression
    when_true::Vector{Any}
    when_false::Vector{Any}
end

struct Loop
    cond
    body
    continue_target
end
