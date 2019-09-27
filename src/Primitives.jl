known_inversions = Dict()
known_contractions = Dict()

#invert: (X -> Y) -> (Y * (param_type) -> X)
invert(f) = known_inversions[f]
contract(f, args) = known_contractions[f](args)

plus(x1, x2) = tuple(x1 + x2)
plus_inv(y, th) = tuple(y[1] - th, th)
plus_contr(y) = y
square(x) = tuple(x[1]^2)
square_inv(y, th) = tuple(th in [-1, 1] ? th * y[1]^0.5 : error("square inverse parameter must be 1 or -1"))
square_contr(y) = tuple(max(0, y[1]))
twice(x) = tuple(2*x[1])
twice_inv(y, th) = tuple(y[1]/2)
twice_contr(y) = y

dupl(n) = function(x)
	tuple([x[1] for i in 1:n]...)
end
dupl_inv(n) = function(arr, th)
	for i in 1:length(arr)
		if arr[i] != arr[1]
			error("dupl inverse failed")
		end
	end
	return tuple(arr[1])
end
dupl_contr(n) = function(arr)
	tuple([arr[1] for i in 1:n]...)
end
dupl1 = dupl(1)
dupl2 = dupl(2)

mult(x1, x2) = tuple(x1 * x2)
function mult_inv(y, th)
	if th[1] == 0
		error("")
	elseif (th[2] != 0) && (th[2] != 1)
		error("")
	else
		return th[2] == 0 ? tuple(y[1]/th[1], th[1]) : tuple(th[1], y[1]/th[1])
	end
end
mult_contr(y) = y

known_inversions[plus] = plus_inv
known_inversions[square] = square_inv
known_inversions[dupl1] = dupl_inv(1)
known_inversions[dupl2] = dupl_inv(2)
known_inversions[mult] = mult_inv
known_inversions[twice] = twice_inv

known_contractions[plus] = plus_contr
known_contractions[square] = square_contr
known_contractions[dupl1] = dupl_contr(1)
known_contractions[dupl2] = dupl_contr(2)
known_contractions[mult] = mult_contr
known_contractions[twice] = twice_contr
