using ParametricInversion
const PI = ParametricInversion
using Test

# y = x^2
function test1()
	prog1 = PI.Program(
	[PI.FuncExpr((:y,), PI.square, (:x,))],
	[:x],
	[:y]
	)
	inv_prog1 = PI.invert_prog(prog1)
	fwd_julia = PI.compile(prog1, :fwd_prog1)
	inv_julia = PI.compile(inv_prog1, :inv_prog1)
	inp = rand()
	out, = eval(fwd_julia)(inp)
	inv_out, = eval(inv_julia)(out, 1)
	@test out == fwd_julia(inv_out)[1]
end


# #= 
# z = xy + x
# -------------
# t2, t3 = dupl(2)(x)
# t4, = dupl(1)(y)
# t1 = t3 * t4
# z = t1 + t2
# =#
# exprs = [
# 	PI.FuncExpr((:t2, :t3), PI.dupl2, (:x,)),
# 	PI.FuncExpr((:t4,), PI.dupl1, (:y,)),
# 	PI.FuncExpr((:t1,), PI.mult, (:t3, :t4)),
# 	PI.FuncExpr((:z,), PI.plus, (:t1, :t2))
# ]
# prog2 = PI.Program(
# 	exprs,
# 	[:x, :y],
# 	[:z]
# )
# x, y = PI.invert_prog(prog2, [8], [0, 0, [3, 0], 1])
# PI.run_prog(prog2, [x, y])
# println(PI.z)

# # y = (x^2)^2
# exprs = [
# 	PI.FuncExpr((:t1,), PI.square, (:x,))
# 	PI.FuncExpr((:y,), PI.square, (:t1,))
# ]
# prog3 = PI.Program(
# 	exprs,
# 	[:x],
# 	[:y]
# )
# x, = PI.invert_prog(prog3, [16], [-1, -1])
# PI.run_prog(prog3, [x])
# println(PI.y)
# #=
# z = x^2 + 2xy + y^2
# -------------
# t3, t6 = dupl2(x)
# t7, t9 = dupl2(y)
# t8 = square(t9) # y^2 1
# t5 = twice(t6) # 2x 4
# t4 = prod(t5, t7) # 2xy 4
# t2 = square(t3) # x^2 4
# t1 = sum(t2, t4) # x^2+2xy 8
# z = t1 + t8 # x^2+2xy+y^2 9
# =#
# exprs = [
# 	PI.FuncExpr((:t3, :t6), PI.dupl2, (:x,))
# 	PI.FuncExpr((:t7, :t9), PI.dupl2, (:y,))
# 	PI.FuncExpr((:t8,), PI.square, (:t9,))
# 	PI.FuncExpr((:t5,), PI.twice, (:t6,))
# 	PI.FuncExpr((:t4,), PI.mult, (:t5, :t7))
# 	PI.FuncExpr((:t2,), PI.square, (:t3,))
# 	PI.FuncExpr((:t1,), PI.plus, (:t2, :t4))
# 	PI.FuncExpr((:z,), PI.plus, (:t1, :t8))
# ]
# prog4 = PI.Program(
# 	exprs,
# 	[:x, :y],
# 	[:z]
# )
# x, y = PI.invert_prog(prog4, [9], [0, 0, 1, 0, [1, 0], 1, 4, 1])
# PI.run_prog(prog4, [x, y])
# println(PI.z)

