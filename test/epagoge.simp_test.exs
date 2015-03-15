defmodule Epagoge.SimpTest do
  use ExUnit.Case
	alias Epagoge.Simp, as: Simp

	test "Binary conversion" do
		assert Simp.make_bin(0,0) == <<0,0>>
		assert Simp.make_bin(0,4) == <<0,4>>
		assert Simp.make_bin(1,4) == <<64,4>>
		assert Simp.make_bin(2,4) == <<128,4>>
		assert Simp.make_bin(3,4) == <<192,4>>
		assert Simp.make_bin(3,1024) == <<196,0>>
	end

	test "Binary display" do
		assert Simp.display_bin(Simp.make_bin(0,0)) == [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
		assert Simp.display_bin(Simp.make_bin(0,4)) == [0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0]
		assert Simp.display_bin(Simp.make_bin(1,4)) == [0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0]
		assert Simp.display_bin(Simp.make_bin(2,4)) == [1,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0]
		assert Simp.display_bin(Simp.make_bin(3,4)) == [1,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0]
		assert Simp.display_bin(Simp.make_bin(3,1024)) == [1,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0]
	end

	test "Tsetin transformations" do
		assert Simp.tsetin({:lt,{:v,"x"},{:lit,"3"}}) == [{:lt,{:v,"x"},{:lit,"3"}}]
		assert Simp.tsetin({:gr,{:v,"x"},{:lit,"3"}}) == [{:gr,{:v,"x"},{:lit,"3"}}]
		assert Simp.tsetin({:conj, {:gr,{:v,"x"},{:lit,"3"}}, {:lit,"false"}}) == [{:conj,{:prop,1},{:lit,"false"}}, 
																																							{:gr,{:v,"x"},{:lit,"3"}}]
		# x < 5 ^ x > 3 ^ false 
		# [{^ p1 p2},{< x 5},{^ p3 false},{> x 3}
		assert Simp.tsetin({:conj, 
												{:lt,{:v,"x"},{:lit,"5"}}, 
												{:conj, 
												 {:gr,{:v,"x"},{:lit,"3"}}, 
												 {:lit,"false"}
											  }
											 }) 
												 == [{:conj,{:prop,1},{:prop,2}},
														 {:lt,{:v,"x"},{:lit,"5"}},
														 {:conj,{:prop,3},{:lit,"false"}}, 
														 {:gr,{:v,"x"},{:lit,"3"}}]
		# Bracketed the other way...
		assert Simp.tsetin({:conj,
												{:conj,
												 {:lt,{:v,"x"},{:lit,"5"}}, 
												 {:gr,{:v,"x"},{:lit,"3"}}, 
												},
												{:lit,"false"}
											}) == [{:conj,{:prop,1},{:lit,"false"}},
														 {:conj,{:prop,2},{:prop,3}},
														 {:lt,{:v,"x"},{:lit,"5"}},
														 {:gr,{:v,"x"},{:lit,"3"}}
													 ]
	end

	test "Label variables" do
		assert Simp.label_vars({:conj, 
												{:lt,{:v,"x"},{:lit,"5"}}, 
												{:conj, 
												 {:gr,{:v,"x"},{:lit,"3"}}, 
												 {:lit,"false"}
											  }
											 }) == {{:conj, 
												{:lt,{:lv,0},{:lit,"5"}}, 
												{:conj, 
												 {:gr,{:lv,0},{:lit,"3"}}, 
												 {:lit,"false"}
											  }
											 },[{0,"x"}]}
	end
	test "Label literals" do
		assert Simp.label_lits({:conj, 
												{:lt,{:lv,0},{:lit,"5"}}, 
												{:conj, 
												 {:gr,{:lv,0},{:lit,"3"}}, 
												 {:lit,"false"}
											  }
											 }) == {{:conj, 
												{:lt,{:lv,0},{:ll,1}}, 
												{:conj, 
												 {:gr,{:lv,0},{:ll,2}}, 
												 {:ll,3}
											  }
											 },[{0,nil},{1,"5"},{2,"3"},{3,"false"}]}
	end

	test "Prop to Binary" do
	#{:conj,{:prop,1},{:prop,2}},
	#{:lt,{:lv,0},{:ll,1}},
	#{:conj,{:prop,3},{:ll,3}}, 
	#{:gr,{:lv,0},{:ll,2}}
		assert Simp.prop_to_bin({:conj, 
														 {:lt,{:v,"x"},{:lit,"5"}}, 
														 {:conj, 
															{:gr,{:v,"x"},{:lit,"3"}}, 
															{:lit,"false"}
														 }
													 }) == {[<<192,0,128,1,128,2>>,
																	 <<192,4,64,0,0,1>>,
																	 <<192,0,128,3,0,3>>,
																	 <<192,2,64,0,0,2>>],
																	[{0,"x"}],
																	[{0,nil},{1,"5"},{2,"3"},{3,"false"}]}
	end
	
	test "Make patterns" do
		assert Simp.make_patterns([{0,nil},{1,"5"},{2,"3"},{3,"false"}]) ==
									[{<<255,255,255,255,0,0>>,<<192,0,0,3,0,0>>,<<0,3,0,0,0,0>>},
									{<<255,255,0,0,255,255>>,<<192,0,0,0,0,3>>,<<0,3,0,0,0,0>>}]
	end

	test "GPU conversion" do
		assert Simp.gpu_convert({:conj, 
														 {:lt,{:v,"x"},{:lit,"5"}}, 
														 {:conj, 
															{:gr,{:v,"x"},{:lit,"3"}}, 
															{:lit,"false"}
														 }
													 }) == {{[<<192,0,128,1,128,2>>,
																		<<192,4,64,0,0,1>>,
																		<<192,0,128,3,0,3>>,
																		<<192,2,64,0,0,2>>],
																	 [{<<255,255,255,255,0,0>>,<<192,0,0,3,0,0>>,<<0,3,0,0,0,0>>},
																		{<<255,255,0,0,255,255>>,<<192,0,0,0,0,3>>,<<0,3,0,0,0,0>>}]
																	},
																	{[{0,"x"}],
																	 [{0,nil},{1,"5"},{2,"3"},{3,"false"}]}}
	end

end