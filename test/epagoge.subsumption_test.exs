defmodule Epagoge.SubsumptionTest do
  use ExUnit.Case
	alias Epagoge.Subsumption, as: Subsumption

	test "Subsumption by variable" do
		assert Subsumption.subsumes?({:v,:r1},{:lit,"coke"}) == true
	end

	test "Subsumption of literals" do
		assert Subsumption.subsumes?({:lit,"coke"},{:lit,"pepsi"}) == false
		assert Subsumption.subsumes?({:lit,"coke"},{:lit,"coke"}) == true
	end

	test "Equality subsumption" do
		assert Subsumption.subsumes?({:eq,{:v,:r1},{:v,:r2}},{:eq,{:lit,1},{:lit,2}}) == true
		assert Subsumption.subsumes?({:eq,{:v,:r1},{:v,:r2}},{:eq,{:v,:r1},{:lit,2}}) == true
		assert Subsumption.subsumes?({:eq,{:v,:r1},{:v,:r2}},{:eq,{:lit,1},{:v,:r2}}) == true
		assert Subsumption.subsumes?({:eq,{:v,:r1},{:v,:r2}},{:eq,{:lit,1},{:v,:r1}}) == false
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
		assert Subsumption.subsumes?({:match,"c","e",{:v,:r1}},{:match,"cj","je",{:v,:r1}}) == true
		assert Subsumption.subsumes?({:match,"c","e",{:v,:r1}},{:match,"c","ej",{:v,:r1}}) == false
		assert Subsumption.subsumes?({:match,"c","e",{:v,:r1}},{:match,"jc","e",{:v,:r1}}) == false
		assert Subsumption.subsumes?({:match,"c","e",{:v,:r1}},{:match,"j","j",{:v,:r1}}) == false
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
		assert Subsumption.subsumes?([{:eq,{:v,:r1},{:v,:r2}}],[{:eq,{:lit,1},{:v,:r1}}]) == false
		assert Subsumption.subsumes?([
																	{:eq,{:v,:r1},{:v,:r2}},
																	{:eq,{:v,:r1},{:v,:r2}},
																	{:eq,{:v,:r1},{:v,:r2}}
																	],[
																		 {:eq,{:lit,1},{:lit,2}},
																		 {:eq,{:v,:r1},{:lit,2}},
																		 {:eq,{:lit,1},{:v,:r2}}
																]) == true
	end

	test "Subsumption of numerics" do
		assert Subsumption.subsumes?({:eq,{:v,:i1},{:lit,4}},{:ge,{:v,:i1},{:lit,3}}) == true
		assert Subsumption.subsumes?({:eq,{:v,:i1},{:lit,4}},{:ge,{:v,:i1},{:lit,4}}) == true
		assert Subsumption.subsumes?({:eq,{:v,:i1},{:lit,4}},{:ge,{:v,:i1},{:lit,5}}) == false
		assert Subsumption.subsumes?({:ge,{:v,:i1},{:lit,4}},{:eq,{:v,:i1},{:lit,5}}) == false

		assert Subsumption.subsumes?({:eq,{:v,:i1},{:lit,4}},{:gt,{:v,:i1},{:lit,3}}) == true
		assert Subsumption.subsumes?({:eq,{:v,:i1},{:lit,4}},{:gt,{:v,:i1},{:lit,4}}) == false
		assert Subsumption.subsumes?({:eq,{:v,:i1},{:lit,4}},{:gt,{:v,:i1},{:lit,5}}) == false
		assert Subsumption.subsumes?({:gt,{:v,:i1},{:lit,4}},{:eq,{:v,:i1},{:lit,5}}) == false

		assert Subsumption.subsumes?({:eq,{:v,:i1},{:lit,4}},{:le,{:v,:i1},{:lit,3}}) == false
		assert Subsumption.subsumes?({:eq,{:v,:i1},{:lit,4}},{:le,{:v,:i1},{:lit,4}}) == true
		assert Subsumption.subsumes?({:eq,{:v,:i1},{:lit,4}},{:le,{:v,:i1},{:lit,5}}) == true
		assert Subsumption.subsumes?({:le,{:v,:i1},{:lit,4}},{:eq,{:v,:i1},{:lit,5}}) == false

		assert Subsumption.subsumes?({:eq,{:v,:i1},{:lit,4}},{:lt,{:v,:i1},{:lit,3}}) == false
		assert Subsumption.subsumes?({:eq,{:v,:i1},{:lit,4}},{:lt,{:v,:i1},{:lit,4}}) == false
		assert Subsumption.subsumes?({:eq,{:v,:i1},{:lit,4}},{:lt,{:v,:i1},{:lit,5}}) == true
		assert Subsumption.subsumes?({:lt,{:v,:i1},{:lit,4}},{:eq,{:v,:i1},{:lit,5}}) == false
	end

end
