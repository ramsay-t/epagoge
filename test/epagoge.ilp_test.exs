defmodule Epagoge.ILPTest do
  use ExUnit.Case
	alias Epagoge.ILP, as: ILP
#	alias Epagoge.Exp, as: Exp

#	defp p1 do
#		{:conj,{:lt,{:v,:r1},{:lit,"6"}},{:gr,{:v,:r2},{:lit,"9"}}}
#	end

#	defp p2 do
#		{:disj,
#		 {:conj,{:lt,{:v,:r1},{:lit,"4"}},{:gr,{:v,:r2},{:lit,"3"}}},
#		 {:conj,{:lt,{:v,:r1},{:lit,"2"}},{:gr,{:v,:r2},{:lit,"11"}}}
#		}
#	end

	#test "Numeric generalisation" do
	#	:io.format("~p~n~p~n",[Exp.pp(p1),Exp.pp(p2)])
	#	assert ILP.generalise([p1,p2]) == :fixme
	#end

	test "String joins" do
		# No constraint
		assert ILP.join({:eq,{:v,:i1},{:lit,"coke"}},{:eq,{:v,:i1},{:lit,"pepsi"}}) == {:match,"","",{:v,:i1}}
		assert ILP.join({:eq,{:v,:i1},{:lit,"key=coke;"}},{:eq,{:v,:i1},{:lit,"key=pepsi;"}}) == {:match,"key=",";",{:v,:i1}}
		assert ILP.join({:match,"key=",";",{:v,:i1}},{:match,"y=","",{:v,:i1}}) == {:match,"y=","",{:v,:i1}}
		assert ILP.join({:match,"abc","def",{:v,:i1}},{:match,"xyz","pqr",{:v,:i1}}) == nil
		assert ILP.join({:match,"","",{:v,:i1}},{:match,"","",{:v,:i1}}) == {:match,"","",{:v,:i1}}
		assert catch_error(ILP.join({:match,"","",{:v,:i1}},{:match,"","",{:v,:i2}})) == %ArgumentError{message: "Unsupported join: {match,<<>>,<<>>,{v,i1}} with {match,<<>>,<<>>,{v,i2}}"}

		assert ILP.join({:match,"cc","e",{:v,:i1}},{:match,"c","ee",{:v,:i1}}) == {:match,"c","e",{:v,:i1}}

	end
	
	test "Simplifying boolean expressions" do
		assert ILP.simplify([]) == []
		assert ILP.simplify([{:conj,{:lit,true},{:lit,true}}]) == []
		assert ILP.simplify([{:conj,{:lit,true},{:eq,{:v,:i1},{:lit,4}}}]) == [{:eq,{:v,:i1},{:lit,4}}]
		assert ILP.simplify([{:conj,{:eq,{:v,:i1},{:lit,4}},{:eq,{:v,:i1},{:lit,4}}}]) == [{:eq,{:v,:i1},{:lit,4}}]
		assert ILP.simplify([{:eq,{:v,:i1},{:lit,4}},{:eq,{:v,:i1},{:lit,4}}]) == [{:eq,{:v,:i1},{:lit,4}}]
		assert ILP.simplify({:conj,{:ge,{:v,:i1},{:lit,4}},{:eq,{:v,:i1},{:lit,4}}}) == {:eq,{:v,:i1},{:lit,4}}
		assert ILP.simplify([{:conj,{:ge,{:v,:i1},{:lit,4}},{:ge,{:v,:i1},{:lit,6}}}]) == [{:ge,{:v,:i1},{:lit,4}}]
		assert ILP.simplify([{:ge,{:v,:i1},{:lit,4}},{:ge,{:v,:i1},{:lit,6}}]) == [{:ge,{:v,:i1},{:lit,4}}]
		assert ILP.simplify({:conj,{:ge,{:v,:i1},{:lit,4}},{:eq,{:v,:i12},{:lit,4}}}) == 
								 {:conj,{:ge,{:v,:i1},{:lit,4}},{:eq,{:v,:i12},{:lit,4}}}
	end

	test "Simplifying stacked conjunctions" do
		assert ILP.simplify({:conj,{:eq,{:v,:i1},{:lit,4}},{:conj,{:ge,{:v,:i1},{:lit,4}},{:ge,{:v,:i1},{:lit,2}}}}) == 
								 {:eq,{:v,:i1},{:lit,4}}
		assert ILP.simplify([{:eq,{:v,:i1},{:lit,4}},{:ge,{:v,:i1},{:lit,4}},{:ge,{:v,:i1},{:lit,2}}]) ==
								 [{:eq,{:v,:i1},{:lit,4}}]
		assert ILP.simplify([{:ge,{:v,:i1},{:lit,4}},{:eq,{:v,:i1},{:lit,4}},{:ge,{:v,:i1},{:lit,2}}]) ==
								 [{:eq,{:v,:i1},{:lit,4}}]
		assert ILP.simplify([{:ge,{:v,:i1},{:lit,4}},{:ge,{:v,:i1},{:lit,2}},{:eq,{:v,:i1},{:lit,4}}]) ==
								 [{:eq,{:v,:i1},{:lit,4}}]
	end

	test "Simplifying matches" do
		assert ILP.simplify([{:eq,{:v,:i1},{:lit,"coke"}},{:match,"c","e",{:v,:i1}}]) == [{:match,"c","e",{:v,:i1}}] 
		assert ILP.simplify([{:match,"","",{:v,:i1}},{:eq,{:v,:i1},{:lit,"coke"}}]) == [] 
		assert ILP.simplify([{:eq,{:v,:i1},{:lit,"coke"}},{:match,"","",{:v,:i1}}]) == [] 
		assert ILP.simplify([{:match,"c","e",{:v,:i1}},{:match,"cc","e",{:v,:i1}}]) == [{:match,"c","e",{:v,:i1}}] 
		assert ILP.simplify([{:match,"cc","e",{:v,:i1}},{:match,"c","e",{:v,:i1}}]) == [{:match,"c","e",{:v,:i1}}] 
		assert ILP.simplify([{:match,"c","ee",{:v,:i1}},{:match,"cc","e",{:v,:i1}}]) == [{:match,"c","e",{:v,:i1}}] 
		assert ILP.simplify([{:match,"c","e",{:v,:i1}},{:match,"c","ee",{:v,:i1}}]) == [{:match,"c","e",{:v,:i1}}] 
	end

	test "Simplifying subsumptive lists" do
		assert ILP.simplify([
												 {:assign,:o1,{:lit,"{ok,10}"}},
												 {:assign,:o1,{:concat,{:v,:r2},{:lit,"0}"}}}
												 ]) == 
								 [{:assign,:o1,{:concat,{:v,:r2},{:lit,"0}"}}}]
	end

	test "Simplifying common examples" do
		assert ILP.simplify({:eq,{:lit,"hello"},{:lit,"hello"}}) == {:lit,true}
		assert ILP.simplify({:eq,{:lit,"hello"},{:lit,"goodby"}}) == {:lit,false}
		assert ILP.simplify({:eq,{:v,:x},{:v,:x}}) == {:lit,true}
		assert ILP.simplify({:ne,{:ne,{:v,:r1},{:lit,"wine"}},{:eq,{:v,:r1},{:lit,"beer"}}}) == 
								 {:conj,
									{:ne,{:v,:r1},{:lit,"wine"}},
									{:ne,{:v,:r1},{:lit,"beer"}}
								 }
	end

	test "Literal simplifications" do
		assert ILP.simplify({:plus, {:lit, 1}, {:lit, 2}}) == {:lit, 3} 
		assert ILP.simplify({:minus, {:lit, 1}, {:lit, 2}}) == {:lit, -1} 
		assert ILP.simplify({:multiply, {:lit, 1}, {:lit, 2}}) == {:lit, 2} 
		assert ILP.simplify({:divide, {:lit, 1}, {:lit, 2}}) == {:lit, 0.5} 
	end

	test "Non-numeric simplifications shouldn't break" do
		assert ILP.simplify({:plus,{:lit,"1"},{:lit,"2"}}) == {:plus,{:lit,"1"},{:lit,"2"}}
		assert ILP.simplify({:minus,{:lit,"1"},{:lit,"2"}}) == {:minus,{:lit,"1"},{:lit,"2"}}
		assert ILP.simplify({:multiply,{:lit,"1"},{:lit,"2"}}) == {:multiply,{:lit,"1"},{:lit,"2"}}
		assert ILP.simplify({:divide,{:lit,"1"},{:lit,"2"}}) == {:divide,{:lit,"1"},{:lit,"2"}}
	end

	test "Inverse" do
		assert ILP.inverse({:lit, false}) == {:lit, true}
		assert ILP.inverse({:lit, true}) == {:lit, false}
		assert ILP.inverse({:nt, {:v, :r1}}) == {:v, :r1}
		assert ILP.inverse({:v, :r1}) == {:nt,{:v, :r1}}
	end

	test "Some conjunctive and disjunctive simplifications" do
		assert ILP.simplify({:conj,{:v,:r1},{:nt,{:v,:r1}}}) == {:lit, false}
		assert ILP.simplify({:disj,{:v,:r1},{:nt,{:v,:r1}}}) == {:lit, true}
		assert ILP.simplify({:conj,{:eq,{:lit,"beer"},{:v,:r1}},{:ne,{:v,:r1},{:lit,"beer"}}}) == {:lit, false}
		assert ILP.simplify({:disj,{:eq,{:lit,"beer"},{:v,:r1}},{:ne,{:v,:r1},{:lit,"beer"}}}) == {:lit, true}
	end

	test "Some things that have been known to be non-terminal..." do
		ILP.simplify({:le,{:v,:i1},{:eq,{:v,:r2},{:v,:i1}}})
		assert true
	end

end
