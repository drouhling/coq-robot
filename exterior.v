Require Import mathcomp.ssreflect.ssreflect.
From mathcomp
Require Import ssrfun ssrbool eqtype ssrnat seq choice fintype tuple finfun.
From mathcomp
Require Import bigop ssralg ssrint div rat poly closed_field polyrcf.
From mathcomp
Require Import matrix mxalgebra tuple mxpoly zmodp binomial.
From mathcomp
Require Import perm finset path fingroup.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory.

Local Open Scope ring_scope.

Section delta.

Import GroupScope.

Fact perm_of_2seq_key : unit. Proof. exact: tt. Qed.
Definition perm_of_2seq :=
  locked_with perm_of_2seq_key
  (fun (T : eqType) n (si so : n.-tuple T) =>
  if (perm_eq si so =P true) isn't ReflectT ik then 1%g
  else sval (sig_eqW (tuple_perm_eqP ik))).
Canonical perm_of_2seq_unlockable := [unlockable fun perm_of_2seq].

Lemma perm_of_2seqE n (T : eqType) (si so : n.-tuple T) (j : 'I_n) :
  perm_eq si so -> tnth so (perm_of_2seq si so j) = tnth si j.
Proof.
rewrite [perm_of_2seq]unlock; case: eqP => // H1 H2.
case: sig_eqW => /= s; rewrite /tnth => -> /=.
by rewrite (nth_map j) ?size_enum_ord // nth_ord_enum.
Qed.

(* Definition perm_of_2seq (T : eqType) n (si : seq T) (so : seq T) : 'S_n := *)
(*   if (size so == n) =P true isn't ReflectT so_n then 1%g *)
(*   else if (perm_eq si (Tuple so_n) =P true) isn't ReflectT ik then 1%g *)
(*   else sval (sig_eqW (tuple_perm_eqP ik)). *)

(* Lemma perm_of_2seqE n (T : eqType) (si so : n.-tuple T) (j : 'I_n) : *)
(*   perm_eq si so -> tnth so (perm_of_2seq n si so j) = tnth si j. *)
(* Proof. *)
(* rewrite /perm_of_2seq; case: eqP => // so_n p_si_so; last first. *)
(*   by rewrite size_tuple eqxx in so_n. *)
(* case: eqP => // ?; case: sig_eqW => /= s; rewrite /tnth => -> /=. *)
(* rewrite (nth_map j) ?size_enum_ord // nth_ord_enum /=. *)
(* by apply: set_nth_default; rewrite size_tuple. *)
(* Qed. *)

Lemma perm_of_2seqV n (T : eqType) (si so : n.-tuple T) : uniq si ->
  (perm_of_2seq si so)^-1%g = perm_of_2seq so si.
Proof.
move=> uniq_si.
apply/permP => /= j.
apply/val_inj/eqP => /=.
rewrite -(@nth_uniq _ (tnth_default si j) (val si)) //=; last 2 first.
- by rewrite size_tuple.
- by rewrite size_tuple.
rewrite [perm_of_2seq]unlock; case: eqP => p; last first.
  case: eqP => // p0; by [rewrite perm_eq_sym p0 in p | rewrite invg1].
case: eqP => [p'|]; last by rewrite perm_eq_sym {1}p.
case: sig_eqW => /= x Hx; case: sig_eqW => /= y Hy.
rewrite {1}Hx (nth_map j); last by rewrite size_enum_ord.
rewrite nth_ord_enum permE f_iinv /tnth Hy (nth_map j); last by rewrite size_enum_ord.
rewrite nth_ord_enum /tnth; apply/eqP/set_nth_default;  by rewrite size_tuple.
Qed.

Variable R : ringType.
Local Open Scope ring_scope.

Definition delta (i k : seq nat) : R :=
  if (perm_eq i k) && (uniq i) then
  (-1) ^+ perm_of_2seq (insubd (in_tuple k) i) (in_tuple k) else 0.

Lemma deltaE n (i k : seq nat) (si : size i = n) (sk : size k = n) : 
   let T l (P : size l = n)  := Tuple (appP eqP idP P) in
   delta i k = if (perm_eq i k) && (uniq i)
               then (-1) ^+ perm_of_2seq (T _ si) (T _ sk) else 0.
Proof.
move=> T; rewrite /delta; have [/andP [pik i_uniq]|//] := ifP.
set i' := insubd _ _; set k' := in_tuple _.
have [] : (i' = T _ si :> seq _ /\ k' = T _ sk :> seq _).
  by rewrite /= val_insubd /= (perm_eq_size pik) eqxx.
move: i' k' (T i si) (T k sk) => /=.
by case: _ / sk => ??????; congr (_ ^+ perm_of_2seq _ _); apply: val_inj.
Qed.

(* Definition deltaE n (i k : seq nat) (si : size i == n) (sk : size k == n) := *)
(*   deltaE (Tuple si) (Tuple sk). *)

(* Lemma delta_cast n (i k : seq nat) (ni : size i = n) (nk : size k = n) : *)
(*   delta i k = delta (Tuple (appP eqP idP ni)) (Tuple (appP eqP idP nk)). *)

Lemma delta_0 (i : seq nat) k : (~~ uniq i) || (~~ uniq k) -> delta i k = 0.
Proof.
case/orP => [Nui|Nuk]; rewrite /delta; case: ifP => // /andP[pik ui].
  by rewrite (negbTE Nui) in ui.
by rewrite -(perm_eq_uniq pik) ui in Nuk.
Qed.

(* Definition scast {m n : nat} (eq_mn : m = n) (s : 'S_m) : 'S_n := *)
(*   ecast n ('S_n) eq_mn s. *)

(* Lemma tcastE (m n : nat) (eq_mn : m = n) (t : 'S_m) (i : 'I_n), *)
(*    tnth (tcast eq_mn t) i = tnth t (cast_ord (esym eq_mn) i) *)
(* tcast_id *)
(*    forall (T : Type) (n : nat) (eq_nn : n = n) (t : n.-tuple T), *)
(*    tcast eq_nn t = t *)
(* tcastK *)
(*    forall (T : Type) (m n : nat) (eq_mn : m = n), *)
(*    cancel (tcast eq_mn) (tcast (esym eq_mn)) *)
(* tcastKV *)
(*    forall (T : Type) (m n : nat) (eq_mn : m = n), *)
(*    cancel (tcast (esym eq_mn)) (tcast eq_mn) *)
(* tcast_trans *)
(*    forall (T : Type) (m n p : nat) (eq_mn : m = n)  *)
(*      (eq_np : n = p) (t : m.-tuple T), *)
(*    tcast (etrans eq_mn eq_np) t = tcast eq_np (tcast eq_mn t) *)
(* L *)

(* Lemma perm_of_2seq_tcast (T : eqType) n m i (k : m.-tuple T) (eq_mn : m = n): *)
(*   perm_of_2seq i (tcast eq_mn k) = scast eq_mn (perm_of_2seq i k). *)

Lemma perm_of_2seq_ii n (i : n.-tuple nat) : perm_of_2seq i i = 1%g.
Proof. Admitted.

Lemma deltaii (i : seq nat) : uniq i -> delta i i = 1.
Proof.
move=> i_uniq; rewrite !(@deltaE (size i)) .
by rewrite perm_eq_refl i_uniq /= perm_of_2seq_ii odd_perm1.
Qed.

Lemma deltaC i k : delta i k = delta k i.
Proof.
have [pik|pik] := boolP (perm_eq i k); last first.
  by rewrite /delta (negPf pik) perm_eq_sym (negPf pik).
have [uk|Nuk] := boolP (uniq k); last by rewrite !delta_0 // Nuk ?orbT.
have si := (perm_eq_size pik); rewrite !(@deltaE (size k)) //.
rewrite pik /= perm_eq_sym pik (perm_eq_uniq pik) uk /=.
by rewrite -perm_of_2seqV // odd_permV.
Qed.

(* Lemma deltaN1 (i : seq nat) k : uniq i -> *)
(*   perm_of_2seq i (in_tuple k) -> delta i k = -1. *)
(* Proof. *)
(* move=> ui; rewrite /delta /perm_of_2seq ui. *)
(* case: eqP => [p|]; last by rewrite odd_perm1. *)
(* case: sig_eqW => /= x ih Hx; by rewrite p Hx expr1. *)
(* Qed. *)

(* Lemma delta_1 (i : seq nat) k : uniq i -> perm_eq i k ->  *)
(*  ~~ perm_of_2seq i (in_tuple k) -> delta i k = 1. *)
(* Proof. *)
(* move=> ui ik. *)
(* rewrite /delta /perm_of_2seq ui. *)
(* case: eqP => [p|]. *)
(*   case: sig_eqW => /= x ih Hx. *)
(*   by rewrite p (negPf Hx) expr0. *)
(* by rewrite ik. *)
(* Qed. *)

Lemma perm_of_2seq_comp n {T: eqType} (s1 s2 s3 : n.-tuple T) :
  uniq s3 -> perm_eq s1 s2 -> perm_eq s2 s3 ->
  (perm_of_2seq s1 s2 * perm_of_2seq s2 s3)%g = perm_of_2seq s1 s3.
Proof.
move=> us3 s12 s23; have s13 := perm_eq_trans s12 s23.
apply/permP => /= i; rewrite permE /=; apply/val_inj/eqP => /=.
rewrite -(@nth_uniq _ (tnth_default s1 i) s3) ?size_tuple // -!tnth_nth.
by rewrite !perm_of_2seqE.
Qed.

Lemma delta_comp (i j k : seq nat) :
  uniq k -> perm_eq i j -> perm_eq j k ->
  delta i k = delta i j * delta j k.
Proof.
move=> uk pij pjk; have pik := perm_eq_trans pij pjk.
have [sj si] := (perm_eq_size pjk, perm_eq_size pik).
rewrite !(@deltaE (size k)) pik pij pjk /=.
rewrite (perm_eq_uniq pij) (perm_eq_uniq pjk) uk.
by rewrite -signr_addb -odd_permM perm_of_2seq_comp.
Qed.

End delta.

Section Normal.

Lemma submx_add_cap (F : fieldType) (m1 m2 m3 n : nat)
   (A : 'M[F]_(m1, n)) (B : 'M_(m2, n)) (C : 'M_(m3, n)) :
  (A :&: B + A :&: C <= A :&: (B + C))%MS.
Proof.
apply/rV_subP => x /sub_addsmxP [[u v] /= ->]; rewrite sub_capmx.
by rewrite addmx_sub_adds ?addmx_sub ?mulmx_sub ?capmxSl ?capmxSr.
Qed.

Lemma submx_sum_cap (F : fieldType) (k m1 n : nat)
   (A : 'M[F]_(m1, n)) (B_ : 'I_k -> 'M_n) :
   (\sum_i (A :&: B_ i) <= A :&: \sum_i B_ i)%MS.
Proof.
elim/big_ind2: _; rewrite ?capmx0 => //=.
by move=> ???? /addsmxS H /H /submx_trans -> //; apply: submx_add_cap.
Qed.

Variable (R : fieldType) (n : nat).

Print Canonical Projections.

Let dim := #|{set 'I_n}|.
Definition exterior := 'rV[R]_dim.
Canonical exterior_eqType := [eqType of exterior].
Canonical exterior_choiceType := [choiceType of exterior].
Canonical exterior_zmodType := [zmodType of exterior].

Definition sign (A B : {set 'I_n}) : R :=
  let s (A : {set 'I_n}) := [seq val x | x <- enum A] in
  let deltas s := delta R s (sort leq s) in
  deltas (s A) * deltas (s B) * deltas (s (A :|: B)).

Lemma signND (A B : {set 'I_n}) : ~~ [disjoint A & B] -> sign A B = 0.
Proof. Admitted.

Definition blade A : exterior := (delta_mx 0 (enum_rank A)).

Definition mul_ext (u v : exterior) : exterior :=
  \sum_(su : {set 'I_n})
   \sum_(sv : {set 'I_n})
   (u 0 (enum_rank su) * v 0 (enum_rank sv) * sign su sv) *: blade (su :|: sv).

Local Notation "*w%R" := (@mul_ext _).
Local Notation "u *w w" := (mul_ext u w) (at level 40).

Definition extn r : 'M[R]_dim :=
 (\sum_(s : {set 'I_n} | #|s| == r) <<blade s>>)%MS.

Lemma dim_extn r : \rank (extn r) = 'C(n, r).
Proof.
rewrite (mxdirectP _) /=; last first.
  by rewrite mxdirect_delta // => i ???; apply: enum_rank_inj.
rewrite (eq_bigr (fun=> 1%N)); last first.
  by move=> s _; rewrite mxrank_gen mxrank_delta.
by rewrite sum1dep_card card_draws card_ord.
Qed.

Lemma dim_exterior : \rank (1%:M : 'M[R]_dim) = (2 ^ n)%N.
Proof.
rewrite mxrank1 /dim (@eq_card _ _ (mem (powerset [set: 'I_n]))); last first.
  by move=> A; rewrite !inE subsetT.
by rewrite card_powerset cardsT card_ord.
Qed.

Lemma mxdirect_extn : mxdirect (\sum_(i < n.+1) extn i).
Proof.
have card_small (A : {set 'I_n}) : #|A| < n.+1.
  by rewrite ltnS (leq_trans (max_card _)) ?card_ord.
apply/mxdirectP=> /=; rewrite -(@partition_big _ _ _ _ _ xpredT 
          (fun A => Ordinal (card_small A)) xpredT) //=.
rewrite (mxdirectP _) ?mxdirect_delta //=; last by move=> ????/enum_rank_inj.
by rewrite (@partition_big _ _ _ _ _ xpredT 
          (fun A => Ordinal (card_small A)) xpredT) //=.
Qed.

Lemma extnn : (\sum_(i < n.+1) extn i :=: 1%:M)%MS.
Proof.
apply/eqmxP; rewrite -mxrank_leqif_eq ?submx1 // dim_exterior /extn.
rewrite (expnDn 1 1) (mxdirectP _) /=; last exact mxdirect_extn.
apply/eqP/eq_bigr => i _; rewrite (eq_bigr (fun=> 1%N)); last first.
  by move=> A _; rewrite mxrank_gen mxrank_delta.
by rewrite sum1dep_card /= card_draws card_ord !exp1n !muln1.
Qed.

Lemma mul_extnV (u v : exterior) r s : (u <= extn r)%MS -> (v <= extn s)%MS ->
  (u *w v)  = 0.

Lemma mul_extE (u v : exterior) (A : {set 'I_n}) :
  (u *w v) 0 (enum_rank A) = 
  \sum_(s in powerset A)
   (u 0 (enum_rank s) * v 0 (enum_rank (A :\: s)) * sign s (A :\: s)).
Proof.
have bm := (@big_morph _ _ (fun M : 'M__ => M 0 _) 0 +%R); move=> [:mid mop].
rewrite [LHS]bm; last first.
- by abstract: mid; rewrite mxE.
- by abstract: mop; move=> ??; rewrite mxE.
rewrite (bigID (mem (powerset A))) /= [X in _ + X]big1 ?addr0 /=; last first.
  move=> su; rewrite inE => NsuA.
  rewrite bm ?big1 => // sv _; rewrite !mxE /= [_ == _]negbTE ?mulr0 //.
  by apply: contraNneq NsuA => /enum_rank_inj ->; rewrite subsetUl.
apply: eq_bigr => su suA; rewrite bm // (bigD1 (A :\: su)) //= big1 ?addr0.
  rewrite setDE setUIr -setDE setUCr setIT (setUidPr _) -?powersetE //.
  by rewrite !mxE ?eqxx ?mulr1.
move=> sv svNADsu; rewrite !mxE /=.
have [duv|Nduv]:= boolP [disjoint su & sv]; last first.
  by rewrite signND ?(mulr0,mul0r).
rewrite [_ == _]negbTE ?mulr0 //.
apply: contraNneq svNADsu => /enum_rank_inj ->.
by rewrite setDUl setDv set0U (setDidPl _) // disjoint_sym.
Qed.

Definition id_ext : exterior := blade set0. 

Delimit Scope ext_scope with ext.
Local Open Scope ext_scope.
Local Notation "\prod_ ( i | P ) B" :=
  (\big[mul_ext/id_ext]_(i | P) B%ext) : ext_scope.
Local Notation "\prod_ ( i < n | P ) B" :=
  (\big[mul_ext/id_ext]_(i < n | P) B%ext) : ext_scope.
Local Notation "\prod_ ( i <- r | P ) B" :=
  (\big[mul_ext/id_ext]_(i <- r | P) B%ext) : ext_scope.
Local Notation "\prod_ i B" :=
  (\big[mul_ext/id_ext]_i B%ext) : ext_scope.
Local Notation "\prod_ ( i < n ) B" :=
  (\big[mul_ext/id_ext]_(i < n) B%ext) : ext_scope.
Local Notation "\prod_ ( i <- r ) B" :=
  (\big[mul_ext/id_ext]_(i <- r) B%ext) : ext_scope.

Definition to_ext (x : 'rV_n) : exterior := 
  \sum_(i : 'I_n) (x 0 i) *: blade [set i].

(* Lemma to_ext1 (u : 'rV_n) : (to_ext u <= extn 1%N)%MS. *)

Definition form r := 'M[R]_(r,n) -> R.

Definition form_of r (u : exterior) : 'M_(r,n) -> R := fun v : 'M_(r,n) =>
  \sum_(s : {set 'I_n} | #|s| == r)
     u 0 (enum_rank s) * (\prod_i to_ext (row i v))%ext 0 (enum_rank s).

Definition canon_enum (s : {set 'I_n}) : seq 'I_n :=
  sort (fun i j : 'I_n => i <= j) (enum s).

(* Hypothesis ff : False. *)

(* Definition size_canon_enum (s : {set 'I_n}) : size (canon_enum s) == n. *)
(* Proof. by have := ff. Qed. *)

(* Definition canon_tuple (s : {set 'I_n}) := Tuple (size_canon_enum s). *)

Definition ext_of_form r (i0 : 'I_n) (f : 'M[R]_(r,n) -> R) : exterior :=
  \sum_(s : {set 'I_n} | #|s| == r)
   f (\matrix_(i < r) delta_mx 0 (nth i0 (canon_enum s) i)) *: blade s.

(* Lemma ext_of_formK r (i0 : 'I_n) (f : 'M[R]_(r,n) -> R) : *)
(*   form_of (ext_of_form i0 f) =1 f. *)
(* Proof. *)
(* move=> v. *)
(* rewrite /form_of /ext_of_form /=. *)

(* Lemma mul_extDr :  (u v : exterior) (A : {set 'I_n}) : *)