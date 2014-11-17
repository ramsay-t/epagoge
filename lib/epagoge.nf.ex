defmodule Epagoge.NF do

	# Disjunctive Normal Form
	def dnf({:disj,l,r}) do
		{:disj,dnf(l),dnf(r)}
	end
	def dnf({:conj,orl,orr}) do
		tl = dnf(orl)
		tr = dnf(orr)
		case {:conj,tl,tr} do
			{:conj,{:disj,ll,lr},{:disj,rl,rr}} ->
				{:disj,{:disj,{:conj,ll,rl},{:conj,ll,rr}},{:disj,{:conj,lr,rl},{:conj,lr,rr}}}
			{:conj,{:disj,ll,lr},r} ->
				{:disj,{:conj,ll,r},{:conj,lr,r}}
			{:conj,l,{:disj,rl,rr}} ->
				{:disj,{:conj,l,rl},{:conj,l,rr}}
			{:conj,l,r} ->
				{:conj,l,r}
		end
	end	
	def dnf({:nt,r}) do
		d = ntdiss({:nt,r})
		if d == {:nt,r} do
			d
		else
			dnf(d)
		end
	end
	def dnf(prop) do
		prop
	end

	# Conjunctive Normal Form
	def cnf({:conj,l,r}) do
		{:conj,cnf(l),cnf(r)}
	end
	def cnf({:disj,orl,orr}) do
		tl = cnf(orl)
		tr = cnf(orr)
		case {:disj,tl,tr} do
			{:disj,{:conj,ll,lr},{:conj,rl,rr}} ->
				{:conj,{:conj,{:disj,ll,rl},{:disj,ll,rr}},{:conj,{:disj,lr,rl},{:disj,lr,rr}}}
			{:disj,{:conj,ll,lr},r} ->
				{:conj,{:disj,ll,r},{:disj,lr,r}}
			{:disj,l,{:conj,rl,rr}} ->
				{:conj,{:disj,l,rl},{:disj,l,rr}}
			{:disj,l,r} ->
				{:disj,l,r}
		end
	end
	def cnf({:nt,r}) do
		d = ntdiss({:nt,r})
		if d == {:nt,r} do
			d
		else
			cnf(d)
		end
	end
	def cnf(prop) do
		prop
	end

	defp ntdiss({:nt,{:conj,l,r}}) do
		{:disj,ntdiss({:nt,l}),ntdiss({:nt,r})}
	end
	defp ntdiss({:nt,{:disj,l,r}}) do
		{:conj,ntdiss({:nt,l}),ntdiss({:nt,r})}
	end
	defp ntdiss(prop) do
		prop
	end

end