theory Match
imports String "~~/src/HOL/Library/Sublist"
begin

fun match :: "string \<Rightarrow> string \<Rightarrow> string \<Rightarrow> bool" where
"match pre suf x = (\<exists>b e v.(b @ pre @ v @ suf @ e) = x)"

fun subsumes :: "string * string \<Rightarrow> string * string \<Rightarrow> bool" (infixl "\<sqsupseteq>" 95)  where
"(p1,s1) \<sqsupseteq> (p2,s2) = ((prefixeq p1 p2) \<and> (suffixeq s1 s2))"

theorem subsumes_refl : "\<forall>p s . (p,s) \<sqsupseteq> (p,s)"
by simp

theorem subsumes_refl2 : "\<forall>x . x \<sqsupseteq> x"
by simp

theorem subsumes_antisym : 
  "((p1,s1) \<sqsupseteq> (p2,s2)) 
    \<and> ((p2,s2) \<sqsupseteq> (p1,s1)) 
      \<longrightarrow> (p1 = p2) \<and> (s1 = s2)"
by (metis subsumes.simps prefix_order.eq_iff suffixeq_antisym)

theorem subsumes_antisym2 : 
  "\<lbrakk> (x \<sqsupseteq> y) 
    ; (y \<sqsupseteq> x) \<rbrakk>
      \<Longrightarrow> x = y"
by (metis old.prod.exhaust subsumes_antisym)

theorem subsumes_trans : 
  "((p1,s1) \<sqsupseteq> (p2,s2)) \<and> ((p2,s2) \<sqsupseteq> (p3,s3))
    \<longrightarrow> (p1,s1) \<sqsupseteq> (p3,s3)"
by (metis subsumes.simps prefix_order.order.trans suffixeq_trans)

theorem subsumes_trans2 :  
  "\<lbrakk> (x \<sqsupseteq> y) ; (y \<sqsupseteq> z) \<rbrakk>
    \<Longrightarrow> x \<sqsupseteq> z"
by (smt2 subsumes.elims(1) subsumes_trans)

lemma subsumes_top : "\<forall>x . ([],[]) \<sqsupseteq> x"
by simp

lemma subsumes_top_id [simp] : "x \<sqsupseteq> ([],[]) = (x = ([],[]))"
by (metis subsumes_antisym2 subsumes_top)

lemma subsumes_left_top [simp] : "x \<sqsupseteq> ([],a) = (\<exists>b. (x = ([],b)) \<and> (suffixeq b a))" 
by (metis (no_types, hide_lams) prefix_bot.bot.extremum prefix_order.eq_iff subsumes.elims(2) subsumes.simps)

lemma subsumes_right_top [simp] : "x \<sqsupseteq> (a,[]) = (\<exists>b. (x = (b,[])) \<and> (prefixeq b a))" 
by (metis (no_types, hide_lams) Nil_suffixeq subsumes.elims(2) subsumes.simps suffixeq_antisym)

lemma subsumes_preserves_match : 
  "\<lbrakk> match a b x; (c,d) \<sqsupseteq> (a,b) \<rbrakk> \<Longrightarrow> match c d x"
apply simp
by (metis append_assoc prefixeqE suffixeq_def)

theorem join : "\<forall>p1 s1 p2 s2 x . 
  (match p1 s1 x) \<and> (match p2 s2 x) 
    \<longrightarrow> (\<exists>p3 s3 . 
            ((p3,s3) \<sqsupseteq> (p1,s1))
            \<and> ((p3,s3) \<sqsupseteq> (p2,s2)))"
by (metis subsumes.simps Nil_suffixeq prefix_bot.bot.extremum)

fun greatest_common_prefix :: "string \<Rightarrow> string \<Rightarrow> string" where
"greatest_common_prefix [] _ = []"
| "greatest_common_prefix _ [] = []"
| "greatest_common_prefix (x # l) (y # r) = 
  (if x = y
  then x # (greatest_common_prefix l r)
  else [])"

lemma gcp_commute : 
  "greatest_common_prefix a b = greatest_common_prefix b a"
apply (induct a arbitrary: b)
apply simp
apply (metis greatest_common_prefix.simps(1) greatest_common_prefix.simps(2) neq_Nil_conv)
apply (subgoal_tac "b = [] \<or> (\<exists>x xs. b = x#xs)")
apply safe
apply (metis greatest_common_prefix.simps(1) greatest_common_prefix.simps(2))
apply (metis greatest_common_prefix.simps(3))
by (metis neq_Nil_conv)

lemma gcp_is_one_prefix : 
  "prefixeq (greatest_common_prefix a b) a" 
apply (induct a arbitrary: b)
apply simp
apply (subgoal_tac "b = [] \<or> (\<exists>x xs. b = x#xs)")
apply auto
by (metis hd_Cons_tl)

lemma gcp_is_prefix : 
  "prefixeq (greatest_common_prefix a b) a
  \<and> prefixeq (greatest_common_prefix a b) b"
by (metis gcp_commute gcp_is_one_prefix)

lemma gcp_shrinks : 
  "length (greatest_common_prefix a b) \<le> length a 
  \<and> length (greatest_common_prefix a b) \<le> length b"
apply (rule conjI)
apply (induct a arbitrary: b)
apply simp
apply (subgoal_tac "b = [] \<or> (\<exists>x xs. b = x#xs)")
apply auto
apply (metis neq_Nil_conv)
apply (induct b arbitrary: a)
apply simp
apply (subgoal_tac "a = [] \<or> (\<exists>x xs. a = x#xs)")
apply safe
apply simp
apply simp
apply (metis neq_Nil_conv)
by (metis gcp_is_prefix prefixeq_length_le)

lemma gcp_refl : "greatest_common_prefix a a = a"
apply (induct a)
apply simp
by (metis greatest_common_prefix.simps(3))

lemma gcp_includes_shorter :
  "\<lbrakk> prefixeq p x; length(p) < length(greatest_common_prefix x y) \<rbrakk> 
    \<Longrightarrow> prefixeq p (greatest_common_prefix x y)"
apply (induct x arbitrary: y)
apply simp
apply (subgoal_tac "y = [] \<or> (\<exists>xy xys. y = xy#xys)")
apply safe
apply (metis greatest_common_prefix.simps(2) list.size(3) not_less0)
apply (metis gcp_is_prefix not_less prefixeq_length_le prefixeq_same_cases)
by (metis hd_Cons_tl)

lemma gcp_includes_shorter_other :
  "\<lbrakk> prefixeq p y; length(p) < length(greatest_common_prefix x y) \<rbrakk> 
    \<Longrightarrow> prefixeq p (greatest_common_prefix x y)"
by (metis gcp_commute gcp_includes_shorter)

lemma gcp_is_shortest_common_prefix : 
  "\<lbrakk> prefixeq p x; prefixeq p y; length(p) < length(greatest_common_prefix x y) \<rbrakk> 
      \<Longrightarrow> prefixeq p (greatest_common_prefix x y)"
by (metis gcp_includes_shorter_other)

lemma gcp_matches_matching_prefix :
  "\<lbrakk>prefixeq p x; length(p) = length(greatest_common_prefix x y) \<rbrakk>
    \<Longrightarrow> greatest_common_prefix x y = p"
by (metis append_eq_conv_conj gcp_is_prefix prefixeq_def)

lemma gcp_cannot_be_extended :
  "\<not>(\<exists>e . prefixeq ((greatest_common_prefix x y) @ [e]) x
          \<and> prefixeq ((greatest_common_prefix x y) @ [e]) y)"
apply (induct x arbitrary: y)
apply simp
apply (subgoal_tac "y = [] \<or> (\<exists>z zs . y = z # zs)")
apply safe
apply (metis append_Nil greatest_common_prefix.simps(2) prefixeq_code(2))
apply (metis Cons_prefixeq_Cons append_Cons append_Nil greatest_common_prefix.simps(3))
by (metis hd_Cons_tl)

lemma gcp_is_longest_prefix :
  "\<not>(\<exists>p . prefix p x \<and> prefix p y \<and> length(p) > length(greatest_common_prefix x y))"
apply (induct x arbitrary: y)
apply simp
apply (subgoal_tac "y = [] \<or> (\<exists> z zs. y = z # zs)")
apply safe
apply simp
apply simp
apply (subgoal_tac "p = [] \<or> (\<exists> q qs. p = q # qs)")
apply safe
apply (metis list.size(3) not_less0)
apply (metis (mono_tags)  Suc_less_eq length_Cons prefix_simps(3))
apply (metis neq_Nil_conv)
by (metis hd_Cons_tl)

lemma gcp_is_greatest_prefix : 
  "\<forall>p. prefixeq p x \<and> prefixeq p y \<longrightarrow> prefixeq p (greatest_common_prefix x y)"
apply (induct x arbitrary: y)
apply simp
apply (subgoal_tac "y = [] \<or> (\<exists>x xs . y = x # xs)")
apply safe
apply simp
apply (subst greatest_common_prefix.simps)
apply simp
apply (subst prefixeq_def)
apply safe
apply (metis list.exhaust list.inject prefixeq_Cons prefixeq_def)
apply (metis list.inject prefixeq_Cons)
apply simp
by (metis hd_Cons_tl)

theorem gcp_is_least_upper_bound : 
  "\<forall>p. prefixeq p x \<and> prefixeq p y \<longleftrightarrow> prefixeq p (greatest_common_prefix x y)"
apply (induct x arbitrary: y)
apply simp
apply (subgoal_tac "y = [] \<or> (\<exists>x xs . y = x # xs)")
apply safe
apply simp
apply (metis neq_Nil_conv)
apply (metis gcp_is_greatest_prefix)
apply (metis gcp_is_prefix prefix_order.order.trans)
by (metis gcp_is_prefix prefix_order.order.trans)

lemma prefix_rev_suffix : "prefixeq x y \<longleftrightarrow> suffixeq (rev x) (rev y)"
by (metis rev_rev_ident suffixeq_to_prefixeq)

definition greatest_common_suffix :: "string \<Rightarrow> string \<Rightarrow> string" where
"greatest_common_suffix x y \<equiv> rev (greatest_common_prefix (rev x) (rev y))"
declare greatest_common_suffix_def [simp]

lemma gcs_commute : "greatest_common_suffix x y = greatest_common_suffix y x"
by (metis gcp_commute greatest_common_suffix_def)

lemma gcs_is_suffix : 
  "suffixeq (greatest_common_suffix a b) a
  \<and> suffixeq (greatest_common_suffix a b) b"
by (metis gcp_is_prefix greatest_common_suffix_def rev_rev_ident suffixeq_to_prefixeq)

lemma gcs_shrinks :
  "length (greatest_common_suffix a b) \<le> length a 
    \<and> length (greatest_common_suffix a b) \<le> length b"
by (metis gcp_shrinks greatest_common_suffix_def length_rev)

lemma gcs_refl : "greatest_common_suffix a a = a"
apply (induct a)
apply simp
apply simp
by (metis gcp_refl)

fun match_join :: "(string * string) \<Rightarrow> (string * string) \<Rightarrow> (string * string)" where
"match_join (p1,s1) (p2,s2) = 
  ((greatest_common_prefix p1 p2),(greatest_common_suffix s1 s2))"

lemma match_join_refl [simp] : "match_join a a = a"
apply (induct a)
by (metis gcp_refl greatest_common_suffix_def rev_rev_ident match_join.simps)

lemma match_join_commute [simp] : "match_join a b = match_join b a"
apply (induct a arbitrary: b)
by (metis fst_conv gcp_commute gcs_commute snd_conv match_join.elims)

lemma match_join_top : 
  "\<forall>a b . ([],[]) \<sqsupseteq> match_join a b"
by simp

lemma match_join_top_id :
  "\<forall>x . match_join x ([],[]) = ([],[])"
apply simp
by (metis gcp_commute greatest_common_prefix.simps(1))

lemma match_join_left_empty : 
  "\<forall>x y. \<exists> z. match_join ([],y) x = ([],z)"
apply simp
by (metis gcp_commute greatest_common_prefix.simps(1))

lemma match_join_right_empty : 
  "\<forall>x y. \<exists> z. match_join (y,[]) x = (z,[])"
apply simp
by (metis gcp_commute greatest_common_prefix.simps(1))

lemma match_join_is_join : 
  "match_join a b \<sqsupseteq> a
  \<and> match_join a b \<sqsupseteq> b"
apply (rule conjI)
apply (metis PairE fst_conv gcp_is_prefix gcs_is_suffix snd_conv subsumes.elims(3) match_join.elims)
by (metis fst_conv gcp_is_prefix gcs_is_suffix snd_conv subsumes.elims(3) match_join.elims surj_pair)

lemma match_join_tran :
  "\<lbrakk>a \<sqsupseteq> (c,cc); b \<sqsupseteq> (d,dd)\<rbrakk> \<Longrightarrow> 
    match_join a b \<sqsupseteq> (c,cc) 
    \<and> match_join a b \<sqsupseteq> (d,dd)" 
apply (rule conjI)
apply (metis match_join_is_join subsumes_trans2)
by (metis match_join_is_join subsumes_trans2)

lemma match_join_antisym :
  "(match_join a b \<sqsupseteq> match_join c d)
  \<and> (match_join c d \<sqsupseteq> match_join a b)
  \<longleftrightarrow> match_join a b = match_join c d"
apply auto
apply (metis subsumes_antisym2)
apply (metis subsumes_refl2)
by (metis subsumes_refl2)

theorem match_join_least_upper_bound : 
  "\<forall>p x y . (p \<sqsupseteq> x \<and> p \<sqsupseteq> y) \<longleftrightarrow> p \<sqsupseteq> match_join x y"
apply auto
apply (metis gcp_is_greatest_prefix)
apply (metis gcp_is_greatest_prefix rev_rev_ident suffixeq_to_prefixeq)
apply (metis gcp_is_prefix prefix_order.order.trans)
apply (metis gcs_is_suffix greatest_common_suffix_def suffixeq_trans)
apply (metis gcp_is_prefix prefix_order.order.trans)
by (metis gcs_is_suffix greatest_common_suffix_def suffixeq_trans)


end
