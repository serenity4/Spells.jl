function emit(ctx, op)
end

function parse_function(ctx::Context, ex)
end

function emit_struct(ctx, name, fields)
    for field in fields
        if !is_builtin(field)
            emit_type(ctx, field)
        end
    end
end

function emit_field(ctx, field)
    name, type = @match field begin
        :($name::$type) => (name, type)
        _ => error("Expected struct member declaration of the form `member::type`")
    end
    ssa = new_ssavalue!(ctx)
    insert!(ctx.types, ssa, type)
end

function emit(ctx, block, expr::Call)
    result_id = new_ssavalue!(ctx)
    argtypes = types.(ctx, expr.args)
    id = function_id(ctx, expr.op, argtypes)
    rtype = get_rtype(ctx, func, argtypes)
    type_id = get_type_id(ctx, rtype)
    push!(block.insts, Instruction(SPIRV.OpFunctionCall, type_id, result_id, expr.args))
end

function emit(ctx, func::Func)
    fctx = FunctionContext(ctx)
    id = new_ssavalue!(ctx)
    insert!(ctx.sigs, func.sig, id)
    arg_ids = get_type_id.(ctx, func.sig.argtypes)

    exs = body(func)
    for (i, ex) in enumerate(exs)
        ret = emit(fctx, ex)
    end
    insert!(ctx.ir.fdefs, id, SPIRV.FunctionDefinition(id, SPIRV.FunctionControlNone, arg_ids, cfg))
end

function emit(fctx::FunctionContext, ex::If)
    cond_id = new_ssavalue!(fctx)
    emit(fctx, ex.cond)

    # declare merge block
    (; blk, cfg) = fctx
    blk_merge = new_block!(fctx)

    # if true
    blk_true = new_block!(fctx)
    for subex in ex.when_true
        emit(fctx, subex)
    end
    add_edge!(cfg, blk, blk_true)
    add_edge!(cfg, blk_true, blk_merge)

    # else
    blk_false = new_block!(fctx)
    for subex in ex.when_false
        emit(fctx, subex)
    end
    add_edge!(cfg, blk, blk_false)
    add_edge!(cfg, blk_false, blk_merge)

    # finish original block
    current_block!(fctx, blk)
    emit(fctx, @inst SPIRV.OpSelectionMerge(SPIRV.SelectionControlNone))
    emit(fctx, @inst SPIRV.OpBranchConditional(cond_id, blk_true.id, blk_false.id))

    # start merge block
    current_block!(fctx, blk_merge)
end

function emit(fctx::FunctionContext, ex::Loop)
    (; blk, cfg) = fctx
    # declare loop blocks
    blk_header = new_block!(fctx)
    blk_body = new_block!(fctx)
    blk_merge = new_block!(fctx)
    blk_continue = new_block!(fctx)
    blk_cond = new_block!(fctx)

    # finish previous block
    current_block!(fctx, blk)
    emit(fctx, @inst OpBranch(blk_header.id))
    add_edge!(cfg, blk, blk_header)

    # emit loop header
    current_block!(fctx, blk_header)
    emit(fctx, @inst SPIRV.OpLoopMerge(blk_merge.id, blk_continue.id, SPIRV.LoopControlNone))
    emit(fctx, @inst SPIRV.OpBranch(blk_cond.id))
    add_edge!(cfg, blk_header, blk_cond)

    # emit loop condition (head-controlled loop)
    current_block!(fctx, blk_cond)
    cond_id = emit(fctx, ex.cond)
    emit(fctx, @inst SPIRV.OpBranchConditional(cond_id, blk_merge.id, blk_body.id))
    add_edge!(cfg, blk_cond, blk_merge)
    add_edge!(cfg, blk_cond, blk_body)

    # emit loop body
    current_block!(fctx, blk_body)
    for subex in ex.body
        emit(fctx, subex)
    end
    emit(fctx, @inst SPIRV.OpBranch(blk_continue.id))
    add_edge!(cfg, blk_body, blk_continue)

    # emit loop continue target
    current_block!(fctx, blk_continue)
    for subex in ex.continue_target
        emit(fctx, subex)
    end
    add_edge!(cfg, blk_continue, blk_header)

    # start merge block
    current_block!(fctx, blk_merge)
end

function function_id(ctx, op, argtypes)
    sig = Signature(op, argtypes)
    haskey(ctx.sigs, sig) || error("No method matching $op($(join("::" .* string.(argtypes), ", ")))")
    ctx.sigs[sig]
end
