defmodule Epagoge.Subsumption do

	def subsumes?([],r) do
		# Emptylist can be read as "no restrictions", so it is just 'true' and subsumes everything
		true
	end
	def subsumes?(_,[]) do
		# Conversley, anything restrictive can't subsume true
		false
	end
	def subsumes?(l,r) do
		if l == r do
			# Reflexivity
			true
		else
			if is_list(l) and is_list(r) do
				# Lists of expressions are treated as conjunction
				subsumes_case(List.foldr(tl(l),hd(l),fn(e,acc) -> {:conj,e,acc} end),
										 List.foldr(tl(r),hd(r),fn(e,acc) -> {:conj,e,acc} end))
			else
				subsumes_case(l,r)
			end
		end
	end

	# Variable subsumption
	defp subsumes_case({:v,_},{:lit,_}) do
		true
	end
	defp subsumes_case({:v,lname},{:v,rname}) do
		lname == rname
	end
	defp subsumes_case({:lit,l1},{:lit,l2}) do
		l1 == l2
	end

	defp subsumes_case({:eq,ll,lr},{:eq,rl,rr}) do
		subsumes_case(ll,rl) and subsumes_case(lr,rr)
	end

  # Match expression subsuption
	defp subsumes_case({:match,lpre,lsuf,lt},{:match,rpre,rsuf,rt}) do
		if lt != rt do
			false
		else
			String.starts_with?(rpre,lpre) and String.ends_with?(rsuf,lsuf)
		end
	end

	#FIXME: this doesn't feel complete. I can imagine there might be 
	#       a circumstance where you need both halves to subsume...
	defp subsumes_case({:conj,l,r},o) do
		subsumes_case(l,o) or subsumes_case(r,o)
	end
	defp subsumes_case(o,{:conj,l,r}) do
		subsumes_case(o,l) and subsumes_case(o,r)
	end

	# Some numerics
	defp subsumes_case({:eq,tgt,{:lit,eqval}},{:ge,tgt,{:lit,gval}}) do
		eqval >= gval
	end
	defp subsumes_case({:ge,tgt,{:lit,lval}},{:ge,tgt,{:lit,rval}}) do
		lval <= rval
	end
	defp subsumes_case({:ge,_,_},{:eq,_,_}) do
		false
	end
	defp subsumes_case({:eq,tgt,{:lit,eqval}},{:le,tgt,{:lit,lval}}) do
		eqval <= lval
	end
	defp subsumes_case({:le,tgt,{:lit,lval}},{:le,tgt,{:lit,rval}}) do
		lval >= rval
	end
	defp subsumes_case({:le,_,_},{:eq,_,_}) do
		false
	end
	defp subsumes_case({:le,_,_},{:ge,_,_}) do
		false
	end
	defp subsumes_case({:ge,_,_},{:le,_,_}) do
		false
	end

	defp subsumes_case({:eq,tgt,{:lit,eqval}},{:gt,tgt,{:lit,lval}}) do
		eqval > lval
	end
	defp subsumes_case({:gt,tgt,{:lit,lval}},{:gt,tgt,{:lit,rval}}) do
		lval >= rval
	end
	defp subsumes_case({:eq,tgt,{:lit,eqval}},{:lt,tgt,{:lit,lval}}) do
		eqval < lval
	end
	defp subsumes_case({:lt,tgt,{:lit,lval}},{:lt,tgt,{:lit,rval}}) do
		lval >= rval
	end
	defp subsumes_case({:lt,_,_},{:eq,_,_}) do
		false
	end
	defp subsumes_case({:gt,_,_},{:eq,_,_}) do
		false
	end
	defp subsumes_case({:lt,_,_},{:gt,_,_}) do
		false
	end
	defp subsumes_case({:gt,_,_},{:lt,_,_}) do
		false
	end
	
	# Mismatched targets or non-literal values
	defp subsumes_case({:gt,t1,_},{:gt,t2,_}) do
		false
	end
	defp subsumes_case({:lt,t1,_},{:lt,t2,_}) do
		false
	end
	defp subsumes_case({:ge,t1,_},{:ge,t2,_}) do
		false
	end
	defp subsumes_case({:le,t1,_},{:le,t2,_}) do
		false
	end

	defp subsumes_case({:eq,t1,_},{:le,t2,_}) do
		false
	end
	defp subsumes_case({:eq,t1,_},{:lt,t2,_}) do
		false
	end
	defp subsumes_case({:eq,t1,_},{:ge,t2,_}) do
		false
	end
	defp subsumes_case({:eq,t1,_},{:gt,t2,_}) do
		false
	end


	defp subsumes_case(_l,_r) do
		:io.format("Fell through subsumption: ~p vs ~p~n",[_l,_r])
		false
	end
end