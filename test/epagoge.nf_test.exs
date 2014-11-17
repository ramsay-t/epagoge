defmodule Epagoge.NFTest do
  use ExUnit.Case
	alias Epagoge.NF, as: NF

	defp p1 do
		{:disj,{:conj,{:v,:r1},{:v,:r2}},{:eq,{:v,:r3},{:lit,4}}}
	end

	defp p2 do
		{:conj,{:disj,{:v,:r1},{:v,:r2}},{:eq,{:v,:r3},{:lit,4}}}
	end

	defp p3 do
		{:conj,{:disj,{:v,:r1},{:v,:r2}},{:disj,{:v,:r3},{:v,:r4}}}
	end
	
	defp p4 do
		{:disj,{:conj,{:v,:r1},{:v,:r2}},{:conj,{:v,:r3},{:v,:r4}}}
	end
	
	defp p5 do
		{:nt,{:conj,{:disj,{:v,:r1},{:v,:r2}},{:disj,{:v,:r3},{:v,:r4}}}}
	end
	
	test "Not distribution" do
		assert NF.dnf({:nt,{:conj,{:v,:r1},{:v,:r2}}}) == {:disj,{:nt,{:v,:r1}},{:nt,{:v,:r2}}}
		assert NF.dnf({:nt,{:disj,{:v,:r1},{:v,:r2}}}) == {:conj,{:nt,{:v,:r1}},{:nt,{:v,:r2}}}
		assert NF.cnf({:nt,{:conj,{:v,:r1},{:v,:r2}}}) == {:disj,{:nt,{:v,:r1}},{:nt,{:v,:r2}}}
		assert NF.cnf({:nt,{:disj,{:v,:r1},{:v,:r2}}}) == {:conj,{:nt,{:v,:r1}},{:nt,{:v,:r2}}}
	end

	test "Disjunctive Normal Form" do
		assert NF.dnf(p1) == p1
		assert NF.dnf(p2) == {:disj,
													{:conj,{:v,:r1},{:eq,{:v,:r3},{:lit,4}}},
													{:conj,{:v,:r2},{:eq,{:v,:r3},{:lit,4}}}
												 }
		assert NF.dnf(p3) ==
								{:disj,
								 {:disj,{:conj,{:v,:r1},{:v,:r3}},{:conj,{:v,:r1},{:v,:r4}}},
								 {:disj,{:conj,{:v,:r2},{:v,:r3}},{:conj,{:v,:r2},{:v,:r4}}}}
		assert NF.dnf(p4) == p4
		assert NF.dnf(p5) == {:disj,
													{:conj,{:nt,{:v,:r1}},{:nt,{:v,:r2}}},
													{:conj,{:nt,{:v,:r3}},{:nt,{:v,:r4}}}
												 }
	end

	test "Conjunctive Normal Form" do
		assert NF.cnf(p1) == {:conj,
													{:disj,{:v,:r1},{:eq,{:v,:r3},{:lit,4}}},
													{:disj,{:v,:r2},{:eq,{:v,:r3},{:lit,4}}}
												 }
		assert NF.cnf(p2) == p2
		assert NF.cnf(p3) == p3
		assert NF.cnf(p4) == 
								{:conj,
								 {:conj,{:disj,{:v,:r1},{:v,:r3}},{:disj,{:v,:r1},{:v,:r4}}},
								 {:conj,{:disj,{:v,:r2},{:v,:r3}},{:disj,{:v,:r2},{:v,:r4}}}}
		assert NF.cnf(p5) == {:conj, 
													{:conj, 
													 {:disj, {:nt, {:v, :r1}}, {:nt, {:v, :r3}}},
													 {:disj, {:nt, {:v, :r1}}, {:nt, {:v, :r4}}}
													},
													{:conj, 
													 {:disj, {:nt, {:v, :r2}}, {:nt, {:v, :r3}}}, 
													 {:disj, {:nt, {:v, :r2}}, {:nt, {:v, :r4}}}
													}
												 }
	end
end
