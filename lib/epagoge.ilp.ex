defmodule Epagoge.ILP do
	alias Epagoge.NF, as: NF
	alias Epagoge.Exp, as: Exp

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
		p = gcs(p1,p2)
		s = gcp(s1,s2)
		if p == "" and s == "" do
			nil
		else
			{:match,p,s,tgt}
		end
	end
	def join({:eq,{:v,tgt},{:lit,s1}},{:eq,{:v,tgt},{:lit,s2}}) do
		{:match,gcp(s1,s2),gcs(s1,s2),tgt}
	end
	def join({:match,pre,suf,tgt}=m,{:eq,{:v,tgt},{:lit,s}}) do
		if Exp.eval(m,Map.put(%{},tgt,s)) do
			m
		else
			#fixme...
			nil
		end
	end
	def join({:eq,tgt,{:lit,s}}=l,{:match,pre,suf,tgt}=r) do
		join(r,l)
	end
	def join(c1,c2) do
		raise ArgumentError, message: to_string(:io_lib.format("Unsupported join: ~p with ~p",[c1,c2]))
	end

	defp gcs("",_) do
		""
	end
	defp gcs(_,"") do
		""
	end
	defp gcs(s1,s2) do
		{p1,l1} = String.split_at(s1,-1)
		{p2,l2} = String.split_at(s2,-1)
		if l1 == l2 do
			gcs(p1,p2) <> l1
		else
			""
		end
	end

	defp gcp("",_) do
		""
	end
	defp gcp(_,"") do
		""
	end
	defp gcp(s1,s2) do
		{p1,l1} = String.split_at(s1,1)
		{p2,l2} = String.split_at(s2,1)
		if p1 == p2 do
			p1 <> gcp(l1,l2)
		else
			""
		end
	end

end