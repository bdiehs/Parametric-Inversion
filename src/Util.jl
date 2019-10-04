mutable struct ParamSymbolGen
	idx::Int64
end

function generate(param_gen::ParamSymbolGen)
	param_gen.idx = param_gen.idx + 1
	Symbol(string("th", param_gen.idx))
end

param_generator() = ParamSymbolGen(0)