module ParametricInversion

export invert_prog, compile_prog

include("Primitives.jl")

"""
Data structure for a functional expression that represents
	vars = func(args...)
where func is a primitive function
"""
struct FuncExpr
	vars::Tuple
	func
	args::Tuple
end


"""
Data structure that represents a program that consists of several functional
expressions, takes inputs and returns outputs
"""
struct Program
	exprs::Array{FuncExpr}
	input_vars::Array{Symbol}
	output_vars::Array{Symbol}
end

"""
Converts a functional expression to a Julia Expr type
"""
compile(expr::FuncExpr) = Expr(
	:(=),
	Expr(:tuple, expr.vars...),
	Expr(:call, expr.func, expr.args...)
)

"""
Gets the values of the variables in vars from bindings
"""
get_many(bindings, vars) = tuple([bindings[var] for var in vars]...)

"""
Binds values to variables and stores it in bindings
"""
function set_many(bindings, vars, vals)
	for i in 1:length(vars)
		bindings[vars[i]] = vals[i]
	end
end

"""
Compiles a program, assigns input values and runs Julia code
"""
function run_prog(program::Program, input_vals)
	for i in 1:length(program.input_vars)
		eval(:($(program.input_vars[i]) = $(input_vals[i])))
	end
	for expr in program.exprs
		eval(compile(expr))
	end
end

"""
Inverts a functional expression using bindings and a parameter 
"""
function invert_and_assign_exp(bindings, expr::FuncExpr, th)
	contr_vals = contract(expr.func, get_many(bindings, expr.vars))
	set_many(bindings, expr.vars, contr_vals)
	arg_vals = invert(expr.func)(contr_vals, th)
	set_many(bindings, expr.args, arg_vals)
end

"""
Inverts a program given output values and parameters
"""
function invert_prog(program::Program, output_vals, params)
	bindings = Dict{Symbol, Number}()
	set_many(bindings, program.output_vars, output_vals)
	for i in length(program.exprs):-1:1
		invert_and_assign_exp(bindings, program.exprs[i], params[i])
	end
	return [bindings[input_var] for input_var in program.input_vars]
end

end