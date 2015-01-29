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

	defp subsumes_case(_l,_r) do
		:io.format("Fell through subsumption: ~p vs ~p~n",[_l,_r])
		false
	end

end