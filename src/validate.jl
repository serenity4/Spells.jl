function validate(ir::IR)
    mod = SPIRV.Module(ir)
    input = IOBuffer()
    write(input, mod)
    seekstart(input)
    err = IOBuffer()

    try
        run(pipeline(`$spirv_val -`, stdin=input, stdout=err))
    catch e
        if e isa ProcessFailedException
            err_str = String(take!(err))
            throw(ValidationError(err_str))
        else
            rethrow(e)
        end
    end

    true
end

struct ValidationError <: Exception
    msg::String
end

Base.showerror(io::IO, err::ValidationError) = print(io, "ValidationError:\n\n$(err.msg)")
