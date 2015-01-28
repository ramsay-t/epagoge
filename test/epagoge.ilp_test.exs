defmodule Epagoge.ILPTest do
  use ExUnit.Case
	alias Epagoge.ILP, as: ILP

	defp p1 do
		{:conj,{:lt,{:v,:r1},{:lit,"6"}},{:gr,{:v,:r2},{:lit,"9"}}}
	end

	defp p2 do
		{:disj,
		 {:conj,{:lt,{:v,:r1},{:lit,"4"}},{:gr,{:v,:r2},{:lit,"3"}}},
		 {:conj,{:lt,{:v,:r1},{:lit,"2"}},{:gr,{:v,:r2},{:lit,"11"}}}
		}
	end

	#test "Numeric generalisation" do
	#	assert ILP.generalise([p1,p2]) == {:lit,"fixme"}
	#end

	test "String joins" do
		# No constraint
		assert ILP.join({:eq,{:v,:i1},{:lit,"coke"}},{:eq,{:v,:i1},{:lit,"pepsi"}}) == {:match,"","",:i1}
		assert ILP.join({:eq,{:v,:i1},{:lit,"key=coke;"}},{:eq,{:v,:i1},{:lit,"key=pepsi;"}}) == {:match,"key=",";",:i1}
		assert ILP.join({:match,"key=",";",:i1},{:match,"y=","",:i1}) == {:match,"y=","",:i1}
		assert ILP.join({:match,"abc","def",:i1},{:match,"xyz","pqr",:i1}) == nil
		assert ILP.join({:match,"","",:i1},{:match,"","",:i1}) == {:match,"","",:i1}
		assert catch_error(ILP.join({:match,"","",:i1},{:match,"","",:i2})) == %ArgumentError{message: "Unsupported join: {match,<<>>,<<>>,i1} with {match,<<>>,<<>>,i2}"}
	end
	
end
