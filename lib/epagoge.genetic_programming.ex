defmodule Epagoge.GeneticProgramming do
	alias Epagoge.Exp, as: Exp

	def infer(dataset, target) do
		infer(dataset,target,[{:pop_size,10},{:thres,1.0}])
	end
	def infer(dataset, target, options) do
		names = get_v_names(dataset)
		:elgar.run(&generator(names,&1),&fitness(dataset,target,&1),mutations(names),&crossover/2,options)
	end

	# Fitness
	defp fitness(dataset,target,exp) do
		diffs = Enum.map(dataset,
										 fn(data) ->
												 # Generated formulae can have errors (e.g. divide by zero)
												 try do
													 {comp,_newdata} = Exp.eval(exp,data)
													 delta = abs(data[target] - comp)
													 if delta > 0 do
														 # Occam's razor...
														 delta + (depth(exp) / 100)
													 else
														 0
													 end
													 rescue
														 e -> 
														 99999
												 end
										 end
										)
		av = Enum.sum(diffs) / length(diffs)
		if av == 0 do
			1.0
		else
			1 / av
		end
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
				case :random.uniform(2) do
					1 -> {:lit,1}
					2 -> {:lit,:random.uniform(1000)}
				end
		end
	end

	# Pick a random operator
	# Currently this makes no attempt to detrmine type...
	# In fact, currently they are all numeric...
	defp pick_op() do
		ops = [:plus,:minus,:divide,:multiply]
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
	defp generator(names,_seed) do
		v = pick_val(names)
		case :random.uniform(2) do
			1 -> v
			2 ->
				# Use the add_op mutation because that includes filter code
				# for stupid combinations...
				add_op(names,v)
		end
	end

	# Crossover on complex expressions always replaces one of the branches
	defp crossover({op,l,r},e2) do
		case :random.uniform(2) do
			1 -> {op,get_subexp(e2),r}
			2 -> {op,l,get_subexp(e2)}
		end
	end
	defp crossover(e1,{op,l,r}) do
		crossover({op,l,r},e1)
	end
	defp crossover(e1,e2) do
		# If we are here then neither is a compund, so lets compound them...
		{pick_op(),e1,e2}
	end

	# Mutations

	# This function makes a list of mutation operators that use the
	# supplied list of names
	defp mutations(names) do
		[
		 &add_op(names,&1),
		 &rem_op/1,
		 &mod_val(names,&1)
		]
	end

	# Add an operator and a random value
	defp add_op(names,e) do
		res = 
			case :random.uniform(2) do
				1 ->
					{pick_op(),e,pick_val(names)}
				2 ->
					{pick_op(),pick_val(names),e}
			end
	  # Filter stupid possibilities
		case res do
			{:multiply,{:lit,1},r} -> add_op(names,e)
			{:multiply,l,{:lit,1}} -> add_op(names,e)
			{:divide,l,{:lit,1}} -> add_op(names,e)
			{_,{:lit,_},{:lit,_}} -> add_op(names,e)
			_ -> res
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
		case :random.uniform(2) do
			1 -> {op,l,mod_val(names,r)}
			2 -> {op,mod_val(names,l),r}
		end
	end

end