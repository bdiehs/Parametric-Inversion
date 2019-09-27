module ParametricInversion

export invert_prog, compile_prog

include("Primitives.jl")

struct FuncExpr
	vars::Tuple
	func
	args::Tuple
end

struct Program
	exprs::Array{FuncExpr}
	input_vars::Array{Symbol}
	output_vars::Array{Symbol}
end

compile(expr::FuncExpr) = Expr(
	:(=),
	Expr(:tuple, expr.vars...),
	Expr(:call, expr.func, expr.args...)
)

get_many(bindings, vars) = tuple([bindings[var] for var in vars]...)
function set_many(bindings, vars, vals)
	for i in 1:length(vars)
		bindings[vars[i]] = vals[i]
	end
end


compile_prog(program::Program) = function(input_vals)
	for i in 1:length(program.input_vars)
		eval(:($(program.input_vars[i]) = $(input_vals[i])))
	end
	for expr in program.exprs
		eval(compile(expr))
	end
end


function invert_and_assign_exp(bindings, expr::FuncExpr, th)
	contr_vals = contract(expr.func, get_many(bindings, expr.vars))
	set_many(bindings, expr.vars, contr_vals)
	arg_vals = invert(expr.func)(contr_vals, th)
	set_many(bindings, expr.args, arg_vals)
end

invert_prog(program::Program) = function(output_vals, params)
	bindings = Dict{Symbol, Number}()
	set_many(bindings, program.output_vars, output_vals)
	for i in length(program.exprs):-1:1
		invert_and_assign_exp(bindings, program.exprs[i], params[i])
	end
	return [bindings[input_var] for input_var in program.input_vars]
end

end