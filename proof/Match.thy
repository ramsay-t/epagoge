theory Match
imports String "~~/src/HOL/Library/Sublist"
begin

fun match :: "string \<Rightarrow> string \<Rightarrow> string \<Rightarrow> bool" where
"match pre suf x = (\<exists>b.\<exists>e.\<exists>v.(b @ pre @ v @ suf @ e) = x)"

definition Hello :: "string" where
"Hello \<equiv> [CHR ''h'', CHR ''e'', CHR ''l'', CHR ''l'', CHR ''o'']"
declare Hello_def [simp]

definition He :: "string" where
"He \<equiv> [CHR ''h'', CHR ''e'']"
declare He_def [simp]

definition Lo :: "string" where
"Lo \<equiv> [CHR ''l'', CHR ''o'']"
declare Lo_def [simp]

lemma test0 : "[] @ He @ [CHR ''l''] @ Lo @ [] = Hello"
by simp

(* sledgehammer z3 can solve this too, but this is explicit *)
lemma test1 : "match He Lo Hello" 
apply simp
apply (rule_tac x="[]" in exI)
apply (rule_tac x="[]" in exI)
apply (rule_tac x="[CHR ''l'']" in exI)
by simp

fun subsumes :: "string * string \<Rightarrow> string * string \<Rightarrow> bool" where
"subsumes (p1,s1) (p2,s2) = ((prefixeq p1 p2) \<and> (suffixeq s1 s2))"

theorem reflexivity : "\<forall>p s . subsumes (p,s) (p,s)"
by simp

theorem antisymetry : 
  "\<forall>p1 s1 p2 s2 . 
    (subsumes (p1,s1) (p2,s2)) 
    \<and> (subsumes (p2,s2) (p1,s1)) 
      \<longrightarrow> (p1 = p2) \<and> (s1 = s2)"
by (metis subsumes.simps prefix_order.eq_iff suffixeq_antisym)

theorem transitivity : "\<forall>p1 p2 p3 s1 s2 s3 . 
  (subsumes (p1,s1) (p2,s2)) \<and> (subsumes (p2,s2) (p3,s3))
    \<longrightarrow> subsumes (p1,s1) (p3,s3)"
by (metis subsumes.simps prefix_order.order.trans suffixeq_trans)

theorem join : "\<forall>p1 s1 p2 s2 x . 
  (match p1 s1 x) \<and> (match p2 s2 x) 
    \<longrightarrow> (\<exists>p3 s3 . 
            (subsumes (p3,s3) (p1,s1))
            \<and> (subsumes (p3,s3) (p2,s2)))"
by (metis subsumes.simps Nil_suffixeq prefix_bot.bot.extremum)

end
