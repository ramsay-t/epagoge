defmodule Epagoge.GeneticProgrammingTest do
  use ExUnit.Case
	alias Epagoge.Exp, as: Exp
	alias Epagoge.GeneticProgramming, as: GenProg

	setup_all do
		:net_adm.world()
		peasants = Enum.map(:lists.seq(1,20), fn(_) -> :sk_peasant.start() end)
		on_exit(fn() ->
								Enum.map(peasants, fn(peasant) -> send peasant, :terminate end)
						end)
	end


	defp dset1 do
		[
		 %{r1: 1, o1: 2},
		 %{r1: 4, o1: 5},
		 %{r1: 0, o1: 1},
		 %{r1: 1100, o1: 1101}
		]
	end

	test "Simple increment" do
		exp = GenProg.infer(dset1, :o1)
		assert (exp == {:plus, {:v,:r1}, {:lit, 1}}
						or
						exp == {:plus, {:lit, 1}, {:v,:r1}})
	end

	defp dset2 do
		[
		 %{r1: 1, i1: 1, o1: 2},
		 %{r1: 5, i1: 5, o1: 10},
		 %{r1: 5, i1: 2, o1: 7},
		 %{r1: 5, i1: 1, o1: 6},
		 %{r1: 33, i1: 88, o1: 121},
		]
	end

	test "Simple sum" do
		exp = GenProg.infer(dset2, :o1)
		assert (exp == {:plus, {:v,:r1}, {:v, :i1}}
						or
						exp == {:plus, {:v, :i1}, {:v,:r1}})
	end

	defp calc(data) do
		Map.put(data,:o1,(data[:r1] + data[:r2]) / data[:i1])
	end
	
	def make_dset(f) do
		Enum.map(:lists.seq(1,100), 
										fn(_) -> 
												d = %{}
												d = Map.put(d,:r1,:random.uniform(100))
												d = Map.put(d,:r2,:random.uniform(100))
												d = Map.put(d,:i1,:random.uniform(100))
												d = Map.put(d,:rlast1,:random.uniform(100))
												f.(d)
										end)
	end

	defp check(exp,target,f) do
		dset2 = make_dset(f)
		av = Enum.sum(Enum.map(dset2, fn(data) -> 
																			{comp,_newdata} = Exp.eval(exp,data) 
																			if comp == data[target] do 0 else 1 end
																	end)) / length(dset2)
		score = 1 / (1 + av)
		assert score > 0.8
	end

	@tag timeout: 300000
	test "More complex calc" do
		dset = make_dset(&calc/1)
		exp = GenProg.infer(dset, :o1,[{:pop_size,50},{:thres,1.0}])
		#:io.format("For (r1 + r2) / i1, Made: ~p~n",[Exp.pp(exp)])
		check(exp,:o1,&calc/1)
		# Arg! Algebra!!
		assert (exp == {:divide, {:plus, {:v,:r1}, {:v, :r2}}, {:v,:i1}}
						or
						exp == {:divide, {:plus, {:v,:r2}, {:v, :r1}}, {:v,:i1}}
						or
						exp == {:plus, {:divide, {:v,:r1}, {:v,:i1}},{:divide,{:v,:r2},{:v,:i1}}}
						or
						exp == {:plus, {:divide, {:v,:r2}, {:v,:i1}},{:divide,{:v,:r1},{:v,:i1}}})
	end

	defp classifier1(data) do
		Map.put(data,:possible,(data[:i1] > 10))
	end
	
	@tag timeout: 300000
	test "Boolean decision" do
		dset = make_dset(&classifier1/1)
		exp = GenProg.infer(dset, :possible, [{:pop_size,50},{:thres,1.0}])
		av = Enum.sum(Enum.map(dset, fn(data) -> 
														{comp,_newdata} = Exp.eval(exp,data) 
														if comp == data[:possible] do 0 else 1 end
												end)) / length(dset)
		score = 1 / (1 + av) 
		assert score == 1.0
		check(exp,:possible,&classifier1/1)
	end

	def hardclassifier(data) do
		Map.put(data,:possible,((data[:i1] > 75) or (data[:r1] < 50)))
	end

	defp dset3 do
		[
		 %{r1: 50, i1: 50, o1: 100, possible: true},
		 %{r1: 50, i1: 20, o1: 70, possible: false},
		 %{r1: 90, i1: 10, o1: 100, possible: true},
		 %{r1: 90, i1: 50, o1: 140, possible: true},
		 %{r1: 20, i1: 20, o1: 40, possible: false},
		 %{r1: 90, i1: 5, o1: 95, possible: false},
		 %{r1: 5, i1: 90, o1: 95, possible: false},
		 %{r1: 70, i1: 20, o1: 90, possible: false}
		]
	end

	defp numclassifier(data) do
		Map.put(data,:possible,((data[:i1] + data[:r1]) >= 100))
  end

	@tag timeout: 300000
	test "Numerical Boolean decision" do
		#dset = make_dset(&numclassifier/1)
		exp = GenProg.infer(dset3, :possible, [{:pop_size,50},{:thres,1.0}])
		#:io.format("Num: ~p~n",[Epagoge.Exp.pp(exp)])
		check(exp,:possible,&numclassifier/1)
	end

	defp simplenumclassifier(data) do
		Map.put(data,:possible,data[:rlast1] >= 100)
	end
	defp dset4() do
		[
		 %{rlast1: 100, o1: "coke", possible: true},
		 %{rlast1: 120, o1: "coke", possible: true},
		 %{rlast1: 110, o1: "coke", possible: true},
		 %{rlast1: 100, o1: "pepsi", possible: true},
		 %{rlast1: 110, o1: "pepsi", possible: true},
		 %{rlast1: 90, o1: "coke", possible: false},
		 %{rlast1: 45, o1: "coke", possible: false}
		]
	end

	@tag timeout: 300000
	test "Simple Numerical Boolean decision" do
		#dset = make_dset(&numclassifier/1)
		exp = GenProg.infer(dset4, :possible, [{:pop_size,50},{:thres,1.0}])
		#:io.format("Simple Num: ~p~n",[Epagoge.Exp.pp(exp)])
		check(exp,:possible,&simplenumclassifier/1)
	end


#	@tag timeout: 300000
#	test "Hard boolean decision" do
#		dset = make_dset(&hardclassifier/1)
#		exp = GenProg.infer(dset, :possible, [{:pop_size,30},{:thres,1.0}])
#		#:io.format("Made ~p~n",[Exp.pp(exp)])
#		av = Enum.sum(Enum.map(dset, fn(data) -> 
#																		 {comp,_newdata} = Exp.eval(exp,data) 
#																		 if comp == data[:possible] do 0 else 1 end
#																 end)) / length(dset)
#		score = 1 / (1 + av)
#		assert score == 1.0
#		# Unfortunately, the classifier is often more complex but algebraicaly equivilent,
#		# so we can't test the actual structure. However, we can test its score over another
#		# sample and it should be reasonably predictive...
#		check(exp,:possible,&hardclassifier/1)
#	end

end