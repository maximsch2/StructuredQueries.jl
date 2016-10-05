# TODO: should we inline the following?

if VERSION < v"0.6.0-dev.848"
    unsafe_get(x::Nullable) = x.value
    unsafe_get(x) = x
    Base.isnull(x) = false
end

function lift(f, x)
    U = Core.Inference.return_type(f, Tuple{eltype(typeof(x))})
    if isnull(x)
        return Nullable{U}()
    else
        return Nullable(f(unsafe_get(x)))
    end
end

function lift(f, x1, x2)
    U = Core.Inference.return_type(
        f, Tuple{eltype(typeof(x1)), eltype(typeof(x2))}
    )
    if isnull(x1) | isnull(x2)
        return Nullable{U}()
    else
        return Nullable(f(unsafe_get(x1), unsafe_get(x2)))
    end
end

function lift(f, xs...)
    U = Core.Inference.return_type(
        f, Tuple{map(x->eltype(typeof(x)), xs)...}
    )
    if hasnulls(xs)
        return Nullable{U}()
    else
        return Nullable(f(map(unsafe_get, xs)...))
    end
end

# Three-valued logic (3VL)

function lift(::typeof(&), x, y)::Nullable{Bool}
    return ifelse(
        isnull(x),
        ifelse(
            isnull(y),
            Nullable{Bool}(),
            ifelse(
                unsafe_get(y),
                Nullable{Bool}(),
                Nullable(false)
            )
        ),
        ifelse(
            isnull(y),
            ifelse(
                unsafe_get(x),
                Nullable{Bool}(),
                Nullable(false)
            ),
            Nullable(unsafe_get(x) & unsafe_get(y))
        )
    )
end

function lift(::typeof(|), x, y)::Nullable{Bool}
    return ifelse(
        isnull(x),
        ifelse(
            isnull(y),
            Nullable{Bool}(),
            ifelse(
                unsafe_get(y),
                Nullable(true),
                Nullable{Bool}()
            )
        ),
        ifelse(
            isnull(y),
            ifelse(
                unsafe_get(x),
                Nullable(true),
                Nullable{Bool}()
            ),
            Nullable(unsafe_get(x) | unsafe_get(y))
        )
    )
end
