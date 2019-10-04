module ParametricInversion

export invert_prog, compile_prog

include("Primitives.jl")
include("Util.jl")

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
Compiles a program, assigns input values and runs Julia code
"""
function compile(program::Program, input_vals)
	for i in 1:length(program.input_vars)
		eval(:($(program.input_vars[i]) = $(input_vals[i])))
	end
	for expr in program.exprs
		eval(compile(expr))
	end
end

"""
Inverts a functional expression. It uses param_gen to generate new symbols for the new parameters
"""
function invert_exp(param_gen, expr::FuncExpr)
	contraction = Expr(:(=), Expr(:tuple, expr.vars...), Expr(:call, contract(expr.func), expr.vars...))
	inversion = Expr(:(=), Expr(:tuple, expr.args...), Expr(:call, invert(expr.func), (expr.vars..., generate(param_gen))))
end


"""
Inverts a program and returns another program
"""
function invert_prog(program::Program)
	param_gen = param_generator()
	program_inv = Program([], copy(program.output_vars), copy(program.input_vars))
	for i in length(program.exprs):-1:1
		expr = program.exprs[i]
		contraction = FuncExpr(expr.vars, contract(expr.func), expr.vars)
		new_param = generate(param_gen)
		println(new_param)
		push!(program_inv.input_vars, new_param)
		inversion = FuncExpr(expr.args, invert(expr.func), (expr.vars..., new_param))
		push!(program_inv.exprs, contraction, inversion)
	end
	return program_inv
end


end