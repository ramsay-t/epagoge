defmodule Epagoge.GeneticProgramming do
	alias Epagoge.Exp, as: Exp
	alias Epagoge.ILP, as: ILP

	# This uses the Elgar genetic algorithms library
	# Since it specifies a fixed limit it will always terminate
	# but it may return a pair {:incomplete,Val} if it hits the limit
	def infer(dataset, target) do
		infer(dataset,target,[{:pop_size,40},{:thres,1.0},{:limit,100}])
	end
	def infer(dataset, target, options) do
		names = get_v_names(dataset)
		litrange = get_lit_range(dataset)
		strings = get_lit_strings(dataset)
		case get_type(dataset,target) do
			:num ->
				:elgar.run(&num_generator(names,litrange,&1),&num_fitness(dataset,target,&1),num_mutations(names,litrange),&num_crossover/2,options)
			:bool ->
				:elgar.run(&bool_generator(names,{litrange,strings},&1),&bool_fitness(dataset,target,&1),bool_mutations(names,{litrange,strings}),&bool_crossover/2,options)
		end
	end

	defp get_type([d | _],target) do
		# Since we don't support mixed types this is determined by the first element
		if is_boolean(d[target]) do
			:bool
		else
			:num
		end
	end

	defp get_lit_strings(dataset) do
		get_lit_strings(dataset,[])
	end
	defp get_lit_strings([],ss) do
		ss
	end
	defp get_lit_strings([data | dataset],ss) do
		newss = :lists.usort(ss ++ Enum.flat_map(Map.keys(data),
																						fn(k) ->
																								v = data[k]
																								if String.valid?(v) do
																									[v]
																								else
																									[]
																								end
																						end))
		get_lit_strings(dataset,newss)
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
	defp num_fitness(dataset,target,exp) do
#		:io.format("~p~n",[Exp.pp(exp)])
		len = length(dataset)
		difftotal = List.foldl(dataset,
											 0,
											 fn(data,acc) ->
													 # Generated formulae can have errors (e.g. divide by zero)
													 try do
														 {comp,_newdata} = Exp.eval(exp,data)
														 delta = abs(data[target] - comp)
														 # Erlang/Elixir seems to have slightly random behaviour below some threshold of accuracy...
														 if delta > 0.00000000001 do
															 # Occam's razor...
															 acc + delta + (depth(exp) / len)
														 else
															 acc
														 end
														 rescue
															 _e -> 
															 # Crashing is definately wrong...
															 acc + 99999
													 end
											 end
											)
		av = difftotal / len
		1 / (1 + av)
	end
	
	defp bool_fitness(dataset,target,exp) do
		diffs = Enum.map(dataset,
										 fn(data) ->
												 # Generated formulae can have errors (e.g. divide by zero)
												 try do
													 {comp,_newdata} = Exp.eval(exp,data)
													 delta = if data[target] == comp do
																		 0
																	 else
																		 if is_boolean(comp) do
																			 # How big you make this value controls how much it values size vs correctness
																			 5 + (depth(exp) / length(dataset))
																		 else
																			 # Not being boolean is really, really wrong
																			 # but its worth generating them because sometimes they will be
																			 # needed in crossover...
																			 10 + (depth(exp) / length(dataset))
																		 end
																	 end
													 rescue
														 _e -> 
														 # Crashing is definately wrong...
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
	defp pick_val(names,{{litmin,litmax},strings}) do
		if strings == [] do
			pick_val(names,{litmin,litmax})
		else
			case :random.uniform(2) do
				1 -> 
					pick_val(names,{litmin,litmax})
				2 ->
					{:lit,:lists.nth(:random.uniform(length(strings)),strings)}
			end
		end
	end


	defp pick_val(names,{litmin,litmax}) do
		case :random.uniform(2) do
			1 ->
				# Variable...
				# This crashes if there are no names, but I can't see how that will 
				# ever be meaningful
				{:v,:lists.nth(:random.uniform(length(names)),names)}
			2 ->
				# Literal...
				# Boolean literals are never useful?
				if litmax - litmin == 0 do
					{:lit,1}
				else
					case :random.uniform(4) do
						1 -> {:lit,1}
						_ -> {:lit,:random.uniform(litmax-litmin) + litmin}
					end
				end
		end
	end

	# Pick a random operator
	# Currently this makes no attempt to detrmine type...
	# In fact, currently they are all numeric...
	defp pick_op(type) do
		ops = case type do
						:arith -> [:plus,:minus,:divide,:multiply]
						:comp -> [:gr,:ge,:lt,:le,:ne,:eq]
						:bool -> [:conj,:disj]
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
	defp num_generator(names,litrange,_seed) do
		v = pick_val(names,litrange)
		case :random.uniform(2) do
			1 -> v
			2 ->
				# Use the add_op mutation because that includes filter code
				# for stupid combinations...
				num_add_op(names,litrange,v)
		end
	end
	defp bool_generator(names,litrange,_seed) do
		v = pick_val(names,litrange)
		case :random.uniform(2) do
			1 -> v
			2 ->
				# Use the add_op mutation because that includes filter code
				# for stupid combinations...
				bool_add_op(names,litrange,v)
		end
	end

	# Crossover
	defp bool_crossover({op,l,r},e2) do
		res = case :random.uniform(3) do
						1 -> {op,get_subexp(e2),r}
						2 -> {op,l,get_subexp(e2)}
						3 -> case op_type(op) do
									 :bool ->
										 {pick_op(:bool),l,r}
									 :num ->
										 case :random.uniform(2) do
											 1 -> {pick_op(:comp),l,r}
											 2 -> {pick_op(:arith),l,r}
										 end
								 end
					end
		ILP.simplify(res)
	end
	defp bool_crossover(e1,{op,l,r}) do
		bool_crossover({op,l,r},e1)
	end
	defp bool_crossover({:lit,v1},{:lit,v2}) do
		if is_number(v1) and is_number(v2) do
			# There is nothing sensible to do with expressions over two literals, so lets take the average
			{:lit,(v1 + v2) / 2}
		else
			case :random.uniform(2) do
				1 -> {:lit,v1}
				2 -> {:lit,v2}
			end
		end
	end
	defp bool_crossover(e1,e2) do
		res = case :random.uniform(2) do
						1 -> {pick_op(:comp),e1,e2}
						2 -> {pick_op(:bool),e1,e2}
					end
		res = ILP.simplify(res)
		if is_sensible?(res) do
			res
		else
			bool_crossover(e1,e2)
		end
	end

	# Crossover on complex expressions always replaces one of the branches
	defp num_crossover({op,l,r},e2) do
		res = case :random.uniform(3) do
						1 -> {op,get_subexp(e2),r}
						2 -> {op,l,get_subexp(e2)}
						3 -> {pick_op(:arith),l,r}
					end
		ILP.simplify(res)
	end
	defp num_crossover(e1,{op,l,r}) do
		num_crossover({op,l,r},e1)
	end
	defp num_crossover({:lit,v1},{:lit,v2}) do
		# There is nothing sensible to do with expressions over two literals, so lets take the average
		{:lit,(v1 + v2) / 2}
	end
	defp num_crossover(e1,e2) do
		# If we are here then neither is a compound, so lets compound them...
		{pick_op(:arith),e1,e2}
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
	defp bool_mutations(names,litrange) do
		[
		 &bool_add_op(names,litrange,&1),
		 &rem_op/1,
		 &mod_val(names,litrange,&1),
		 &nudge/1,
		 &bool_split(names,litrange,&1),
		 &bool_mod_op(&1)
		]
	end
	defp num_mutations(names,litrange) do
		[
		 &num_add_op(names,litrange,&1),
		 &rem_op/1,
		 &mod_val(names,litrange,&1),
		 &nudge/1,
		 &num_split(names,litrange,&1),
		 &num_mod_op(&1)
		]
	end

	defp add_op_to_symbol(names,litrange,e) do
		case :random.uniform(6) do
			1 -> ILP.simplify({pick_op(:comp),e,pick_val(names,litrange)})
			2 -> ILP.simplify({pick_op(:comp),pick_val(names,litrange),e})
			3 -> ILP.simplify({pick_op(:arith),e,pick_val(names,litrange)})
			4 -> ILP.simplify({pick_op(:arith),pick_val(names,litrange),e})
			5 -> ILP.simplify({pick_op(:bool),e,pick_val(names,litrange)})
			6 -> ILP.simplify({pick_op(:bool),pick_val(names,litrange),e})
		end
	end
	# Add an operator and a random value
	defp bool_add_op(names,litrange,e) do
		res = case e do
						{:lit,_} -> add_op_to_symbol(names,litrange,e)
						{:v,_} -> add_op_to_symbol(names,litrange,e)
						_ ->
							case :random.uniform(4) do
								1 -> ILP.simplify({pick_op(:comp),e,pick_val(names,litrange)})
								2 -> ILP.simplify({pick_op(:comp),pick_val(names,litrange),e})
								3 -> ILP.simplify({pick_op(:bool),e,pick_val(names,litrange)})
								4 -> ILP.simplify({pick_op(:bool),pick_val(names,litrange),e})
							end
					end
		if is_sensible?(res) do
			res
		else
			# Try again...
			bool_add_op(names,litrange,e)
		end
	end

	defp num_add_op(names,litrange,e) do
		case :random.uniform(2) do
			1 ->
				ILP.simplify({pick_op(:arith),e,pick_val(names,litrange)})
			2 ->
				ILP.simplify({pick_op(:arith),pick_val(names,litrange),e})
		end
	end

	defp bool_mod_op(names,litrange,{op,l,r}) do
		#:io.format("Mod Op~n")
		if not is_sensible?({op,l,r}) do
			# This should not have been created, but going round an endless loop is worse...
			{op,l,r}
		else
			res = case :random.uniform(3) do
							1 -> {op,bool_mod_op(l),r}
							2 -> {op,l,bool_mod_op(r)}
							3 -> case op_type({op,l,r}) do
										 :bool ->
											 {pick_op(:bool),l,r}
										 :num ->
											 case :random.uniform(2) do
												 1 -> {pick_op(:arith),l,r}
												 2 -> {pick_op(:comp),l,r}
											 end
									 end
						end
			res = ILP.simplify(res)
			if is_sensible?(res) and (res != {op,l,r}) do
				res
			else
				bool_mod_op({op,l,r})
			end
		end
	end
	defp bool_mod_op(e) do
		e
	end

	defp num_mod_op({_op,l,r}) do
		{pick_op(:arith),l,r}
	end
	defp num_mod_op(e) do
		e
	end

	# Remove an operator
	defp rem_op({op,l,r}) do
		#:io.format("Rem op ")
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
		#:io.format("Mod Val~n")
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

	defp num_split(names,litrange,{op,l,r}) do
		case :random.uniform(2) do
			1 -> {pick_op(:arith),l,{op,pick_val(names,litrange),r}}
			2 -> {pick_op(:arith),{op,pick_val(names,litrange),l},r}
		end
	end
	defp num_split(_names,_litrane,e) do
		e
	end
	
	defp bool_split(names,litrange,{op,l,r}) do
		#:io.format("Split~n")
		res = case op_type({op,l,r}) do
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
		ILP.simplify(res)
		if is_sensible?(res) and (res != {op,l,r}) do
			res
		else
			#split(type,names,litrange,{op,l,r})
			{op,l,r}
		end
	end
	defp bool_split(_names,_litrange,e) do
		e
	end

	# "Nudge" a literal
	defp nudge({:lit,val}) do
		if is_number(val) do
			{:lit,val + (:random.uniform(4) - 2)}
		else
			{:lit,val}
		end
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
		# This should all be handled by the simplifier!
		#FIXME remove calls to here and improve the simplifier
		true
	end

end