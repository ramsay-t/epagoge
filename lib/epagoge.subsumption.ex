defmodule Epagoge.Subsumption do
	
	# Reflexivity
	def subsumes?(l,r) do
		if l == r do
			true
		else
			subsumes_case(l,r)
		end
	end

	# Variable subsumption
	def subsumes_case({:v,_},{:lit,_}) do
		true
	end
	def subsumes_case({:v,lname},{:v,rname}) do
		lname == rname
	end

	def subsumes_case({:eq,ll,lr},{:eq,rl,rr}) do
		subsumes_case(ll,rl) and subsumes_case(lr,rr)
	end

  # Match expression subsuption
	def subsumes_case({:match,lpre,lsuf,lt},{:match,rpre,rsuf,rt}) do
		if lt != rt do
			false
		else
			String.starts_with?(rpre,lpre) and String.ends_with?(rsuf,lsuf)
		end
	end

	def subsumes_case(_l,_r) do
		:io.format("Fell through subsumption: ~p vs ~p~n",[_l,_r])
		false
	end

end