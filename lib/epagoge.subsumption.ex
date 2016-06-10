defmodule Epagoge.Subsumption do
	@moduledoc """
  Subsumption defines a partial ordering for expressions where P subsumes Q if it makes sense to consider
  Q to be an 'instance of' the more general statement made by P. 

  This is often the inverse of implication, so if Q -> P then P subsumes Q. For example, x > 3 subsumes x = 4.

  However, it also includes other generalisations. Specifically, variables always subsume literals, so
  x = r1 subsumes x = 4. This is important for many of the applications of subsumption that want to 
  produce statements that accept more possibilities, but it means that you cannot use subsumption as
  the inverse of implication.
  """

	alias Epagoge.Exp, as: Exp

	@doc """
  The subsumes? predicate computes whether the first parameter subsumes the second parameter.
   """
	def subsumes?([],_r) do
		# Emptylist can be read as "no restrictions", so it is just 'true' and subsumes everything
		true
	end
	def subsumes?(_,[]) do
		# Conversly, anything restrictive can't subsume true
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
	# Variables are more general than values
	# This is an example of subsumption not always being the inverse of implication!
	defp subsumes_case({:v,_},{:lit,_}) do
		true
	end

	defp subsumes_case({:v,lname},{:v,rname}) do
		lname == rname
	end
	defp subsumes_case({:lit,l1},{:lit,l2}) do
		l1 == l2
	end

	# FIXME: should this be commutative?
	defp subsumes_case({:eq,ll,lr},{:eq,rl,rr}) do
		(subsumes_case(ll,rl) and subsumes_case(lr,rr))
		or
		(subsumes_case(ll,rr) and subsumes_case(lr,rl))
	end

  # Match expression subsuption
	defp subsumes_case({:match,lpre,lsuf,lt},{:match,rpre,rsuf,rt}) do
		if lt != rt do
			false
		else 
			p = case {rpre,lpre} do
						{"",""} -> true
						{"",_} -> false
						{_,""} -> true
						_ -> String.ends_with?(rpre,lpre)
					end
			s = case {rsuf,lsuf} do
						{"",""} -> true
						{"",_} -> false
						{_,""} -> true
						_ -> String.starts_with?(rsuf,lsuf)
					end
			p and s
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
	defp subsumes_case({:get,p1,s1,tgt},{:eq,tgt,{:lit,str}}=r) do
		subsumes?({:match,p1,s1,tgt},r)
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

	# Since subsumption is a matter of generalisation, if we take the
	# two halves of the conjunction and they each subsume the 
	# right hand expression then there are no contradictions 
	# and we can accept the total subsumption..
	defp subsumes_case({:conj,l,r}=le,{:conj,l2,r2}=re) do
		subsumes_case(l,re) and subsumes_case(r,re)
	end
	defp subsumes_case({:conj,l,r},o) do
		subsumes_case(l,o) and subsumes_case(r,o)
	end
	defp subsumes_case(o,{:conj,l,r}) do
		subsumes_case(o,l) or subsumes_case(o,r)
	end

	# Some numeric cases that get less restrictive
	defp subsumes_case({:ge,tgt,{:lit,lval}},{:ge,tgt,{:lit,rval}}) do
		lval <= rval
	end
	defp subsumes_case({:ge,tgt,{:lit,lval}},{:eq,tgt,{:lit,eqval}}) do
		eqval >= lval
	end

	defp subsumes_case({:le,tgt,{:lit,lval}},{:le,tgt,{:lit,rval}}) do
		lval >= rval
	end
	defp subsumes_case({:le,tgt,{:lit,lval}},{:eq,tgt,{:lit,eqval}}) do
		eqval <= lval
	end

	defp subsumes_case({:gr,tgt,{:lit,lval}},{:gr,tgt,{:lit,rval}}) do
		lval <= rval
	end
	defp subsumes_case({:gr,tgt,{:lit,lval}},{:eq,tgt,{:lit,eqval}}) do
		eqval > lval
	end

	defp subsumes_case({:lt,tgt,{:lit,lval}},{:lt,tgt,{:lit,rval}}) do
		lval >= rval
	end
	defp subsumes_case({:lt,tgt,{:lit,lval}},{:eq,tgt,{:lit,eqval}}) do
		eqval < lval
	end
	# In other cases we don't know how to check...



	# Numeric generalisations
	defp subsumes_case({:lt,v,{:lit,x}},{:eq,v,{:lit,y}}) do
		y < x
	end
	defp subsumes_case({:lt,_,_},{:eq,_,_}) do
		false
	end
	defp subsumes_case({:gr,v,{:lit,x}},{:eq,v,{:lit,y}}) do
		y > x
	end
	defp subsumes_case({:gr,_,_},{:eq,_,_}) do
		false
	end
	defp subsumes_case({:le,v,{:lit,x}},{:eq,v,{:lit,y}}) do
		y <= x
	end
	defp subsumes_case({:le,_,_},{:eq,_,_}) do
		false
	end
	defp subsumes_case({:ge,v,{:lit,x}},{:eq,v,{:lit,y}}) do
		y >= x
	end
	defp subsumes_case({:ge,_,_},{:eq,_,_}) do
		false
	end
	

	defp subsumes_case({:lt,_,_},{:gr,_,_}) do
		false
	end
	defp subsumes_case({:gr,_,_},{:lt,_,_}) do
		false
	end
	
	# Mismatched targets or non-literal values
	defp subsumes_case({:gr,_t1,_},{:gr,_t2,_}) do
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
	defp subsumes_case({:eq,_t1,_},{:gr,_t2,_}) do
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