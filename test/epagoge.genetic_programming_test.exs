defmodule Epagoge.GeneticProgrammingTest do
  use ExUnit.Case
	alias Epagoge.Exp, as: Exp
	alias Epagoge.GeneticProgramming, as: GenProg

	setup_all do
		IO.puts "Setting up worker pool..."
		:net_adm.world()
		peasants = Enum.map(:lists.seq(1,10), fn(_) -> :sk_peasant.start() end)
		on_exit(fn() ->
								IO.puts "Terminating workers..."
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
	
	defp make_dset(f) do
		Enum.map(:lists.seq(1,100), 
										fn(_) -> 
												d = %{}
												d = Map.put(d,:r1,:random.uniform(100))
												d = Map.put(d,:r2,:random.uniform(100))
												d = Map.put(d,:i1,:random.uniform(100))
												f.(d)
										end)
	end

	@tag timeout: 120000
	test "More complex calc" do
		dset = make_dset(&calc/1)
		exp = GenProg.infer(dset, :o1,[{:pop_size,30},{:thres,1.0}])
		#:io.format("For (r1 + r2) / i1, Made: ~p~n",[Exp.pp(exp)])
		# Arg! Algebra!!
		assert (exp == {:divide, {:plus, {:v,:r1}, {:v, :r2}}, {:v,:i1}}
						or
						exp == {:plus, {:divide, {:v,:r1}, {:v,:i1}},{:divide,{:v,:r2},{:v,:i1}}}
						or
						exp == {:plus, {:divide, {:v,:r2}, {:v,:i1}},{:divide,{:v,:r1},{:v,:i1}}})
	end

	defp classifier1(data) do
		Map.put(data,:possible,(data[:i1] > 10))
	end
	
	@tag timeout: 120000
	test "Boolean decision" do
		dset = make_dset(&classifier1/1)
		exp = GenProg.infer(dset, :possible, [{:pop_size,30},{:thres,1.0}])
		av = Enum.sum(Enum.map(dset, fn(data) -> 
														{comp,_newdata} = Exp.eval(exp,data) 
														if comp == data[:possible] do 0 else 1 end
												end)) / length(dset)
		score = 1 / (1 + av) 
		assert score == 1.0
		# Allow a small delta for the small sample size...
		case exp do
			{:gr,{:v,:i1},{:lit,cut}} ->
				assert_in_delta(8,12,cut)
			{:ge,{:v,:i1},{:lit,cut}} ->
				assert_in_delta(9,13,cut)
		end
	end

end