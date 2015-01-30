defmodule Epagoge.ILP do
	alias Epagoge.NF, as: NF
	alias Epagoge.Exp, as: Exp
	alias Epagoge.Str, as: Str

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

end