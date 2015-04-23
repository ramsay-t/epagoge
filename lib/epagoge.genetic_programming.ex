defmodule Epagoge.GeneticProgramming do
	alias Epagoge.Exp, as: Exp

	def infer(dataset, target) do
		infer(dataset,target,[{:pop_size,10},{:thres,1.0}])
	end
	def infer(dataset, target, options) do
		names = get_v_names(dataset)
		type = get_type(dataset,target)
		:elgar.run(&generator(names,type,&1),&fitness(dataset,target,type,&1),mutations(names,type),&crossover(type,&1,&2),options)
	end

	defp get_type([d | _],target) do
		# Since we don't support mixed types this is determined by the first element
		if is_boolean(d[target]) do
			:bool
		else
			:num
		end
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
																				 1
																			 end
																	 end
													 if delta > 0 do
														 # Occam's razor...
														 delta + (depth(exp) / 100)
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
	defp pick_val(names) do
		case :random.uniform(2) do
			1 ->
				# Variable...
				{:v,:lists.nth(:random.uniform(length(names)),names)}
			2 ->
				# Literal...
				# Boolean literals are never useful!
				case :random.uniform(4) do
					1 -> {:lit,1}
					_ -> {:lit,:random.uniform(1000)}
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
	defp generator(names,type,_seed) do
		v = pick_val(names)
		case :random.uniform(2) do
			1 -> v
			2 ->
				# Use the add_op mutation because that includes filter code
				# for stupid combinations...
				add_op(names,type,v)
		end
	end

	# Crossover on complex expressions always replaces one of the branches
	defp crossover(_type,{op,l,r},e2) do
		case :random.uniform(2) do
			1 -> {op,get_subexp(e2),r}
			2 -> {op,l,get_subexp(e2)}
		end
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
				if is_sensible?(res) do
					res
				else
					crossover(type,e1,e2)
				end
		end
	end

	# Mutations

	# This function makes a list of mutation operators that use the
	# supplied list of names
	defp mutations(names,type) do
		[
		 &add_op(names,type,&1),
		 &rem_op/1,
		 &mod_val(names,&1),
		 &nudge/1
		]
	end

	defp add_op_detail(names,optype,e) do
							case :random.uniform(2) do
								1 ->
									{pick_op(optype),e,pick_val(names)}
								2 ->
									{pick_op(optype),pick_val(names),e}
							end
	end
	
	# Add an operator and a random value
	defp add_op(names,type,e) do
		res = case type do
						:num ->
							add_op_detail(names,:arith,e)
						:bool ->
							case e do
								{op,_,_} ->
									if Enum.any?([:conj,:disj,:gr,:ge,:lt,:le,:eq,:ne],fn(o) -> o == op end) do
										add_op_detail(names,:bool,e)
									else
										add_op_detail(names,:comp,e)
									end
								_ ->
									add_op_detail(names,:comp,e)
							end
					end
		if is_sensible?(res) do
			res
		else
			# Try again...
			add_op(names,type,e)
		end
	end

	# Remove an operator
	defp rem_op({_op,l,r}) do
		case :random.uniform(2) do
			1 -> l
			2 -> r
		end
	end
	defp rem_op(e) do
		e
	end
	
	# Modify a value
	defp mod_val(names,{:v,_vname}) do
		pick_val(names)
	end
	defp mod_val(names,{:lit,_val}) do
		pick_val(names)
	end
	defp mod_val(names,{op,l,r}) do
		res = case :random.uniform(2) do
			1 -> {op,l,mod_val(names,r)}
			2 -> {op,mod_val(names,l),r}
		end
		if is_sensible?(res) do
			res
		else
			mod_val(names,{op,l,r})
		end
	end

	# "Nudge" a literal
	defp nudge({:lit,val}) do
		{:lit,val + (:random.uniform(10) - 5)}
	end
	defp nudge({op,l,{:lit,v}}) do
		{op,l,nudge({:lit,v})}
	end
	defp nudge({op,{:lit,v},r}) do
		{op,nudge({:lit,v}),r}
	end
	defp nudge({op,l,r}) do
		case :random.uniform(2) do
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
			_ -> true
		end
	end

end