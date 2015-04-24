defmodule Epagoge.GeneticProgramming do
	alias Epagoge.Exp, as: Exp
	alias Epagoge.ILP, as: ILP

	def infer(dataset, target) do
		infer(dataset,target,[{:pop_size,10},{:thres,1.0}])
	end
	def infer(dataset, target, options) do
		names = get_v_names(dataset)
		litrange = get_lit_range(dataset)
		type = get_type(dataset,target)
		:elgar.run(&generator(names,type,litrange,&1),&fitness(dataset,target,type,&1),mutations(names,litrange,type),&crossover(type,&1,&2),options)
	end

	defp get_type([d | _],target) do
		# Since we don't support mixed types this is determined by the first element
		if is_boolean(d[target]) do
			:bool
		else
			:num
		end
	end

	defp get_lit_range(dataset) do
		get_lit_range(dataset,{0,0})
	end
	defp get_lit_range([],range) do
		range
	end
	defp get_lit_range([data | dataset],{min,max}) do
		newrange = List.foldl(Map.keys(data),
															{min,max},
															fn(k,{accmin,accmax}) ->
																	v = data[k]
																	if is_number(v) do
																		{min(v,accmin),max(v,accmax)}
																	else
																		{accmin,accmax}
																	end
															end)
		get_lit_range(dataset,newrange)
	end

	# Fitness
	defp fitness(dataset,target,type,exp) do
		diffs = Enum.map(dataset,
										 fn(data) ->
												 # Generated formulae can have errors (e.g. divide by zero)
												 try do
													 {comp,_newdata} = Exp.eval(exp,data)
													 delta = case type do
																		 :num ->
																			 abs(data[target] - comp)
																		 :bool ->
																			 if data[target] == comp do
																				 0
																			 else
																				 if is_boolean(comp) do
																					 # How big you make this value controls how much it values size vs correctness
																					 5
																				 else
																					 # Not being boolean is really, really wrong
																					 # but its worth generating them because sometimes they will be
																					 # needed in crossover...
																					 10
																				 end
																			 end
																	 end
													 # Erlang/Elixir seems to have slightly random behaviour below some threshold of accuracy...
													 if delta > 0.00000000001 do
														 # Occam's razor...
														 delta + (depth(exp) / length(dataset))
													 else
														 0
													 end
													 rescue
														 _e -> 
														 99999
												 end
										 end
										)
		av = Enum.sum(diffs) / length(diffs)
		1 / (1 + av)
	end

	# A simple measure of "complexity"
	defp depth({_op,l,r}) do
		1 + max(depth(l),depth(r))
	end
	defp depth(_e) do
		1
	end

	# Get the set of variable names that appear in *all* elements of the data set
	defp get_v_names([]) do
		[]
	end
	defp get_v_names([data | set]) do
		get_v_names(set,Map.keys(data))
	end
	defp get_v_names([],names) do
		names
	end
	defp get_v_names([data | more], names) do
		minnames = List.foldl(Map.keys(data),
															[],
															fn(n,acc) ->
																	# We can only compute from inputs and registers
																	nstring = to_string(n)
																	if String.starts_with?(nstring,"r") or String.starts_with?(nstring,"i") do
																		if Enum.any?(names, fn(nn) -> nn == n end) do
																			[n | acc]
																		else
																			acc
																		end
																	else
																		acc
																	end
															end
												 )
		get_v_names(more, minnames)
	end

	# Invent either a variable from the names list or a literal
	# The literal 1 is weighted heavily, partly because simple increment is
	# common, and partly because there are other mutations that will transform
	# the literal later
	defp pick_val(names,{litmin,litmax}) do
		case :random.uniform(2) do
			1 ->
				# Variable...
				{:v,:lists.nth(:random.uniform(length(names)),names)}
			2 ->
				# Literal...
				# Boolean literals are never useful!
				case :random.uniform(4) do
					1 -> {:lit,1}
					_ -> {:lit,:random.uniform(litmax-litmin) + litmin}
				end
		end
	end

	# Pick a random operator
	# Currently this makes no attempt to detrmine type...
	# In fact, currently they are all numeric...
	defp pick_op(type) do
		ops = case type do
						:arith -> [:plus,:minus,:divide,:multiply]
						:comp -> [:gr,:ge,:lt,:le,:eq,:ne]
						:bool -> [:eq,:ne,:conj,:disj]
					end
		:lists.nth(:random.uniform(length(ops)),ops)
	end

  # Crossover

	# Get a random subexpression from an expression
	# For compund expressions this has a 50% chance of returning the whole
	# expression; other expressions are always returned complete.
	defp get_subexp({op,l,r}) do
		case :random.uniform(2) do
			1 ->
				{op,l,r}
			2 ->
				case :random.uniform(2) do
					1 -> get_subexp(l)
					2 -> get_subexp(r)
				end
		end
	end
	defp get_subexp(e) do
		e
	end

	# Generator
	defp generator(names,type,litrange,_seed) do
		v = pick_val(names,litrange)
		case :random.uniform(2) do
			1 -> v
			2 ->
				# Use the add_op mutation because that includes filter code
				# for stupid combinations...
				add_op(names,type,litrange,v)
		end
	end

	# Crossover on complex expressions always replaces one of the branches
	defp crossover(type,{op,l,r},e2) do
		res = case :random.uniform(3) do
			1 -> {op,get_subexp(e2),r}
			2 -> {op,l,get_subexp(e2)}
			3 -> case type do
						 :num -> {pick_op(:arith),l,r}
						 :bool -> case op_type(l) do
												:bool ->
													{pick_op(:bool),l,r}
												:num ->
													case :random.uniform(2) do
														1 -> {pick_op(:comp),l,r}
														2 -> {pick_op(:arith),l,r}
													end
											end
					 end
		end
		ILP.simplify(res)
	end
	defp crossover(type,e1,{op,l,r}) do
		crossover(type,{op,l,r},e1)
	end
	defp crossover(_type,{:lit,v1},{:lit,v2}) do
		# There is nothing sensible to do with expressions over two literals, so lets take the average
		{:lit,(v1 + v2) / 2}
	end
	defp crossover(type,e1,e2) do
		# If we are here then neither is a compound, so lets compound them...
		case type do
			:num ->
				{pick_op(:arith),e1,e2}
			:bool ->
				res = case :random.uniform(2) do
								1 -> {pick_op(:comp),e1,e2}
								2 -> {pick_op(:bool),e1,e2}
							end
				res = ILP.simplify(res)
				if is_sensible?(res) do
					res
				else
					crossover(type,e1,e2)
				end
		end
	end

	defp op_type({op,_,_}) do
		if Enum.any?([:conj,:disj,:gr,:ge,:lt,:le,:eq,:ne],fn(o) -> o == op end) do
			:bool
		else
			:num
		end
	end
	defp op_type(oporvar) do
		if Enum.any?([:conj,:disj,:gr,:ge,:lt,:le,:eq,:ne],fn(o) -> o == oporvar end) do
			:bool
		else
			:num
		end
	end

	# Mutations

	# This function makes a list of mutation operators that use the
	# supplied list of names
	defp mutations(names,litrange,type) do
		[
		 &add_op(names,type,litrange,&1),
		 &rem_op/1,
		 &mod_val(names,litrange,&1),
		 &nudge/1,
		 &split(type,names,litrange,&1),
		 &mod_op(type,&1)
		]
	end

	defp add_op_detail(names,optype,litrange,e) do
							case :random.uniform(2) do
								1 ->
									ILP.simplify({pick_op(optype),e,pick_val(names,litrange)})
								2 ->
									ILP.simplify({pick_op(optype),pick_val(names,litrange),e})
							end
	end
	
	# Add an operator and a random value
	defp add_op(names,type,litrange,e) do
		res = case type do
						:num ->
							add_op_detail(names,:arith,litrange,e)
						:bool ->
							case op_type(e) do
								:bool ->
									add_op_detail(names,:bool,litrange,e)
								:num ->
									add_op_detail(names,:comp,litrange,e)
							end
					end
		if is_sensible?(res) do
			res
		else
			# Try again...
			add_op(names,type,litrange,e)
		end
	end

	defp mod_op(type,{op,l,r}) do
		if not is_sensible?({op,l,r}) do
			# This should not have been created, but going round an endless loop is worse...
			{op,l,r}
		else
			res = case :random.uniform(3) do
							1 -> {op,mod_op(type,l),r}
							2 -> {op,l,mod_op(type,r)}
							3 -> case type do
										 :num ->
										 	 {pick_op(:arith),l,r}
										 :bool ->
											 case op_type({op,l,r}) do
												 :bool ->
													 {pick_op(:bool),l,r}
												 :num ->
													 case :random.uniform(2) do
														 1 -> {pick_op(:arith),l,r}
														 2 -> {pick_op(:comp),l,r}
													 end
											 end
									 end
						end
			res = ILP.simplify(res)
			if is_sensible?(res) and (res != {op,l,r}) do
				res
			else
				mod_op(type,{op,l,r})
			end
		end
	end
	defp mod_op(_type,e) do
		e
	end

	# Remove an operator
	defp rem_op({op,l,r}) do
		case :random.uniform(2) do
			1 -> if is_sensible?(l) do
						 l
					 else
						 if is_sensible?(r) do
							 r
						 else
							 {op,l,r}
						 end
					 end
			2 -> if is_sensible?(r) do
						 r
					 else
						 if is_sensible?(l) do
							 l
						 else
							 {op,l,r}
						 end
					 end
		end
	end
	defp rem_op(e) do
		e
	end
	
	# Modify a value
	defp mod_val(names,litrange,{:v,_vname}) do
		pick_val(names,litrange)
	end
	defp mod_val(names,litrange,{:lit,_val}) do
		pick_val(names,litrange)
	end
	defp mod_val(names,litrange,{op,l,r}) do
		if not is_sensible?({op,l,r}) do
			# This should not have been built, but trying to fix it won't help...
			{op,l,r}
		else
			res = case :random.uniform(2) do
							1 -> {op,l,mod_val(names,litrange,r)}
							2 -> {op,mod_val(names,litrange,l),r}
						end
			res = ILP.simplify(res)
			if is_sensible?(res) do
				res
			else
				mod_val(names,litrange,{op,l,r})
			end
		end
	end

	defp split(type,names,litrange,{op,l,r}) do
		res = case :random.uniform(3) do
						1 -> {op,split(type,names,litrange,l),r}
						2 -> {op,l,split(type,names,litrange,r)}
						3 -> case type do
									 :num ->
										 {pick_op(:arith),l,{op,pick_val(names,litrange),r}}
									 :bool ->
										 case op_type({op,l,r}) do
											 :bool ->
												 {pick_op(:bool),l,{op,pick_val(names,litrange),r}}
											 :num ->
												 case op_type(l) do
													 :bool ->
														 {pick_op(:bool),l,{op,pick_val(names,litrange),r}}
													 :num ->
														 case :random.uniform(2) do
															 1 -> {pick_op(:comp),l,{op,pick_val(names,litrange),r}}
															 2 -> {pick_op(:arith),l,{op,pick_val(names,litrange),r}}
														 end
												 end
										 end
								 end
					end
		ILP.simplify(res)
		if is_sensible?(res) and (res != {op,l,r}) do
			res
		else
			split(type,names,litrange,{op,l,r})
		end
	end
	defp split(_type,_names,_litrange,e) do
		e
	end

	# "Nudge" a literal
	defp nudge({:lit,val}) do
		{:lit,val + (:random.uniform(4) - 2)}
	end
	defp nudge({op,l,{:lit,v}}) do
		ILP.simplify({op,l,nudge({:lit,v})})
	end
	defp nudge({op,{:lit,v},r}) do
		ILP.simplify({op,nudge({:lit,v}),r})
	end
	defp nudge({op,l,r}) do
		res = case :random.uniform(2) do
						1 -> 
							t = {op,l,nudge(r)}
							if t == {op,l,r} do
								{op,nudge(l),r}
							else
								t
							end
						2 ->
							t = {op,nudge(l),r}
							if t == {op,l,r} do
								{op,l,nudge(r)}
							else
								t
							end
					end
		res = ILP.simplify(res)
		if is_sensible?(res) do
			res
		else
			nudge({op,l,r})
		end
	end
	defp nudge(e) do
		e
	end

	defp is_sensible?(exp) do
		#:io.format("Filtering ~p~n",[Exp.pp(exp)])
	  # Filter stupid possibilities
		case exp do
			{:multiply,{:lit,1},_} -> false
			{:multiply,_,{:lit,1}} -> false
			{:divide,_,{:lit,1}} -> false
			{:plus,_,{:lit,0}} -> false
			{:plus,{:lit,0},_} -> false
			{:divide,_,{:lit,0}} -> false
			{_,{:lit,_},{:lit,_}} -> false
			{:conj,{:lit,_},_} -> false
			{:conj,_,{:lit,_}} -> false
			{:disj,{:lit,_},_} -> false
			{:disj,_,{:lit,_}} -> false
			{:gr,{:lit,_},_} -> false
			{:ge,{:lit,_},_} -> false
			{:lt,{:lit,_},_} -> false
			{:le,{:lit,_},_} -> false
			{:eq,{:lit,true},_} -> false
			{:eq,_,{:lit,true}} -> false
			{:ne,{:lit,true},_} -> false
			{:ne,_,{:lit,true}} -> false
			{:eq,{:lit,false},_} -> false
			{:eq,_,{:lit,false}} -> false
			{:ne,{:lit,false},_} -> false
			{:ne,_,{:lit,false}} -> false
			{:eq,{:v,name},{:v,name}} -> false
			{:ne,{:v,name},{:v,name}} -> false
			{:gr,{:v,name},{:v,name}} -> false
			{:ge,{:v,name},{:v,name}} -> false
			{:lt,{:v,name},{:v,name}} -> false
			{:le,{:v,name},{:v,name}} -> false
			{:eq,x,x} -> false
			{:neq,x,x} -> false
			_ -> true
		end
	end
	
end