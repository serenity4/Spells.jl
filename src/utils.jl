macro forward(ex, fs)
    T, prop = @match ex begin
        :($T.$prop) => (T, prop)
        _ => error("Invalid expression $ex, expected <Type>.<prop>")
    end

    fs = @match fs begin
        :(($(fs...),)) => fs
        _ => error("Expected a tuple of functions, got $fs")
    end

    defs = map(fs) do f
        esc(:($f(x::$T, args...; kwargs...) = $f(x.$prop, args...; kwargs...)))
    end

    Expr(:block, defs...)
end
