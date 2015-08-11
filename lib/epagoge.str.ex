defmodule Epagoge.Str do

	@doc """
  Supplied with a list of pairs containing a string and a substring from that string, get_match computes the 
  longest prefix and suffix that is common to all of the pairs.
  """
	@spec get_match(list({String.t,String.t})) :: {String.t,String.t}
	def get_match([]) do
		nil
	end
	def get_match([{v,v}]) do
		{"",""}
	end
	def get_match([{v,v} | more]) do
		# When the content is the entirety this is a) easy and b) breaks z3str
		if get_match(more) == {"",""} do
			{"",""}
		else
			nil
		end
	end
	def get_match([{v,nv}]) do
		calc_match(v,nv)
	end

	def get_match([{v,nv} | more]) do
		{p1,s1} = calc_match(v,nv)
		{p2,s2} = get_match(more)
		{gcs(p1,p2),gcp(s1,s2)}
	end

	defp calc_match(v,nv) do
		make_match("",nv,v)
	end
	defp make_match(pre,_cont,"") do
		{pre,""}
	end
	defp make_match(pre,cont,nil) do
		{pre,""}
	end
	defp make_match(pre,cont,rest) do
		if String.starts_with?(rest,cont) do
			# Yes, I know length(rest) is too big, but that will still work and it
			# saves the double computation of length cont and the arithmetic etc.
			{pre,String.slice(rest,String.length(cont),String.length(rest))}
		else
			make_match(pre <> String.at(rest,0),cont,String.slice(rest,1,String.length(rest)))
		end
	end

#	def get_match(pairs) do
#		{z3file,count} = List.foldl(pairs,
#												{"(declare-variable pre String)\n(declare-variable suf String)\n",0},
#												fn({str,cont},{acc,vn}) ->
#														vnum = to_string(vn+1)
#														{acc <> "(declare-variable p" <> vnum <> " String)\n" <> 
#														 "(declare-variable beg" <> vnum <> " String)\n" <>
#														 "(declare-variable end" <> vnum <> " String)\n" <>
#														 "(declare-variable v" <> vnum <> " String)\n" <>
#														 "(assert (= p" <> vnum <> " \"" <> str <> "\"))\n" <>
#														 "(assert (= p" <> vnum <> " (Concat beg" <> vnum <> " (Concat pre (Concat v" <> vnum <> " (Concat suf end" <> vnum <> "))))))\n" <>
#														 "(assert (= (- 0 1) (Indexof v" <> vnum <> " suf)))\n" <>
#														 "(assert (= (- 0 1) (Indexof beg" <> vnum <> " pre)))\n" <>
#														 "(assert (= v" <> vnum <> " \"" <> cont <>"\"))\n",
#														 vn+1}
#												end)
#		z3file = z3file <> "(assert (=> (= (Length pre) 0) " <> make_length_zero("beg",count) <> "))\n" <> "(assert (=> (= (Length suf) 0) " <> make_length_zero("end",count) <> "))\n"
#		IO.puts z3file
#		z3res = Epagoge.EZ3Str.runZ3Str(z3file)
#		case z3res[:SAT] do
#			true ->
#				{z3res[:pre],z3res[:suf]}
#			_ ->
#				:io.format("Z3 returned ~p~n",[z3res])
#				nil
#		end
#	end

#	defp make_length_zero(pre,0) do
#		""
#	end
#	defp make_length_zero(pre,n) do
#		case make_length_zero(pre,n-1) do
#			"" ->
#				"(= (Length " <> pre <> to_string(n) <> ") 0)"
#			more ->
#				"(and (= (Length " <> pre <> to_string(n) <> ") 0) " <> more <> ")"
#		end
#	end

	@doc """
  Finds all the substrings that are present in both strings.
  """
	@spec common_substrings(String.t,String.t) :: list(String.t)
	def common_substrings("",_) do
		[]
	end
	def common_substrings(_,"") do
		[]
	end
	def common_substrings(s1,s2) do
		sss = get_common_substrings(s1,s2) ++ get_common_substrings(s2,s1)
		filtered = Enum.filter(sss,fn({_,n1,n2,len}) -> 
																	 # Irrelevant if we could expand either way and still have a substring
																	 Enum.all?(sss,fn ({_,n1p,n2p,_}) -> not ((n1p == (n1-1)) and (n2p == (n2-1))) end)
																	 and
																	 Enum.all?(sss,fn ({_,n1p,n2p,lenp}) -> not ((n1p == n1) and (n2p == n2) and (lenp > len)) end)
															 end)
		Enum.uniq(Enum.map(filtered,fn({s,_,_,_}) -> s end))
	end

	defp get_common_substrings("",_) do
		[]
	end
	defp get_common_substrings(_,"") do 
		[]
	end
	defp get_common_substrings(s1,s2) do
		case largest_substring(s1,s2,min(String.length(s1),String.length(s2))) do
			false ->
				get_common_substrings(String.slice(s1,1,String.length(s1)),s2)
			{ss,n,m,len} ->
				[{ss,n,m,len} | get_common_substrings(String.slice(s1,n,String.length(s1)),s2)]
		end
	end

	defp largest_substring(_,_,0) do
		false
	end
	defp largest_substring(s1,s2,n) do
		ss = String.slice(s1,0,n)
		case :binary.match(s2,[ss]) do
			:nomatch -> 
				largest_substring(s1,s2,n-1)
			{start,len} ->
				{ss,n,start,len}
		end
	end
	
	@doc """
  Compute the Greatest Common Suffix.
  """
	@spec gcs(String.t,String.t) :: String.t
	def gcs("",_) do
		""
	end
	def gcs(_,"") do
		""
	end
	def gcs(s1,s2) do
		{p1,l1} = String.split_at(s1,-1)
		{p2,l2} = String.split_at(s2,-1)
		if l1 == l2 do
			gcs(p1,p2) <> l1
		else
			""
		end
	end

	@doc """
  Compute the Greatest Common Prefix.
  """
	@spec gcp(String.t,String.t) :: String.t
	def gcp("",_) do
		""
	end
	def gcp(_,"") do
		""
	end
	def gcp(s1,s2) do
		{p1,l1} = String.split_at(s1,1)
		{p2,l2} = String.split_at(s2,1)
		if p1 == p2 do
			p1 <> gcp(l1,l2)
		else
			""
		end
	end

end
