defmodule Epagoge.Subsumption do
	alias Epagoge.Exp, as: Exp

	def subsumes?([],_r) do
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
			String.ends_with?(rpre,lpre) and String.starts_with?(rsuf,lsuf)
		end
	end
	defp subsumes_case({:match,_pre,_suf,{:v,tgt}}=l,{:eq,{:v,tgt},{:lit,val}}) do
		{t,_} = Exp.eval(l,Map.put(%{},tgt,val))
		t
	end
	# Nothing except matching can subsume a match
	defp subsumes_case(_,{:match,_,_,_}) do
		false
	end

	# Get subsumption is identical to match subsumption
	defp subsumes_case({:get,p1,s1,tgt},{:get,p2,s2,tgt}) do
		subsumes?({:match,p1,s1,tgt},{:match,p2,s2,tgt})
	end
	# Special case - assignment from src is equivilent to get("","",src)
	defp subsumes_case({:assign,tgt,src},{:assign,tgt,{:get,_,_,src}}) do
		true
	end
	defp subsumes_case({:assign,tgt,{:get,p1,s1,src}},{:assign,tgt,{:get,p2,s2,src}}) do
		subsumes?({:match,p1,s1,tgt},{:match,p2,s2,tgt})
	end
	defp subsumes_case({:assign,_t1,_s1},{:assign,_t2,{:get,_,_,_s2}}) do
		false
	end
	defp subsumes_case({:get,_,_,_},_) do
		false
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
	defp subsumes_case({:gt,_t1,_},{:gt,_t2,_}) do
		false
	end
	defp subsumes_case({:lt,_t1,_},{:lt,_t2,_}) do
		false
	end
	defp subsumes_case({:ge,_t1,_},{:ge,_t2,_}) do
		false
	end
	defp subsumes_case({:le,_t1,_},{:le,_t2,_}) do
		false
	end

	defp subsumes_case({:eq,_t1,_},{:le,_t2,_}) do
		false
	end
	defp subsumes_case({:eq,_t1,_},{:lt,_t2,_}) do
		false
	end
	defp subsumes_case({:eq,_t1,_},{:ge,_t2,_}) do
		false
	end
	defp subsumes_case({:eq,_t1,_},{:gt,_t2,_}) do
		false
	end

	# Assignments
	# The only thing an assignment can subsume is an assignment with a subsumed source expression
	# and identical target
	defp subsumes_case({:assign,tgt,src1},{:assign,tgt,src2}) do
		subsumes?(src1,src2)
	end
	defp subsumes_case({:assign,_,_},_) do
		false
	end

	# Concat
	defp subsumes_case({:concat,{:lit,pre},rest},{:lit,val}) do
		if String.starts_with?(val,pre) do
			subsumes?(rest,{:lit,String.slice(val,String.length(pre),String.length(val))})
		else
			false
		end
	end
	defp subsumes_case({:concat,rest,{:lit,suf}},{:lit,val}) do
		if String.ends_with?(val,suf) do
			subsumes?(rest,{:lit,String.slice(val,String.length(val)-String.length(suf),String.length(val))})
		else
			false
		end
	end
	defp subsumes_case({:concat,{:lit,pre},rest},{:concat,{:lit,pre2},rest2}) do
		if String.starts_with?(pre2,pre) do
			subsumes?(rest,{:concat,{:lit,String.slice(pre2,String.length(pre),String.length(pre2))},rest2})
		else
			false
		end
	end
	defp subsumes_case({:concat,rest,{:lit,suf}},{:concat,rest2,{:lit,suf2}}) do
		if String.ends_with?(suf2,suf) do
			subsumes?(rest,{:concat,rest2,{:lit,String.slice(suf2,0,String.length(suf2)-String.length(suf))}})
		else
			false
		end
	end
	defp subsumes_case({:v,_},{:concat,_,_}) do
		true
	end

	defp subsumes_case(_l,_r) do
		#raise to_string(:io_lib.format("Fell through subsumption: ~p vs ~p~n",[_l,_r]))
		#:io.format("Fell through subsumption: ~p vs ~p~n",[_l,_r])
		false
	end
end