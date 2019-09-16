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
known_inversions[proj1] = proj1_inv
known_inversions[prod] = prod_inv
known_inversions[twice] = twice_inv

#=
program is a list of lines, each line is a list of the following 
- [type, var, f, var1, var2(opt)]
- [2, var, const] for var = const
type = 0 -> var = f var1 var2
type = 1 -> var = f var1
type = 2 -> var = const
input_var_names is a list of input var names, same for output
=# 
function invert_prog(program, input_var_names, output_var_names)
	function inv_fun(output_vals, params)
		bindings = Dict()
		for i in 1:length(output_vals)
			bindings[output_var_names[i]] = [output_vals[i]]
		end
		for line_num in length(program):-1:1
			println(line_num)
			line = program[line_num]
			println(line)
			println(bindings)
			out_var_name = line[2]
			out_var_val = nothing
			if line[1] == 2
				if out_var_name in keys(bindings)
					push!(bindings[out_var_name], line[3])
				else
					bindings[out_var_name] = [line[3]]
				end
			end
			if out_var_name in keys(bindings)
				for b in bindings[out_var_name]
					if b != bindings[out_var_name][1]
						error("Not total")
					end
				end
				out_var_val = bindings[out_var_name][1]
				pop!(bindings, out_var_name)
			end
			if line[1] == 0
				var1, var2 = invert(line[3])(out_var_val, params[line_num])
				if line[4] in keys(bindings)
					push!(bindings[line[4]], var1)
				else
					bindings[line[4]] = [var1]
				end
				if line[5] in keys(bindings)
					push!(bindings[line[5]], var2)
				else
					bindings[line[5]] = [var2]
				end
			elseif line[1] == 1
				var1 = invert(line[3])(out_var_val, params[line_num])
				if line[4] in keys(bindings)
					push!(bindings[line[4]], var1)
				else
					bindings[line[4]] = [var1]
				end
			end
		end
		input_result = []
		for input_var_name in input_var_names
			if input_var_name in keys(bindings)
				for b in bindings[input_var_name]
					if b != bindings[input_var_name][1]
						error("Not total")
					end
				end
				push!(input_result, bindings[input_var_name][1])
			end
		end
		return input_result
	end
	return inv_fun
end

function run_prog(program, input_var_names, output_var_names, input_vals)
	bindings = Dict()
	for i in 1:length(input_vals)
		bindings[input_var_names[i]] = input_vals[i]
	end
	for line in program
		if line[1] == 0
			bindings[line[2]] = line[3](bindings[line[4]], bindings[line[5]])
		else
			bindings[line[2]] = line[3](bindings[line[4]])
		end
	end
	return [bindings[out_var] for out_var in output_var_names]
end
#=
z = x^2 + 2xy + y^2
->
t6 = square(y) # y^2
t5 = 2
t4 = prod(t5, x) # 2x
t3 = prod(t4, y) # 2xy
t2 = square(x) # x^2
t1 = sum(t2, t3) # x^2+2xy
z = t1 + t6 # x^2+2xy+y^2
->
t1 = x + y
z = t1^2
=#
prog1 = [
	[1, "t6", square, "y"],
	[2, "t5", 2],
	[0, "t4", prod, "t5", "x"],
	[0, "t3", prod, "t4", "y"],
	[1, "t2", square, "x"],
	[0, "t1", plus, "t2", "t3"],
	[0, "z", plus, "t1", "t6"]
]
prog2 = [
	[0, "t1", plus, "x", "y"],
	[1, "z", square, "t1"]
]
prog1_inv = invert_prog(prog1, ["x", "y"], ["z"])
prog2_inv = invert_prog(prog2, ["x", "y"], ["z"])



