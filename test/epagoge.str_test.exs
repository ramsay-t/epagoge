defmodule Epagoge.StrTest do
  use ExUnit.Case
	alias Epagoge.Str, as: Str

	test "Get match for complete but distinct strings" do
		assert Str.get_match([{"coke","coke"},{"pepsi","pepsi"}]) == {"",""}
	end
	test "Get match for incomplete, distinct strings" do
		assert Str.get_match([{"coke","coke"},{"key=pepsi","pepsi"}]) == nil
	end
	test "Get match for pairs with identical pre and suf" do
		assert Str.get_match([{"key=coke;","coke"},{"key=pepsi;","pepsi"}]) == {"key=",";"}
	end
	test "Get match for pairs with identical pre and suf and noise" do
		assert Str.get_match([{"xxxxxkey=coke;xxxx","coke"},{"yyyyykey=pepsi;yyyy","pepsi"}]) == {"key=",";"}
	end
	test "Get match for pairs with identical pre and suf but several pairs" do
		assert Str.get_match([{"xxxxxkey=coke;xxxx","coke"},
													{"yyyyykey=pepsi;yyyy","pepsi"},
													{"pppkeykeykey=co;y=coke;sss","coke"}]) == {"y=",";"}
	end

	test "GCS" do
		assert Str.gcs("","") == ""
		assert Str.gcs("coke","pepsi") == ""
		assert Str.gcs("coke","bloke") == "oke"
		assert Str.gcs("ke","e") == "e"
		assert Str.gcs("e","ke") == "e"
	end
	test "GCP" do
		assert Str.gcp("","") == ""
		assert Str.gcp("coke","pepsi") == ""
		assert Str.gcp("coke","coors") == "co"
		assert Str.gcp("co","c") == "c"
		assert Str.gcp("c","co") == "c"
	end

	defp s1() do 
		"coke=ok"
	end

	defp s2() do
		"I would like a coke, ok? please."
	end

	defp s3() do
		"I would like a pepsi, please."
	end

	defp s4() do
		"pepsiplease"
	end

	defp s5() do
		"coke:ok"
	end
	
	defp s6() do
		"coke is what I want, yes coke."
	end
	
	test "Two common substrings" do
		assert Str.common_substrings(s1,s2) == ["coke","ok","o","e"]
	end

	test "Two common substrings, no space" do
		assert Str.common_substrings(s4,s3) == ["pepsi","please","l", "i", "e", "a"]
	end

	test "Commutativity" do
		assert Str.common_substrings(s3,s4) == ["l", "i", "e", "a", "pepsi","please"]
	end

	test "Seperate but content-overlapping substrings" do
		assert Str.common_substrings(s1,s5) == ["coke","ok"]
	end

	test "Repeated substring" do
		assert Str.common_substrings(s1,s6) == ["coke","ok","e"]
	end

	test "No interesting common substrings" do
		assert Str.common_substrings(s1,s3) == ["o","ke","k","e"]
	end

	test "No Strs" do
		assert Str.common_substrings("abcdef","ghijkl") == []
	end 

	test "One empty string" do
		assert Str.common_substrings(s1,"") == []
	end

	test "Other empty string" do
		assert Str.common_substrings("",s2) == []
	end

	test "Both empty string" do
		assert Str.common_substrings("","") == []
	end


end