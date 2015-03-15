defmodule Epagoge.Simp do
	alias Epagoge.Exp, as: Exp

	def make_bin(type,index) do
		<<type :: size(2),index :: size(14)>> 
	end
	
	def display_bin(<<a :: size(1),b :: size(1),c :: size(1),d :: size(1),e :: size(1),f :: size(1),g :: size(1),h :: size(1),i :: size(1),j :: size(1),k :: size(1),l :: size(1),m :: size(1),n :: size(1),o :: size(1),p :: size(1),>>) do
		[a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p]
	end

	def type_code(:ll) do 0 end
	def type_code(:lv) do 1 end
	def type_code(:prop) do 2 end
	def type_code(:op) do 3 end

	def op_code(:conj) do 0 end
	def op_code(:disj) do 1 end
	def op_code(:gr) do 2 end
	def op_code(:ge) do 3 end
	def op_code(:lt) do 4 end
	def op_code(:le) do 5 end
	def op_code(:eq) do 6 end
	def op_code(:plus) do 7 end
	def op_code(:minus) do 8 end
	def op_code(:multiply) do 9 end
	def op_code(:divide) do 10 end

	# Convert a potentially tree structured proposition into a list of props, with {:prop,index} insertions
	@spec tsetin(Exp.t) :: list({:prop,integer} | {:v,String.t} | {:lit, String.t})
	def tsetin({op,a1,a2}) do
		subs = []
		case a1 do
			{:lv,_name} ->
				a1p = a1
			{:ll,_val} ->				
				a1p = a1
			{:v,_name} ->
				a1p = a1
			{:lit,_val} ->				
				a1p = a1
			_ ->
				a1p = {:prop, 1}
				subs = increment_props(1,tsetin(a1))
		end
		case a2 do
			{:lv,_name} ->
				a2p = a2
			{:ll,_val} ->				
				a2p = a2
			{:v,_name} ->
				a2p = a2
			{:lit,_val} ->				
				a2p = a2
			_ ->
				a2p = {:prop,length(subs)+1}
				subs = subs ++ increment_props(length(subs)+1,tsetin(a2))
		end
		[{op,a1p,a2p} | subs]
	end

	defp increment_props(_,[]) do
		[]
	end
	defp increment_props(count,[{op,a1,a2} | more]) do
		[{op,increment_arg(count,a1),increment_arg(count,a2)} | increment_props(count,more)]
	end
	defp increment_props(count,[something | more]) do
		[something | increment_props(count,more)]
	end

	defp increment_arg(count,{:prop,n}) do
		{:prop,n+count}
	end
	defp increment_arg(_,other) do
		other
	end

	# Replaces vars with lv (labeled vars) and produces an enumerated list of variables
	def label_vars(prop) do
		label(:v,:lv,prop,[])
	end
	# Replaces lits with ll (labeled lits) and produces an enumerated list of literals
	def label_lits(prop) do
		# The null literal is always first, so it will become 0x0000
		label(:lit,:ll,prop,[{0,nil}])
	end

	defp label(tag,newtag,{tag,val},keys) do
		case List.keyfind(keys,val,1) do
			{n,^val} ->
				{{newtag,n},keys}
			nil ->
				idx = length(keys)
				{{newtag,idx},keys ++ [{idx,val}]}
		end
	end
	defp label(tag,newtag,{nottag,val},keys) do
		{newval,newkeys} = label(tag,newtag,val,keys)
		{{nottag,newval},newkeys}
	end
	defp label(tag,newtag,{op,a1,a2},keys) do
		{a1p,keys1} = label(tag,newtag,a1,keys)
		{a2p,keys2} = label(tag,newtag,a2,keys1)
		{{op,a1p,a2p},keys2}
	end
	defp label(_tag,_newtag,val,keys) do
		{val,keys}
	end

	def prop_to_bin(prop) do
		{p1,lits} = label_lits(prop)
		{p2,vars} = label_vars(p1)
		p = tsetin(p2)
		{Enum.map(p,&item_to_bin/1),vars,lits}
	end

	defp item_to_bin(nil) do <<0,0>> end
	defp item_to_bin({type,idx}) do
		make_bin(type_code(type),idx)
	end
	defp item_to_bin({op,a1,a2}) do
		make_bin(type_code(:op),op_code(op)) <> item_to_bin(a1) <> item_to_bin(a2)
	end

	def make_patterns(lits) do
		[make_pattern({:conj,{:lit,"false"},:any},lits),
		 make_pattern({:conj,:any,{:lit,"false"}},lits)]
	end

	defp make_pattern({op,a1,:any},lits) do
		{<<255,255,255,255,0,0>>,
		 make_bin(type_code(:op),op_code(op)) <> arg_to_pat(a1,lits) <> <<0,0>>,
		<<0,3,0,0,0,0>>}
	end
	defp make_pattern({op,:any,a2},lits) do
		{<<255,255,0,0,255,255>>,
		 make_bin(type_code(:op),op_code(op)) <> <<0,0>> <> arg_to_pat(a2,lits),
		<<0,3,0,0,0,0>>}
	end

	defp arg_to_pat({:lit,l1},lits) do
		case List.keyfind(lits,l1,1) do
			{n,^l1} ->
				make_bin(type_code(:ll),n)
			nil ->
				throw l1 <> " not in lits! " <> to_string(lits)
		end
	end

	def gpu_convert(prop) do
		{ps,vs,ls} = prop_to_bin(prop)
		pats = make_patterns(ls)
		{{ps,pats},{vs,ls}}
	end

end