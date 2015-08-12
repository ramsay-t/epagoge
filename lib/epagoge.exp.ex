defmodule Epagoge.Exp do

	@type t :: {:v,String.t} | {:lit, String.t} | {atom,t,t} 

	# Logic
	def eval({:eq,l,r},bind) do
		{lv,_} = eval(l,bind)
		{rv,_} = eval(r,bind)
		case get_number(lv) do
			false -> {lv == rv,bind}
			ln ->
				case get_number(rv) do
					false -> {lv == rv,bind}
					rn -> {ln == rn, bind}
				end
		end
	end
	def eval({:nt,r},bind) do
		{rv,_} = eval(r,bind)
		{not rv,bind}
	end
	def eval({:ne,l,r},bind) do
		eval({:nt,{:eq,l,r}},bind)
	end
	def eval({:conj,l,r},bind) do
		{lv,_} = eval(l,bind)
		{rv,_} = eval(r,bind)
		{lv and rv,bind}
	end
	def eval({:disj,l,r},bind) do
		{lv,_} = eval(l,bind)
		{rv,_} = eval(r,bind)
		{lv or rv,bind}
	end
	# Variables and literals
	def eval({:v,name},bind) do
		{bind[name],bind}
	end
	def eval({:lit,val},bind) do
		{val,bind}
	end

	# Comparison of numerics
	def eval({:gr,l,r},bind) do
		case make_numbers(l,r,bind) do
			false -> {false,bind}
			{lv,rv} -> {lv > rv,bind}
		end
	end
	def eval({:ge,l,r},bind) do
		case make_numbers(l,r,bind) do
			false -> {false,bind}
			{lv,rv} -> {lv >= rv,bind}
		end
	end
	def eval({:lt,l,r},bind) do
		case make_numbers(l,r,bind) do
			false -> {false,bind}
			{lv,rv} -> {lv < rv,bind}
		end
	end
	def eval({:le,l,r},bind) do
		case make_numbers(l,r,bind) do
			false -> {false,bind}
			{lv,rv} -> {lv <= rv,bind}
		end
	end

	# Assignment
	def eval({:assign,name,e}, bind) do
		{val,_} = eval(e,bind)
		{val,Map.put(bind,name,val)}
	end

	# Arithmatic
	def eval({:plus,l,r}, bind) do
		case make_numbers(l,r,bind) do
			false -> {false,bind}
			{lv,rv} -> {lv + rv,bind}
		end
	end
	def eval({:minus,l,r}, bind) do
		case make_numbers(l,r,bind) do
			false -> {false,bind}
			{lv,rv} -> {lv - rv,bind}
		end
	end
	def eval({:multiply,l,r}, bind) do
		case make_numbers(l,r,bind) do
			false -> {false,bind}
			{lv,rv} -> {lv * rv,bind}
		end
	end
	def eval({:divide,l,r}, bind) do
		case make_numbers(l,r,bind) do
			false -> {false,bind}
			{lv,rv} -> 
				if rv == 0 do
					raise "Divide by zero"
				else
					{lv / rv,bind}
				end
		end
	end
	def eval({:concat,l,r},bind) do
		lv = make_string(l,bind)
		rv = make_string(r,bind)
		{lv <> rv,bind}
	end

	# Match and get
	def eval({:match,pre,suf,tgt},bind) do
		{v,_} = eval(tgt,bind)
		case index_of(v,pre) do
			nil ->
				{false,bind}
			pi ->
				case suf do
					# Empty means right to the end, so its always true
					"" ->
						{true,bind}
					_ ->
						# Could be multiple copies of suf...
						case all_indices(v,suf) do
							nil ->
								{false,bind}
							sis ->
								if Enum.any?(sis, fn(si) -> si > pi end) do
									{true,bind}
								else
									{false,bind}
								end
						end
				end
		end
	end

	def eval({:get,pre,suf,tgt},bind) do
		{v,_} = eval(tgt,bind)
		if v == nil do
			{nil,bind}
		else
			case index_of(v,pre) do
				nil ->
					{nil,bind}
				pi ->
					case suf do
						# Empty means right to the end
						"" ->
							{String.slice(v,pi+String.length(pre),String.length(v)),bind}
						_ ->
							case all_indices(v,suf) do
								nil ->
									{nil,bind}
								sis ->
									{get_val(v,pi+String.length(pre),sis),bind}
							end
					end
			end
		end
	end

	defp get_val(_v,_pi,[]) do
		nil
	end
	defp get_val(v,pi,[si | sis]) do
		if si > pi do
			String.slice(v,pi,si-pi)
		else
			get_val(v,pi,sis)
		end
	end

	defp all_indicies(_,"") do
		[0]
	end
	defp all_indices(haystack,needle) do
		case index_of(haystack,needle) do
			nil -> nil
			i ->
				case all_indices(String.slice(haystack,i+String.length(needle),String.length(haystack)),needle) do
					nil ->
						[i]
					is ->
						# We have to offset the children because we have sliced the string...
						[i | Enum.map(is, fn(idx) -> idx + i + String.length(needle) end)]
				end
		end
	end

	defp index_of(_,"") do
		0
	end
	defp index_of(haystack,needle) do
		index_of_step(haystack,needle,0)
	end
	defp index_of_step("",_,_) do
		nil
	end
	defp index_of_step(nil,_,_) do
		nil
	end
	defp index_of_step(h,n,i) do
		if String.starts_with?(h,n) do
			i
		else
			index_of_step(String.slice(h,1,String.length(h)),n,i+1)
		end
	end
	
	# Helper functions
	defp make_numbers(l,r,bind) do
				case make_number(l,bind) do
			false ->
				false
			lv ->
				case make_number(r,bind) do
					false ->
						false
					rv ->
						{lv,rv}
				end
		end
	end

	defp make_number(e,bind) do
		{ev,_} = eval(e,bind)
		get_number(ev)
	end
	def get_number(ev) do
		cond do
			is_integer(ev) -> ev
			is_float(ev) -> ev
			true ->
				try do
					String.to_float(ev)
				catch 
					:error, _ ->
						try do
							String.to_integer(ev)
						catch 
							:error, _ ->
								false
						end
				end
		end
	end

	def make_string(e,bind) do
		{ev,_} = eval(e,bind)
		if String.valid?(ev) do
			ev
		else
			to_string ev
		end
	end

  # String representations
	def pp({:lit,v}) do
		if String.valid?(v) do
			"\"" <> v <> "\""
		else 
			to_string(v)
		end
	end
	def pp({:v,name}) do
		to_string name
	end
	def pp({:eq,l,r}) do
		tpp(l) <> " = " <> tpp(r)
	end
	def pp({:ne,l,r}) do
		tpp(l) <> " != " <> tpp(r)
	end
	def pp({:nt,l}) do
		<<172 :: utf8>> <> tpp(l)
	end
	def pp({:gr,l,r}) do
		tpp(l) <> " > " <> tpp(r)
	end
	def pp({:ge,l,r}) do
		tpp(l) <> " >= " <> tpp(r)
	end
	def pp({:lt,l,r}) do
		tpp(l) <> " < " <> tpp(r)
	end
	def pp({:le,l,r}) do
		tpp(l) <> " =< " <> tpp(r)
	end
	def pp({:assign,n,r}) do
		pp({:v,n}) <> " := " <> tpp(r)
	end
	def pp({:concat,l,r}) do
		tpp(l) <> " <> " <> tpp(r)
	end
	def pp({:plus,l,r}) do
		tpp(l) <> " + " <> tpp(r)
	end
	def pp({:minus,l,r}) do
		tpp(l) <> " - " <> tpp(r)
	end
	def pp({:multiply,l,r}) do
		tpp(l) <> " * " <> tpp(r)
	end
	def pp({:divide,l,r}) do
		tpp(l) <> " / " <> tpp(r)
	end
	def pp({:conj,l,r}) do
		tpp(l) <> " ^ " <> tpp(r)
	end
	def pp({:disj,l,r}) do
		tpp(l) <> " v " <> tpp(r)
	end
	def pp({:match,pre,suf,tgt}) do
		"match(\"" <> pre <> "\",\"" <> suf <> "\"," <> tpp(tgt) <>")"
	end
	def pp({:get,pre,suf,tgt}) do
		"get(\"" <> pre <> "\",\"" <> suf <> "\"," <> tpp(tgt) <>")"
	end

	# Trivial pretty print
	# This is a wrapper function for pp that adds brackets to things that are
	# non-trivial
	def tpp(e) do
		es = pp(e)
		if trivial?(e) do
			es
		else
			"(" <> es <> ")"
		end
	end

	# Trivial and non-trivial expressions
	# Crudely, trivial expressions are those that can be pretty printed
	# without brackets and the meaning is still clear
	def trivial?({:lit,_}) do
		true
	end
	def trivial?({:v,_}) do
		true
	end
	def trivial?({:nt,_}) do
		true
	end
	def trivial?({:match,_,_,_}) do
		true
	end
	def trivial?({:get,_,_,_}) do
		true
	end
	def trivial?(_e) do
		false
	end

	# Free variables
	def freevars({:v,name}) do
		[name]
	end
	def freevars({:lit,_}) do
		[]
	end
	def freevars({:get,_,_,e}) do
		freevars(e)
	end
	def freevars({:match,_,_,e}) do
		freevars(e)
	end
	def freevars({_,r}) do
		:lists.usort(freevars(r))
	end
	def freevars({:assign,tgt,r}) do
		:lists.usort([tgt | freevars(r)])
	end
	def freevars({_,l,r}) do
		:lists.usort(freevars(l) ++ freevars(r))
	end
	
end
