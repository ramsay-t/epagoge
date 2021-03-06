defmodule Epagoge.ILP do
	alias Epagoge.NF, as: NF
	alias Epagoge.Exp, as: Exp
	alias Epagoge.Str, as: Str
	alias Epagoge.Subsumption, as: Subs

	def generalise(ps) do
		IO.puts "\n----------------------------------------------------------"
		pps = Enum.map(ps,&NF.dnf/1)
		Enum.map(pps, fn p -> :io.format("~p~n             ~p~n",[Exp.pp(p),Exp.freevars(p)]) end)
		#FIXME
		ps
	end

	# Reflexivity
	def join({:match,p1,s1,tgt},{:match,p1,s1,tgt}) do
		{:match,p1,s1,tgt}
	end
	def join({:match,p1,s1,tgt},{:match,p2,s2,tgt}) do
		p = Str.gcs(p1,p2)
		s = Str.gcp(s1,s2)
		if p == "" and s == "" do
			nil
		else
			{:match,p,s,tgt}
		end
	end
	def join({:eq,{:v,tgt},{:lit,s1}},{:eq,{:v,tgt},{:lit,s2}}) do
		{:match,Str.gcp(s1,s2),Str.gcs(s1,s2),{:v,tgt}}
	end
	def join({:match,_pre,_suf,{:v,tgt}}=m,{:eq,{:v,tgt},{:lit,s}}) do
		if Exp.eval(m,Map.put(%{},tgt,s)) do
			m
		else
			#FIXME...
			nil
		end
	end
	def join({:eq,tgt,{:lit,_s}}=l,{:match,_pre,_suf,tgt}=r) do
		join(r,l)
	end
	def join(c1,c2) do
		raise ArgumentError, message: to_string(:io_lib.format("Unsupported join: ~p with ~p",[c1,c2]))
	end

	@doc """
  Simplify an expression.

  This is not a particularly advanced simplifier - it will convert the expression to CNF and then
  Remove trivial cases (e.g. true ^ P == P) and look for subsumption across conjunction 
  (e.g. i1 > 7 ^ i1 > 5 == i1 > 5).

  Also, this does not check for tautologies or falacies, so it won't simplify x > 4 ^ x < 3 to false.
  It might in the future.
  """
	def simplify(e) do
		r = if is_list(e) do
					conj_to_list(simplify_step(NF.cnf(list_to_conj(e))))
				else 
					simplify_step(NF.cnf(e))
				end
		r
	end

	def simplify_step({:get,"","",v}) do
		simplify(v)
	end
	def simplify_step({:match,"","",v}) do
		{:lit,true}
	end

	def simplify_step({:conj,{:lit, true},e}) do
		simplify(e)
	end
	def simplify_step({:conj,e,{:lit, true}}) do
		simplify(e)
	end
	def simplify_step({:conj,{:match,_pre,_suf,tgt}=l,r}) do
		sr = simplify(r)
		srlist = conj_to_list(sr)
		# FIXME this shouldn't depend on subsumption...
		if Enum.any?(srlist, fn(sre) -> Subs.subsumes?(sre,l) end) do
			sr
		else
			{newl,filtered} = List.foldl(srlist,
												{l,[]},
												fn(sre,{m,acc}) ->
														case sre do
															{:eq,t2,{:lit,_val}} ->
																if t2 == tgt do
																	if Subs.subsumes?(m,sre) do
																		{m,acc}
																	else
																		{m,acc++[sre]}
																	end
																else
																	{m,acc++[sre]}
																end
															{:match,_,_,t2} ->
																if t2 == tgt do
																	case join(m,sre) do
																		nil ->
																			{m,acc++[sre]}
																		newmatch ->
																			# Drop the subsumed match from the accumulator
																			{newmatch,acc}
																	end
																else
																	{m,acc++[sre]}
																end
															_ ->
																{m,acc++[sre]}
														end
												end)
			case newl do
				{:match,"","",_} ->
					list_to_conj(filtered)
				_ ->
					list_to_conj([newl | filtered])
			end
		end
	end
	def simplify_step({:conj,l,{:match,pre,suf,tgt}}) do
		simplify({:conj,{:match,pre,suf,tgt},l})
	end

	def simplify_step({:conj,l,{:conj,_,_}=r}) do
		sl = simplify(l)
		sr = simplify(r)
		srlist = conj_to_list(sr)
		filterlist = Enum.filter(srlist,fn(o) -> not implies?(sl,o) end)
		if Enum.any?(filterlist, fn(o) -> implies?(o,sl) end) do
			list_to_conj(filterlist)
		else
			list_to_conj([sl|filterlist])
		end
	end
	def simplify_step({:conj,{:conj,_,_}=l,r}) do
		# Use the other pattern
		simplify_step({:conj,r,l})
	end

	# Numerics...
	def simplify_step({:plus,{:lit,0},x}) do
		x
	end
	def simplify_step({:plus,x,{:lit,0}}) do
		x
	end
	def simplify_step({:minus,{:lit,0},x}) do
		x
	end
	def simplify_step({:minus,x,{:lit,0}}) do
		x
	end
	def simplify_step({:multiply,{:lit,1},x}) do
		x
	end
	def simplify_step({:multiply,x,{:lit,1}}) do
		x
	end
	def simplify_step({:divide,x,{:lit,1}}) do
		x
	end

	# All-literal expressions can be simplified
	def simplify_step({:plus,{:lit,x},{:lit,y}}=orig) do
		if (is_integer(x) or is_float(x)) and (is_integer(y) or is_float(y)) do
			{:lit, x+y}
		else
			orig
		end
	end
	def simplify_step({:minus,{:lit,x},{:lit,y}}=orig) do
		if (is_integer(x) or is_float(x)) and (is_integer(y) or is_float(y)) do
			{:lit, x-y}
		else
			orig
		end
	end
	def simplify_step({:multiply,{:lit,x},{:lit,y}}=orig) do
		if (is_integer(x) or is_float(x)) and (is_integer(y) or is_float(y)) do
			{:lit, x*y}
		else
			orig
		end
	end
	def simplify_step({:divide,{:lit,x},{:lit,y}}=orig) do
		if (is_integer(x) or is_float(x)) and (is_integer(y) or is_float(y)) do
			if y == 0 or y == 0.0 do
				:undefined
			else
				{:lit, x/y}
			end
		else
			orig
		end
	end

	def simplify_step({:lt,{:lit,x},{:lit,y}}) do
		{:lit,x < y}
	end
	def simplify_step({:le,{:lit,x},{:lit,y}}) do
		{:lit,x <= y}
	end
	def simplify_step({:gr,{:lit,x},{:lit,y}}) do
		{:lit,x > y}
	end
	def simplify_step({:ge,{:lit,x},{:lit,y}}) do
		{:lit,x >= y}
	end


	def simplify_step({:lt,{:lit,x},y}) do
		{:gr,y,{:lit,x}}
	end
	def simplify_step({:le,{:lit,x},y}) do
		{:ge,y,{:lit,x}}
	end
	def simplify_step({:gr,{:lit,x},y}) do
		{:lt,y,{:lit,x}}
	end
	def simplify_step({:ge,{:lit,x},y}) do
		{:le,y,{:lit,x}}
	end

	def simplify_step({:eq,{:lit,x},{:lit,x}}) do
		{:lit,true}
	end
	def simplify_step({:eq,{:lit,_x},{:lit,_y}}) do
		{:lit,false}
	end
	def simplify_step({:eq,{:v,x},{:v,x}}) do
		{:lit,true}
	end
	def simplify_step({:ne,{:v,x},{:v,x}}) do
		{:lit,false}
	end
	def simplify_step({:ne,{:lit,x},{:lit,x}}) do
		{:lit,false}
	end
	def simplify_step({:ne,{:lit,_x},{:lit,_y}}) do
		{:lit,true}
	end

	def simplify_step({:nt,{:eq,l,r}}) do
		{:ne,l,r}
	end
	def simplify_step({:nt,{:ne,l,r}}) do
		{:eq,l,r}
	end
	def simplify_step({:nt,{:lit,true}}) do
		{:lit,false}
	end
	def simplify_step({:nt,{:lit,false}}) do
		{:lit,true}
	end
	def simplify_step({:nt,{:ge,l,r}}) do
		{:lt,l,r}
	end
	def simplify_step({:nt,{:le,l,r}}) do
		{:gr,l,r}
	end
	def simplify_step({:nt,{:gr,l,r}}) do
		{:le,l,r}
	end
	def simplify_step({:nt,{:lt,l,r}}) do
		{:ge,l,r}
	end
	
	# Move variables left...
	# Unless they are both variables!
	def simplify_step({:eq,{:v,l},{:v,r}}=orig) do
		orig
	end
	def simplify_step({:ne,{:v,l},{:v,r}}=orig) do
		orig
	end
	def simplify_step({:eq,v,{:v,x}}) do
		{:eq,{:v,x},v}
	end
	def simplify_step({:ne,v,{:v,x}}) do
		{:ne,{:v,x},v}
	end

	def simplify_step({:disj,{:eq,l,r},{:ne,l,r}}) do
		{:lit,true}
	end
	def simplify_step({:disj,{:ne,l,r},{:eq,l,r}}) do
		{:lit,true}
	end

	def simplify_step({:conj,{:eq,x,v},{:eq,x,v}}) do
		simplify({:eq,x,v})
	end
	def simplify_step({:conj,{:eq,x,{:lit,_v}},{:eq,x,{:lit,_o}}}) do
		{:lit,false}
	end

	def simplify_step({:disj,{:eq,x,v},{:eq,x,v}}) do
		simplify({:eq,x,v})
	end

	def simplify_step({:disj,x,{:lit,false}}) do
		simplify(x)
	end
	def simplify_step({:disj,{:lit,false},x}) do
		simplify(x)
	end
	def simplify_step({:conj,x,{:lit,true}}) do
		simplify(x)
	end
	def simplify_step({:conj,{:lit,true},x}) do
		simplify(x)
	end
	def simplify_step({:conj,_x,{:lit,false}}) do
		{:lit,false}
	end
	def simplify_step({:conj,{:lit,false},_x}) do
		{:lit,false}
	end

	# This catches the stupid things that GP comes up with:
	# (r1 != \"wine\") != (r1 = \"beer\") -->> (r1 != \"wine\") ^ (r1 != \"beer\")
	def simplify_step({:ne,{lop,ll,lr},{rop,rl,rr}}) when (lop == :eq or lop == :ne) and (rop == :eq or rop == :ne) do
		l = simplify({:conj,simplify({lop,ll,lr}),simplify({:nt,{rop,rl,rr}})})
		r = simplify({:conj,simplify({:nt,{lop,ll,lr}}),simplify({rop,rl,rr})})
		simplify({:disj,l,r})
	end

	def simplify_step({:disj,l,r}) do
		sl = simplify(l)
		sr = simplify(r)
		cond do
			(sl == inverse(sr)) or (sr == inverse(sl)) -> {:lit, true}
			sl == {:lit, false} -> sr
			sr == {:lit, false} -> sl
			true -> {:disj,sl,sr}
		end
	end

	def simplify_step({:conj,l,r}) do
		sl = simplify(l)
		sr = simplify(r)
		cond do
			sl == sr ->	sl
			# Inverse might be easier to calculate one way or the other
			(sl == inverse(sr)) or (sr == inverse(sl)) -> {:lit, false}
			(sr == {:lit, false}) or (sl == {:lit,false}) -> {:lit, false}
			implies?(sl,sr) -> sl
			implies?(sr,sl) -> sr
			true -> {:conj,sl,sr}
		end
	end

	def simplify_step({op,l,r}) do
		sl = simplify(l)
		sr = simplify(r)
		if {op,sl,sr} != {op,l,r} do
			simplify({op,sl,sr})
		else
			{op,l,r}
		end
	end
	def simplify_step(e) do
		e
	end

	# Convert a list of guards to a conjunction tree.
	defp list_to_conj([]) do
		{:lit, true}
	end
	defp list_to_conj([e]) do
		e
	end
	defp list_to_conj([e | es]) do
		{:conj,e,list_to_conj(es)}
	end

	# Convert a conjunction tree to a list.
	defp conj_to_list({:conj,l,r}) do
		conj_to_list(l) ++ conj_to_list(r)
	end
	defp conj_to_list({:lit,true}) do
		[]
	end
	defp conj_to_list(e) do
		[e]
	end

	# Compute inverse if possible?
	def inverse({:lit,true}) do
		{:lit, false}
	end
	def inverse({:lit, false}) do
		{:lit, true}
	end
	def inverse({:ge,x,y}) do
		{:lt,x,y}
	end
	def inverse({:gt,x,y}) do
		{:le,x,y}
	end
	def inverse({:le,x,y}) do
		{:gt,x,y}
	end
	def inverse({:lt,x,y}) do
		{:ge,x,y}
	end
	def inverse({:eq,x,y}) do
		{:ne,x,y}
	end
	def inverse({:ne,x,y}) do
		{:eq,x,y}
	end
	def inverse({:nt,x}) do
		x
	end
	def inverse({:conj,x,y}) do
		nx = simplify({:nt,x})
		ny = simplify({:nt,y})
		{:disj,nx,ny}
	end
	def inverse({:disj,x,y}) do
		nx = simplify({:nt,x})
		ny = simplify({:nt,y})
		{:conj,nx,ny}
	end
	def inverse(x) do
		# This is not very imaginative...
		{:nt, x}
	end

	@doc """
  This is a lightweight definition of implication. Where implies?(p,q) returns true it is the case
  that p -> q, however where implies?(p,q) returns false it *might not be* the case that p -> q.
  You could say that implies?(p,q) -> (p -> q)...
  """
	def implies?({:lit,false},_) do
		true
	end
	def implies?(_,{:lit,true}) do
		true
	end

	def implies?(p,p) do
		true
	end

	def implies?({:eq,x,{:lit,lval}},{:ge,x,{:lit,rval}}) do
		lval >= rval
	end
	def implies?({:eq,x,{:lit,lval}},{:gr,x,{:lit,rval}}) do
		lval > rval
	end
	def implies?({:eq,x,{:lit,lval}},{:le,x,{:lit,rval}}) do
		lval <= rval
	end
	def implies?({:eq,x,{:lit,lval}},{:lt,x,{:lit,rval}}) do
		lval < rval
	end

	def implies?({:ge,x,{:lit,lval}},{:ge,x,{:lit,rval}}) do
		lval >= rval
	end
	def implies?({:gr,x,{:lit,lval}},{:gr,x,{:lit,rval}}) do
		lval >= rval
	end
	def implies?({:ge,x,{:lit,lval}},{:gr,x,{:lit,rval}}) do
		lval > rval
	end
	def implies?({:gr,x,{:lit,lval}},{:ge,x,{:lit,rval}}) do
		# I don't want to get into a debate about floating point precision...
		lval >= rval
	end

	def implies?({:le,x,{:lit,lval}},{:le,x,{:lit,rval}}) do
		lval <= rval
	end
	def implies?({:lt,x,{:lit,lval}},{:lt,x,{:lit,rval}}) do
		lval <= rval
	end
	def implies?({:le,x,{:lit,lval}},{:lt,x,{:lit,rval}}) do
		lval < rval
	end
	def implies?({:lt,x,{:lit,lval}},{:le,x,{:lit,rval}}) do
		lval <= rval
	end

	def implies?({:disj,l,r},rr) do
		implies?(l,rr) and implies?(r,rr)
	end
	def implies?({:conj,l,r},rr) do
		#FIXME this is hard because rr might depend on parts of both...
		false
	end

	# Being equal to one thing implies that you aren't equal to anything else
	def implies?({:eq,l,r},{:ne,l,rr}) do
		r != rr
	end

	# Check whether the rules might match with some simplification
	def implies?(l,r) do
		sl = simplify(l)
		sr = simplify(r)
		if (l == sl) and (r == sr) do
			false
		else
			implies?(sl,sr)
		end
	end

end