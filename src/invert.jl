

# zt: use not abstract (i.e. concrete) types for fields
"""
Data structure for a functional expression that represents
	vars = func(args...)
where func is a primitive function
"""
struct FuncExpr
	vars::Tuple
	func::Function
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


"Converts a functional expression to a Julia Expr type"
compile(expr::FuncExpr) = Expr(
	:(=),
	Expr(:tuple, expr.vars...),
	Expr(:call, expr.func, expr.args...)
)

"Compiles `p` into a julia Expr of name `name`"
function compile(p::Program, name::Symbol)
	head = Expr(:call, name, p.input_vars...)
	lines = map(compile, p.exprs)	
	ret = Expr(:tuple, p.output_vars...)
	Expr(:function, head, Expr(:block, lines..., ret))
end

"Compiles `p` into a julia Expr (anonymous function )"
function compile(p::Program)
	head = Expr(:tuple, p.input_vars...)
	lines = map(compile, p.exprs)	
	ret = Expr(:tuple, p.output_vars...)
	Expr(:->, head, Expr(:block, lines..., ret))
end

"""
Inverts a functional expression. It uses param_gen to generate new symbols for the new parameters
"""
function invert_exp(param_gen, expr::FuncExpr)
	contraction = Expr(:(=), Expr(:tuple, expr.vars...), Expr(:call, contract(expr.func), expr.vars...))
	inversion = Expr(:(=), Expr(:tuple, expr.args...), Expr(:call, invert(expr.func), (expr.vars..., generate(param_gen))))
end

"Inverts `program`` and returns another program"
function invert_prog(program::Program)
	param_gen = param_generator()
	program_inv = Program([], copy(program.output_vars), copy(program.input_vars))
	for i in length(program.exprs):-1:1
    expr = program.exprs[i]
    # zt: separate contration into separate pass
		contraction = FuncExpr(expr.vars, contract(expr.func), expr.vars)
		new_param = generate(param_gen)
		println(new_param)
		push!(program_inv.input_vars, new_param)
		inversion = FuncExpr(expr.args, invert(expr.func), (expr.vars..., new_param))
		push!(program_inv.exprs, contraction, inversion)
	end
	program_inv
end