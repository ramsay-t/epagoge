defmodule Epagoge.SubsumptionTest do
  use ExUnit.Case
	alias Epagoge.Subsumption, as: Subsumption

	test "Subsumption by variable" do
		assert Subsumption.subsumes?({:v,:r1},{:lit,"coke"}) == true
		
		assert Subsumption.subsumes?({:lit,true},{:eq,{:v,:r1},{:lit,4}}) == true
		assert Subsumption.subsumes?([],[{:eq,{:v,:r1},{:lit,4}}]) == true
	end

	test "Subsumption of literals" do
		assert Subsumption.subsumes?({:lit,"coke"},{:lit,"pepsi"}) == false
		assert Subsumption.subsumes?({:lit,"coke"},{:lit,"coke"}) == true
	end

	test "Equality subsumption" do
		assert Subsumption.subsumes?({:eq,{:v,:r1},{:v,:r2}},{:eq,{:lit,1},{:lit,2}}) == true
		assert Subsumption.subsumes?({:eq,{:v,:r1},{:v,:r2}},{:eq,{:v,:r1},{:lit,2}}) == true
		assert Subsumption.subsumes?({:eq,{:v,:r1},{:v,:r2}},{:eq,{:lit,1},{:v,:r2}}) == true
		assert Subsumption.subsumes?({:eq,{:v,:r1},{:v,:r2}},{:eq,{:lit,1},{:v,:r1}}) == true
		assert Subsumption.subsumes?({:eq,{:v,:r1},{:v,:r2}},{:eq,{:v,:r3},{:v,:r1}}) == false
	end

	test "Subsumption between matches" do
		assert Subsumption.subsumes?({:match,"c","e",{:v,:r1}},{:match,"cc","ee",{:v,:r1}}) == true
		assert Subsumption.subsumes?({:match,"cc","ee",{:v,:r1}},{:match,"c","ee",{:v,:r1}}) == false
		assert Subsumption.subsumes?({:match,"cc","ee",{:v,:r1}},{:match,"cc","e",{:v,:r1}}) == false
		assert Subsumption.subsumes?({:match,"cc","ee",{:v,:r1}},{:match,"c","e",{:v,:r1}}) == false
		assert Subsumption.subsumes?({:match,"cc","ee",{:v,:r1}},{:match,"c","ee",{:v,:r2}}) == false
		assert Subsumption.subsumes?({:match,"cc","e",{:v,:r1}},{:match,"c","ee",{:v,:r1}}) == false
		assert Subsumption.subsumes?({:match,"c","ee",{:v,:r1}},{:match,"cc","e",{:v,:r1}}) == false
		assert Subsumption.subsumes?({:match,"j","e",{:v,:r1}},{:match,"c","e",{:v,:r1}}) == false
		assert Subsumption.subsumes?({:match,"c","j",{:v,:r1}},{:match,"c","e",{:v,:r1}}) == false
		assert Subsumption.subsumes?({:match,"","e",{:v,:r1}},{:match,"c","e",{:v,:r1}}) == true
		assert Subsumption.subsumes?({:match,"c","",{:v,:r1}},{:match,"c","e",{:v,:r1}}) == true
		assert Subsumption.subsumes?({:match,"","",{:v,:r1}},{:match,"c","e",{:v,:r1}}) == true

		assert Subsumption.subsumes?({:match,"c","e",{:v,:r1}},{:match,"cj","ej",{:v,:r1}}) == false
		assert Subsumption.subsumes?({:match,"c","e",{:v,:r1}},{:match,"jc","ej",{:v,:r1}}) == true
		assert Subsumption.subsumes?({:match,"c","e",{:v,:r1}},{:match,"c","ej",{:v,:r1}}) == true
		assert Subsumption.subsumes?({:match,"c","e",{:v,:r1}},{:match,"jc","e",{:v,:r1}}) == true
		assert Subsumption.subsumes?({:match,"c","e",{:v,:r1}},{:match,"j","j",{:v,:r1}}) == false

		assert Subsumption.subsumes?({:match,"y=",";",{:v,:r1}},{:match,"key=",";",{:v,:r1}}) == true
	end

	test "Matches subsume literals" do
		assert Subsumption.subsumes?({:match,"c","e",{:v,:r1}},{:eq,{:v,:r1},{:lit,"coke"}}) == true
		assert Subsumption.subsumes?({:match,"o","e",{:v,:r1}},{:eq,{:v,:r1},{:lit,"coke"}}) == true
		assert Subsumption.subsumes?({:match,"c","e",{:v,:r1}},{:eq,{:v,:r1},{:lit,"pepsi"}}) == false
		assert Subsumption.subsumes?({:match,"ep","s",{:v,:r1}},{:eq,{:v,:r1},{:lit,"pepsi"}}) == true
	end

	test "Subsumption over lists" do
		assert Subsumption.subsumes?([],[]) == true
		assert Subsumption.subsumes?([],[{:eq,{:v,:r1},{:v,:r2}}]) == true
		assert Subsumption.subsumes?([{:eq,{:v,:r1},{:v,:r2}}],[]) == false
		assert Subsumption.subsumes?([{:eq,{:v,:r1},{:v,:r2}}],[{:eq,{:lit,1},{:lit,2}}]) == true
		assert Subsumption.subsumes?([{:eq,{:v,:r1},{:v,:r2}}],[{:eq,{:v,:r1},{:lit,2}}]) == true
		assert Subsumption.subsumes?([{:eq,{:v,:r1},{:v,:r2}}],[{:eq,{:lit,1},{:v,:r2}}]) == true
		assert Subsumption.subsumes?([{:eq,{:v,:r1},{:v,:r2}}],[{:eq,{:lit,1},{:v,:r1}}]) == true
		assert Subsumption.subsumes?([{:eq,{:v,:r1},{:v,:r2}}],[{:eq,{:v,:r3},{:v,:r1}}]) == false
		assert Subsumption.subsumes?([
																	{:eq,{:v,:r1},{:v,:r2}},
																	{:eq,{:v,:r1},{:v,:r2}},
																	{:eq,{:v,:r1},{:v,:r2}}
																	],[
																		 {:eq,{:lit,1},{:lit,2}},
																		 {:eq,{:v,:r1},{:lit,2}},
																		 {:eq,{:lit,1},{:v,:r2}}
																]) == true
		assert Subsumption.subsumes?([{:eq,{:v,:r1},{:v,:r2}}],
																 [{:eq,{:v,:r1},{:v,:r2}},{:eq,{:v,:r2},{:v,:r3}}]) == true
	end

	test "Conjunction subsumption" do
		assert Subsumption.subsumes?({:eq,{:v,:r1},{:v,:r2}},
																 {:conj,
																	{:eq,{:v,:r1},{:v,:r2}},
																	{:eq,{:v,:r2},{:v,:r3}}
																 }) == true
		assert Subsumption.subsumes?({:eq,{:v,:r1},{:v,:r2}},
																 {:conj,
																	{:eq,{:v,:r2},{:v,:r3}},
																	{:eq,{:v,:r1},{:v,:r2}}
																 }) == true
		assert Subsumption.subsumes?({:conj,
																	{:eq,{:v,:r2},{:v,:r3}},
																	{:eq,{:v,:r1},{:v,:r2}}
																 },
																 {:eq,{:v,:r1},{:v,:r2}}) == false

		assert Subsumption.subsumes?({:conj,
																	{:eq,{:v,:i1},{:lit,1}},
																	{:conj,
																	 {:eq,{:v,:i2},{:lit,2}},
																	 {:eq,{:v,:n},{:lit,"n"}}
																	}
																 },
																 {:conj,
																	{:eq,{:v,:i1},{:lit,1}},
																	{:eq,{:v,:n},{:lit,"n"}}
																}) == false
		
		assert Subsumption.subsumes?({:conj,
																	{:eq,{:v,:i1},{:lit,1}},
																	{:eq,{:v,:n},{:lit,"n"}}},
																 {:conj,
																	{:eq,{:v,:i1},{:lit,1}},
																	{:conj,
																	 {:eq,{:v,:n},{:lit,"n"}},
																	 {:eq,{:v,:i2},{:lit,2}}
																	}
																}) == true

		assert Subsumption.subsumes?([{:eq,{:v,:i1},{:lit,1}},
																	{:eq,{:v,:n},{:lit,"n"}}],
																 [{:eq,{:v,:i1},{:lit,1}},
																	{:eq,{:v,:i2},{:lit,2}},
																	{:eq,{:v,:n},{:lit,"n"}}]) == true

		assert Subsumption.subsumes?([{:eq,{:v,:i1},{:lit,1}},
																	{:eq,{:v,:i2},{:lit,2}},
																	{:eq,{:v,:n},{:lit,"n"}}],
																 [{:eq,{:v,:i1},{:lit,1}},
																	{:eq,{:v,:n},{:lit,"n"}}]) == false

	end

	test "Subsumption of numerics" do
		assert Subsumption.subsumes?({:ge,{:v,:i1},{:lit,3}},{:eq,{:v,:i1},{:lit,4}}) == true
		assert Subsumption.subsumes?({:ge,{:v,:i1},{:lit,4}},{:eq,{:v,:i1},{:lit,4}}) == true
		assert Subsumption.subsumes?({:ge,{:v,:i1},{:lit,5}},{:eq,{:v,:i1},{:lit,4}}) == false
		assert Subsumption.subsumes?({:eq,{:v,:i1},{:lit,5}},{:ge,{:v,:i1},{:lit,5}}) == false

		assert Subsumption.subsumes?({:gr,{:v,:i1},{:lit,3}},{:eq,{:v,:i1},{:lit,4}}) == true
		assert Subsumption.subsumes?({:gr,{:v,:i1},{:lit,4}},{:eq,{:v,:i1},{:lit,4}}) == false
		assert Subsumption.subsumes?({:gr,{:v,:i1},{:lit,5}},{:eq,{:v,:i1},{:lit,4}}) == false
		assert Subsumption.subsumes?({:eq,{:v,:i1},{:lit,5}},{:gr,{:v,:i1},{:lit,4}}) == false

		assert Subsumption.subsumes?({:le,{:v,:i1},{:lit,3}},{:eq,{:v,:i1},{:lit,4}}) == false
		assert Subsumption.subsumes?({:le,{:v,:i1},{:lit,4}},{:eq,{:v,:i1},{:lit,4}}) == true
		assert Subsumption.subsumes?({:le,{:v,:i1},{:lit,5}},{:eq,{:v,:i1},{:lit,4}}) == true
		assert Subsumption.subsumes?({:eq,{:v,:i1},{:lit,5}},{:le,{:v,:i1},{:lit,4}}) == false

		assert Subsumption.subsumes?({:lt,{:v,:i1},{:lit,3}},{:eq,{:v,:i1},{:lit,4}}) == false
		assert Subsumption.subsumes?({:lt,{:v,:i1},{:lit,4}},{:eq,{:v,:i1},{:lit,4}}) == false
		assert Subsumption.subsumes?({:lt,{:v,:i1},{:lit,5}},{:eq,{:v,:i1},{:lit,4}}) == true
		assert Subsumption.subsumes?({:eq,{:v,:i1},{:lit,5}},{:lt,{:v,:i1},{:lit,4}}) == false

		assert Subsumption.subsumes?({:gr,{:v,:r1},{:lit,3}},{:gr,{:v,:r1},{:lit,6}}) == true
		assert Subsumption.subsumes?({:gr,{:v,:r1},{:lit,6}},{:gr,{:v,:r1},{:lit,3}}) == false

		assert Subsumption.subsumes?({:ge,{:v,:r1},{:lit,3}},{:ge,{:v,:r1},{:lit,6}}) == true
		assert Subsumption.subsumes?({:ge,{:v,:r1},{:lit,6}},{:ge,{:v,:r1},{:lit,6}}) == true
		assert Subsumption.subsumes?({:ge,{:v,:r1},{:lit,6}},{:ge,{:v,:r1},{:lit,3}}) == false

		assert Subsumption.subsumes?({:lt,{:v,:r1},{:lit,6}},{:lt,{:v,:r1},{:lit,3}}) == true
		assert Subsumption.subsumes?({:lt,{:v,:r1},{:lit,3}},{:lt,{:v,:r1},{:lit,6}}) == false

		assert Subsumption.subsumes?({:le,{:v,:r1},{:lit,6}},{:le,{:v,:r1},{:lit,3}}) == true
		assert Subsumption.subsumes?({:le,{:v,:r1},{:lit,6}},{:le,{:v,:r1},{:lit,6}}) == true
		assert Subsumption.subsumes?({:le,{:v,:r1},{:lit,3}},{:le,{:v,:r1},{:lit,6}}) == false

	end

	test "Get subsumption" do
		# This is more extensively tested in assignments and matches, since get subsumption is
		# identical to match subsumption and implemented as such
		assert Subsumption.subsumes?({:get,"","",{:v,:i1}},{:get,"key=",";",{:v,:i1}}) == true
		assert Subsumption.subsumes?({:get,"","",{:v,:i1}},{:get,"key=",";",{:v,:i2}}) == false

		assert Subsumption.subsumes?({:get,"key=",";",{:v,:i1}},{:get,"key=",";",{:v,:i1}}) == true
		assert Subsumption.subsumes?({:get,"y=",";",{:v,:i1}},{:get,"key=",";",{:v,:i1}}) == true
		assert Subsumption.subsumes?({:get,"key=",";",{:v,:i1}},{:get,"y=",";",{:v,:i1}}) == false
	end

	test "Subsumption over updates/assignments" do
		assert Subsumption.subsumes?({:assign,:r1,{:v,:i1}},{:assign,:r1,{:v,:i1}}) == true

		assert Subsumption.subsumes?({:assign,:r1,{:v,:i1}},{:assign,:r1,{:get,"","",{:v,:i1}}}) == true
		assert Subsumption.subsumes?({:assign,:r1,{:v,:i1}},{:assign,:r1,{:get,"","",{:v,:i2}}}) == false
		assert Subsumption.subsumes?({:assign,:r2,{:v,:i1}},{:assign,:r1,{:get,"","",{:v,:i1}}}) == false

		assert Subsumption.subsumes?({:assign,:r1,{:v,:i1}},{:assign,:r1,{:get,"key=",";",{:v,:i1}}}) == true
		assert Subsumption.subsumes?({:assign,:r1,{:get,"","",{:v,:i1}}},{:assign,:r1,{:get,"key=",";",{:v,:i1}}}) == true
		assert Subsumption.subsumes?({:assign,:r1,{:get,"y=",";",{:v,:i1}}},{:assign,:r1,{:get,"key=",";",{:v,:i1}}}) == true
		assert Subsumption.subsumes?({:assign,:r1,{:get,"key=",";",{:v,:i1}}},{:assign,:r1,{:get,"y=",";",{:v,:i1}}}) == false

		assert Subsumption.subsumes?({:assign,:r1,{:v,:i1}},{:assign,:r1,{:v,:i2}}) == false

	end

	test "Concat subsumption" do
		assert Subsumption.subsumes?({:assign,:r1,{:concat,{:lit,"tr"},{:v,:i1}}},{:assign,:r1,{:lit,"true"}}) == true
		assert Subsumption.subsumes?({:assign,:r1,{:concat,{:v,:i1},{:lit,"ue"}}},{:assign,:r1,{:lit,"true"}}) == true
		assert Subsumption.subsumes?({:assign,:r1,{:concat,{:lit,"t"},{:v,:i1}}},{:assign,:r1,{:concat,{:lit,"tr"},{:v,:i1}}}) == true
		assert Subsumption.subsumes?({:assign,:r1,{:concat,{:v,:i1},{:lit,"e"}}},{:assign,:r1,{:concat,{:v,:i1},{:lit,"ue"}}}) == true
	end

	test "Get subsumption over literal equations" do
		assert Subsumption.subsumes?({:get,"k=",";",{:v,:r1}},{:eq,{:v,:r1},{:lit,"k=abc;"}}) == true
		assert Subsumption.subsumes?({:get,"k=",";",{:v,:r1}},{:eq,{:v,:r1},{:lit,"jabc;"}}) == false
		assert Subsumption.subsumes?({:get,"k=",";",{:v,:r1}},{:eq,{:v,:r1},{:lit,"k=abc"}}) == false
		assert Subsumption.subsumes?({:get,"k","",{:v,:r1}},{:eq,{:v,:r1},{:lit,"k=abc;"}}) == true
		assert Subsumption.subsumes?({:get,"","",{:v,:r1}},{:eq,{:v,:r1},{:lit,"k=abc;"}}) == true
	end

	test "More Subsumption over conjunctions" do
		e1 = {:eq, {:v, :a}, {:lit, 1}}
		e2 = {:conj, e1, {:eq, {:v, :b}, {:lit, 2}}}
		e3 = {:conj, e2, {:eq, {:v, :c}, {:lit, 3}}}
		e4 = {:conj, e1, {:eq, {:v, :b}, {:lit, 3}}}
		assert Subsumption.subsumes?(e1,e2) == true
		assert Subsumption.subsumes?(e2,e3) == true
		assert Subsumption.subsumes?(e1,e4) == true
		assert Subsumption.subsumes?(e2,e4) == false
		assert Subsumption.subsumes?(e4,e3) == false

		e5 = {:gr, {:v, :a}, {:lit, 0}}
		e6 = {:conj, e5, {:eq, {:v, :b}, {:lit, 2}}}

		assert Subsumption.subsumes?(e5,e1) == true
		assert Subsumption.subsumes?(e5,e6) == true
		assert Subsumption.subsumes?(e6,e4) == false

		e7 = {:conj, e5, {:eq, {:v, :b}, {:lit, 3}}}

		assert Subsumption.subsumes?(e5,e7) == true
		assert Subsumption.subsumes?(e7,e4) == true
		assert Subsumption.subsumes?(e6,e7) == false
	end

	test "Subsumption of mismatched equalities" do
		assert Subsumption.subsumes?({:eq,{:v,:i2},{:lit,"{2,0}"}},{:eq,{:v,:i2},{:lit,"{3,0}"}}) == false
		# Test list mismatch in one instance but not the other
		assert Subsumption.subsumes?([{:eq,{:v,:i1},{:lit,"tab"}},{:eq,{:v,:i2},{:lit,"{2,0}"}}],
																 [{:eq,{:v,:i1},{:lit,"tab"}},{:eq,{:v,:i2},{:lit,"{3,0}"}}]) == false
	end

end
