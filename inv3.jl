known_inversions = Dict()

#invert: (X -> Y) -> (Y * (param_type) -> X)
invert(f) = known_inversions[f]

id(x) = x
id_inv(x, th) = x
plus(x1, x2) = x1 + x2
plus_inv(y, th) = (y - th, th)
square(x) = x^2
square_inv(y, th) = th in [-1, 1] ? th * y^0.5 : error("square inverse parameter must be 1 or -1")
#sin(x) = sin(x)
sin_inv(y, th) = typeof(th) == Int ? pi * th + (-1)^th * asin(y) : error("")
minus(x1, x2) = x1 - x2
minus_inv(y, th) = (y + th, th)
dupl(x) = (x, x)
dupl_inv(y) = y[1] == y[2] ? y[1] : error("dupl inverse input must have equal coordinates")
prod(x1, x2) = x1 * x2
function prod_inv(y, th)
	if th[1] == 0
		error("")
	elseif (th[2] != 0) && (th[2] != 1)
		error("")
	else
		return th[2] == 0 ? (y/th[1], th[1]) : (th[1], y/th[1])
	end
end
twice(x) = 2*x
twice_inv(y, th) = y/2
known_inversions[plus] = plus_inv
known_inversions[square] = square_inv
known_inversions[sin] = sin_inv
known_inversions[minus] = minus_inv
known_inversions[dupl] = dupl_inv
known_inversions[prod] = prod_inv
known_inversions[twice] = twice_inv

abstract type Exp end
struct TwoArgExp <: Exp
	var::Symbol
	func
	arg1::Symbol
	arg2::Symbol
end
struct OneArgExp <: Exp
	var::Symbol
	func
	arg1::Symbol
end
struct ConstExp <: Exp
	var::Symbol
	cnst
end

compile(expr::TwoArgExp) = Expr(:(=), expr.var, Expr(:call, expr.func, expr.arg1, expr.arg2))
compile(expr::OneArgExp) = Expr(:(=), expr.var, Expr(:call, expr.func, expr.arg1))
compile(expr::ConstExp) = Expr(:(=), expr.var, expr.cnst)

function invert_and_assign_exp(expr::TwoArgExp, th, bindings)
	curr_val1 = get(bindings, expr.arg1, nothing)
	curr_val2 = get(bindings, expr.arg2, nothing)
	val1, val2 = invert(expr.func)(bindings[expr.var], th)
	if curr_val1 != nothing && curr_val1 != val1
		error("Not total") 
	end
	if curr_val2 != nothing && curr_val2 != val2
		error("Not total") 
	end
	bindings[expr.arg1] = val1
	bindings[expr.arg2] = val2
	if expr.var in keys(bindings)
		pop!(bindings, expr.var)
	end
end

function invert_and_assign_exp(expr::OneArgExp, th, bindings)
	curr_val1 = get(bindings, expr.arg1, nothing)
	val1 = invert(expr.func)(bindings[expr.var], th)
	if curr_val1 != nothing && curr_val1 != val1
		error("Not total")
	end
	bindings[expr.arg1] = val1
	if expr.var in keys(bindings)
		pop!(bindings, expr.var)
	end
end

function invert_and_assign_exp(expr::ConstExp, th, bindings)
	curr_val1 = get(bindings, expr.var, nothing)
	if expr.cnst != curr_val1
		error("Not total")
	end
	bindings[expr.var] = expr.cnst
end

function compile_prog(program, input_vars, output_vars)
	function run_prog(input_vals)
		for i in 1:length(input_vars)
			eval(Expr(:(=), input_vars[i], input_vals[i]))
		end
		for expr in program
			eval(compile(expr))
		end
		output_vals = []
		for output_var in output_vars
			push!(output_vals, eval(output_var))
		end
		return output_vals
	end
end

#=
program = Array{Exp}
input_vars = Array{Symbol}
output_vars = Array{Symbol}
=#
function invert_prog(program, input_vars, output_vars)
	# output_vals = Array{Number}
	function inv_fun(output_vals, params)
		bindings = Dict()
		for i in 1:length(output_vals)
			bindings[output_vars[i]] = output_vals[i]
		end
		for i in length(program):-1:1
			invert_and_assign_exp(program[i], params[i], bindings)
		end
		input_result = []
		for input_var in input_vars
			push!(input_result, bindings[input_var])
		end
		return input_result
	end
	return inv_fun
end

# z = x^2+2xy+y^2
prog1 = [
	OneArgExp(:t6, square, :y),
	ConstExp(:t5, :2),
	TwoArgExp(:t4, prod, :t5, :x),
	TwoArgExp(:t3, prod, :t4, :y),
	OneArgExp(:t2, square, :x),
	TwoArgExp(:t1, plus, :t2, :t3),
	TwoArgExp(:z, plus, :t1, :t6)
]
in1 = [:x, :y]
out1 = [:z]
prog1_inv = invert_prog(prog1, in1, out1)
x, y = prog1_inv([9], [1,nothing,[2,0],[1,0],1,4,1])
println(compile_prog(prog1, in1, out1)([x, y]))

# z = (x+y)^2
prog2 = [
	TwoArgExp(:t1, plus, :x, :y),
	OneArgExp(:z, square, :t1)
]
in2 = [:x, :y]
out2 = [:z]
prog2_inv = invert_prog(prog2, in2, out2)
x, y = prog2_inv([9], [1, 1])
println(compile_prog(prog2, in2, out2)([x, y]))

# z = xy+x
prog3 = [
	TwoArgExp(:t1, prod, :x, :y),
	TwoArgExp(:z, plus, :t1, :x)
]
in3 = [:x, :y]
out3 = [:z]
prog3_inv = invert_prog(prog3, in3, out3)
x, y = prog3_inv([8], [[3, 0], 2])
println(compile_prog(prog3, in3, out3)([x, y]))

# y = x^2
prog4 = [
	OneArgExp(:y, square, :x)
]
in4 = [:x]
out4 = [:y]
prog4_inv = invert_prog(prog4, in4, out4)
x, = prog4_inv([4], [-1])
println(compile_prog(prog4, in4, out4)([x]))

# w = x + y + z + xyz
prog5 = [
	TwoArgExp(:t4, prod, :x, :y),
	TwoArgExp(:t3, prod, :t4, :z),
	TwoArgExp(:t2, plus, :x, :y),
	TwoArgExp(:t1, plus, :t2, :z),
	TwoArgExp(:w, plus, :t1, :t3)
]
in5 = [:x, :y, :z]
out5 = [:w]
prog5_inv = invert_prog(prog5, in5, out5)
x, y, z = prog5_inv([12], [[2, 0], [3, 0], 2, 3, 6])
println(compile_prog(prog5, in5, out5)([x, y, z]))


