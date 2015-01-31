defmodule Epagoge.ILP do
	alias Epagoge.NF, as: NF
	alias Epagoge.Exp, as: Exp
	alias Epagoge.Str, as: Str
	alias Epagoge.Subsumption, as: Subs

	def generalise(ps) do
		IO.puts "\n----------------------------------------------------------"
		pps = Enum.map(ps,&NF.dnf/1)
		Enum.map(pps, fn p -> :io.format("~p~n             ~p~n",[Exp.pp(p),Exp.freevars(p)]) end)
		:fixme
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
		{:match,Str.gcp(s1,s2),Str.gcs(s1,s2),tgt}
	end
	def join({:match,_pre,_suf,tgt}=m,{:eq,{:v,tgt},{:lit,s}}) do
		if Exp.eval(m,Map.put(%{},tgt,s)) do
			m
		else
			#fixme...
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
  (e.g. i1 > 7 ^ i1 > 5 == i1 > 5) 
  """
	def simplify(e) do
		if is_list(e) do
			conj_to_list(simplify_step(NF.cnf(list_to_conj(e))))
		else 
			simplify_step(NF.cnf(e))
		end
	end

	def simplify_step({:conj,{:lit, true},e}) do
		simplify(e)
	end
	def simplify_step({:conj,e,{:lit, true}}) do
		simplify(e)
	end
	def simplify_step({:conj,l,{:conj,_,_}=r}) do
		sl = simplify(l)
		sr = simplify(r)
		srlist = conj_to_list(sr)
		if Enum.any?(srlist, fn(sre) -> Subs.subsumes?(sre,sl) end) do
			sr
		else
			filtered = List.foldl(srlist,[], 
														fn(sre,acc) ->  
																if Subs.subsumes?(sl,sre) do
																	acc
																else
																	acc ++ [sre]
																end
														end)
			list_to_conj([sl | filtered])
		end
	end
	def simplify_step({:conj,l,r}) do
		sl = simplify(l)
		sr = simplify(r)
		if Subs.subsumes?(sl,sr) do 
			sl
		else if Subs.subsumes?(sr,sl) do
					 sr
				 else
					 {:conj,sl,sr}
				 end
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

end