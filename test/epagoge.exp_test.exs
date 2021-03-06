defmodule Epagoge.ExpTest do
  use ExUnit.Case
	alias Epagoge.Exp, as: Exp

	defp bind1 do
		%{:x1 => "coke", :x2 => "100", :x3 => "1.1"}
	end
	defp bind2 do
		%{:x => true}
	end

	test "String equality" do
		assert Exp.eval({:eq,{:v,:x1},{:lit,"coke"}},bind1) == {true,bind1}
	end

	test "Int equality with parsing" do
		assert Exp.eval({:eq,{:v,:x2},{:lit,100}},bind1) == {true,bind1}
	end

	test "Float equality with parsing" do
		assert Exp.eval({:eq,{:v,:x3},{:lit,1.1}},bind1) == {true,bind1}
	end

	test "Logical not" do
		assert Exp.eval({:nt,{:eq,{:v,:x3},{:lit,1.1}}},bind1) == {false,bind1}
		assert Exp.eval({:nt,{:eq,{:v,:x3},{:lit,36}}},bind1) == {true,bind1}
	end

	test "Logical conjunction and disjunction" do
		assert Exp.eval({:conj,{:eq,{:v,:x},{:lit,true}},{:lit,true}},bind2) == {true,bind2}
		assert Exp.eval({:conj,{:eq,{:v,:x},{:lit,false}},{:lit,true}},bind2) == {false,bind2}
		assert Exp.eval({:conj,{:eq,{:v,:x},{:lit,true}},{:lit,false}},bind2) == {false,bind2}
		assert Exp.eval({:disj,{:eq,{:v,:x},{:lit,true}},{:lit,true}},bind2) == {true,bind2}
		assert Exp.eval({:disj,{:eq,{:v,:x},{:lit,false}},{:lit,true}},bind2) == {true,bind2}
		assert Exp.eval({:disj,{:eq,{:v,:x},{:lit,false}},{:lit,false}},bind2) == {false,bind2}
	end

	test "Ne is just not eq" do
		assert Exp.eval({:ne,{:v,:x1},{:v,:x2}},bind1) == Exp.eval({:nt,{:eq,{:v,:x1},{:v,:x2}}},bind1)
		assert Exp.eval({:ne,{:v,:x3},{:lit,1.1}},bind1) == {false,bind1}
		assert Exp.eval({:ne,{:v,:x3},{:lit,36}},bind1) == {true,bind1}
	end

	test "Numerical comparison" do
		assert Exp.eval({:gr,{:v,:x2},{:lit,100}},bind1) == {false,bind1}
		assert Exp.eval({:ge,{:v,:x2},{:lit,100}},bind1) == {true,bind1}
		assert Exp.eval({:lt,{:v,:x2},{:lit,100}},bind1) == {false,bind1}
		assert Exp.eval({:le,{:v,:x2},{:lit,100}},bind1) == {true,bind1}
	end

	test "Comparison not defined over strings" do
		assert Exp.eval({:gr,{:lit,"coke"},{:lit,"coke"}},bind1) == {:undefined,bind1}
		assert Exp.eval({:ge,{:lit,"coke"},{:lit,"coke"}},bind1) == {:undefined,bind1}
		assert Exp.eval({:lt,{:lit,"coke"},{:lit,"coke"}},bind1) == {:undefined,bind1}
		assert Exp.eval({:le,{:lit,"coke"},{:lit,"coke"}},bind1) == {:undefined,bind1}
	end

	test "Assignment" do
		assert Exp.eval({:assign,:x4,{:lit,"test"}},bind1) == {"test",%{:x1 => "coke", :x2 => "100", :x3 => "1.1", :x4 => "test"}}
		assert Exp.eval({:assign,:x4,{:v,:x1}},bind1) == {"coke",%{:x1 => "coke", :x2 => "100", :x3 => "1.1", :x4 => "coke"}}
	end

	test "No side effects in logic" do
		assert Exp.eval({:nt,{:eq,{:v,:x1},{:assign,:x4,{:lit,"coke"}}}},bind1) == {false,bind1}
	end
	test "Nested assignment evaluates but doesn't stick" do
		assert Exp.eval({:assign,:x4,{:assign,:x5,{:v,:x1}}},bind1) == {"coke",%{:x1 => "coke", :x2 => "100", :x3 => "1.1", :x4 => "coke"}}
	end

	test "Pretty print" do
		assert Exp.pp({:assign,:x1,{:nt,{:gr,{:v,:x2},{:lit,"coke"}}}}) == "x1 := " <> << 172 :: utf8 >> <> "(x2 > \"coke\")"
		assert Exp.pp({:assign,:x1,{:nt,{:v,:x2}}}) == "x1 := " <> << 172 :: utf8 >> <> "x2"
		assert Exp.pp({:eq,{:ne,{:ge,{:lit,7},{:lit,9}},{:lit,true}},{:eq,{:le,{:lit,4},{:lit,6}},{:lt,{:lit,6},{:lit,8}}}}) == "((7 >= 9) != true) = ((4 =< 6) = (6 < 8))"
		assert Exp.pp({:plus,{:v,:r1},{:minus,{:v,:r2},{:lit,1}}}) == "r1 + (r2 - 1)"
		assert Exp.pp({:multiply,{:v,:r1},{:divide,{:v,:r2},{:lit,2}}}) == "r1 * (r2 / 2)"
		assert Exp.pp({:conj,{:lit,true},{:disj,{:nt,{:v,:r1}},{:v,:r2}}}) == "true ^ (" <> << 172 :: utf8 >> <> "r1 v r2)"
	end

	test "Aritmetic" do
		assert Exp.eval({:plus,{:lit,2},{:lit,2}},%{}) == {4,%{}}
		assert Exp.eval({:minus,{:lit,2},{:lit,2}},%{}) == {0,%{}}
		assert Exp.eval({:divide,{:lit,2},{:lit,2}},%{}) == {1,%{}}
		assert Exp.eval({:multiply,{:lit,2},{:lit,2}},%{}) == {4,%{}}
	end

	test "Aritmetic over variables" do
		assert Exp.eval({:plus,{:v,:r1},{:v,:i1}},%{:r1 => 4, :i1 => 6}) == {10,%{:r1 => 4, :i1 => 6}}
		assert Exp.eval({:minus,{:v,:r1},{:v,:i1}},%{:r1 => 4, :i1 => 6}) == {-2,%{:r1 => 4, :i1 => 6}}
		assert Exp.eval({:divide,{:v,:r1},{:v,:i1}},%{:r1 => 4, :i1 => 6}) == {(4/6),%{:r1 => 4, :i1 => 6}}
		assert Exp.eval({:multiply,{:v,:r1},{:v,:i1}},%{:r1 => 4, :i1 => 6}) == {24,%{:r1 => 4, :i1 => 6}}
	end

	test "Arithmetic over unknowns" do
		assert Exp.eval({:plus,{:v,:r1},{:v,:i1}},%{:r1 => 4, :x1 => 6}) == {:undefined,%{:r1 => 4, :x1 => 6}}
	end

	test "String concatenation" do
		assert Exp.eval({:concat,{:lit,"Hello,"},{:lit, " World!"}},%{}) == 
								 {"Hello, World!",%{}}
		assert Exp.eval({:concat,{:lit,"Hello,"},{:v, :r1}},%{:r1 => " World!"}) == 
								 {"Hello, World!",%{:r1 => " World!"}}
		assert Exp.eval({:concat,{:lit,"Total: "},{:plus,{:v, :r1},{:v, :r2}}},%{:r1 => 4, :r2 => "6"}) == 
								 {"Total: 10",%{:r1 => 4, :r2 => "6"}}
	end

	test "Concat has no side effects" do
		assert Exp.eval({:concat,{:lit,"Total: "},{:assign,:r1,{:lit,7}}},%{:r1 => 6}) == {"Total: 7",%{:r1 => 6}}
	end

	test "Eval match" do
		assert Exp.eval({:match,"key=",";",{:v,:i1}},
										%{:i1 => "wiblewobblenoise;key=abc;morenoisekkkee"}) == 
								 {true,%{:i1 => "wiblewobblenoise;key=abc;morenoisekkkee"}}
		assert Exp.eval({:match,"co","e",{:v,:i1}},
										%{:i1 => "wiblewobblenoise;key=abc;morenoisekkkee"}) == 
								 {false,%{:i1 => "wiblewobblenoise;key=abc;morenoisekkkee"}}
	end

	test "Eval get" do
		assert Exp.eval({:get,"key=",";",{:v,:i1}},
										%{:i1 => "wiblewobblenoise;key=abc;morenoisekkkee"}) == 
								 {"abc",%{:i1 => "wiblewobblenoise;key=abc;morenoisekkkee"}}
		assert Exp.eval({:get,"co","e",{:v,:i1}},
										%{:i1 => "wiblewobblenoise;key=abc;morenoisekkkee"}) == 
								 {nil,%{:i1 => "wiblewobblenoise;key=abc;morenoisekkkee"}}
		assert Exp.eval({:get,"co","e",{:v,:i1}},%{}) == {nil,%{}}
		assert Exp.eval({:get,"key=",";session=ok;",{:v,:o1}},%{o1: "key=abc;session=ok;"}) == {"abc",%{o1: "key=abc;session=ok;"}}
		assert Exp.eval({:get,"key=","suf",{:v,:o1}},%{o1: "suf;key=abcsuf;session=ok;"}) == {"abc",%{o1: "suf;key=abcsuf;session=ok;"}}
		assert Exp.eval({:get,"k","",{:v,:i1}},%{i1: "k=abc"}) == {"=abc",%{i1: "k=abc"}}
	end

	test "Pretty print concat" do
		assert Exp.pp({:concat,{:lit,"Hello,"},{:lit, " World!"}}) == "\"Hello,\" <> \" World!\""
	end

	test "Pretty print match and get" do
		assert Exp.pp({:match,"key=",";",{:v,:i1}}) == "match(\"key=\",\";\",i1)"
		assert Exp.pp({:get,"key=",";",{:v,:i1}}) == "get(\"key=\",\";\",i1)" 

		assert Exp.pp({:eq,{:v,:i1},{:match,"key=",";",{:v,:i1}}}) == "i1 = match(\"key=\",\";\",i1)"
		assert Exp.pp({:assign,:r1,{:get,"key=",";",{:v,:i1}}}) == "r1 := get(\"key=\",\";\",i1)" 
		
	end

	test "Trivial and non-trivial expressions" do
		assert Exp.trivial?({:lit,5}) == true
		assert Exp.trivial?({:v,:r1}) == true
		assert Exp.trivial?({:eq,{:lit,6},{:lit,7}}) == false
	end

	test "Free variables" do
		assert Exp.freevars({:conj,{:nt,{:v,:r1}},{:lt,{:v,:r2},{:v,:r3}}}) == [:r1,:r2,:r3]
		assert Exp.freevars({:eq, {:v, :i1}, {:lit, "coke"}}) == [:i1]
		assert Exp.freevars({:assign, :o1, {:lit, "coke"}}) == [:o1]
	end

	test "Aritmetic undefined over boolean" do
		assert Exp.eval({:multiply, {:lit, false}, {:lit, false}},%{}) == {:undefined,%{}}
		assert Exp.eval({:divide, {:lit, false}, {:lit, false}},%{}) == {:undefined,%{}}
		assert Exp.eval({:plus, {:lit, false}, {:lit, false}},%{}) == {:undefined,%{}}
		assert Exp.eval({:minus, {:lit, false}, {:lit, false}},%{}) == {:undefined,%{}}

		assert Exp.eval({:multiply, {:v, :r1}, {:v, :r2}},%{r1: false, r2: false}) == {:undefined,%{r1: false, r2: false}}
		assert Exp.eval({:divide, {:v, :r1}, {:v, :r2}},%{r1: false, r2: false}) == {:undefined,%{r1: false, r2: false}}
		assert Exp.eval({:plus, {:v, :r1}, {:v, :r2}},%{r1: false, r2: false}) == {:undefined,%{r1: false, r2: false}}
		assert Exp.eval({:minus, {:v, :r1}, {:v, :r2}},%{r1: false, r2: false}) == {:undefined,%{r1: false, r2: false}}
	end

	test "Boolean expresions over undefined are undefined" do
		assert Exp.eval({:nt,{:disj,{:lit,false},{:plus,{:lit,true},{:lit,true}}}},%{}) == {:undefined,%{}}
		assert Exp.eval({:nt,{:conj,{:lit,true},{:plus,{:lit,true},{:lit,true}}}},%{}) == {:undefined,%{}}
		# bizarrely, the elixir 'and' and 'or' operators work for when applied to (bool,atom)
		# and return the atom, but they don't work when applied to (atom,bool)...
		assert Exp.eval({:nt,{:disj,{:plus,{:lit,true},{:lit,true}},{:lit,false}}},%{}) == {:undefined,%{}}
		assert Exp.eval({:nt,{:conj,{:plus,{:lit,true},{:lit,true}},{:lit,true}}},%{}) == {:undefined,%{}}
	end

end
