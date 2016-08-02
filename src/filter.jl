macro filter(input::Symbol, _args::Expr...)
    args = collect(_args)
    filter_helper_ex = _build_helper_ex(FilterNode, args)
    #= we need to generate the filtering kernel's definition at macroexpand-time
    so the definition can be spliced into the proper (i.e., original caller's) scope =#
    return quote
        g = FilterNode(DataNode($(esc(input))), $args, $filter_helper_ex)
        _collect(g)
    end
end

# for case in which data source is piped to @filter call
macro filter(_args::Expr...)
    args = collect(_args)
    filter_helper_ex = _build_filter_helper(args)
    return quote
        # $f = $fdef
        # helper = FilterHelper($f, $fields)
        g = FilterNode(DataNode(), $args, $filter_helper_ex)
        _collect(CurryNode(), g)
    end
end

function _build_filter_helper(args)
    # kernel_def_ex, fields = resolve_filter(args)
    kernel_ex, flds = _filter_helper_parts(args)
    return quote
        FilterHelper($kernel_ex, $flds)
    end
end

function _filter_helper_parts(args)
    filter_pred = aggr(args)
    kernel_ex, ind2sym = _build_anon_func(filter_pred)
end
