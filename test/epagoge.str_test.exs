defmodule Epagoge.StrTest do
  use ExUnit.Case
	alias Epagoge.Str, as: Str

#	test "Join two dissimilar strings" do
#		assert Str.join("coke","pepsi") == {"",""}
#	end

#	test "Join two strings with real identifiers" do
#		assert Str.join("")
#	end

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