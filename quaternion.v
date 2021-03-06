(* coq-robot (c) 2017 AIST and INRIA. License: LGPL v3. *)
From mathcomp Require Import ssreflect ssrfun ssrbool eqtype ssrnat seq choice.
From mathcomp Require Import fintype tuple finfun bigop ssralg ssrint div.
From mathcomp Require Import ssrnum rat poly closed_field polyrcf matrix.
From mathcomp Require Import mxalgebra tuple mxpoly zmodp binomial realalg.
From mathcomp Require Import complex finset fingroup perm.

Require Import ssr_ext euclidean3 angle vec_angle frame rot.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Local Open Scope ring_scope.

Import GRing.Theory Num.Theory.

(*
1. section quaternion
  - definition of quaternions
  - definition of addition, negation -> quaternions form a zmodtype
  - definition of multiplication -> quaternions form a ring
  - definition of scaling -> quaternions form a lmodtype
  - definition of inverse -> quaternions form a unitringtype
  - definition of conjugate, norm
  - definition of unit quaternions
  - definition of rotation using unit quaternions
2. section dual_number
3. section dual_quaternion
*)

Reserved Notation "x %:q" (at level 2, format "x %:q").
Reserved Notation "x %:v" (at level 2, format "x %:v").
Reserved Notation "Q '`0'" (at level 1, format "Q '`0'").
Reserved Notation "Q '`1'" (at level 1, format "Q '`1'").
Reserved Notation "Q '_i'" (at level 1, format "Q '_i'").
Reserved Notation "Q '_j'" (at level 1, format "Q '_j'").
Reserved Notation "Q '_k'" (at level 1, format "Q '_k'").
Reserved Notation "'`i'".
Reserved Notation "'`j'".
Reserved Notation "'`k'".
Reserved Notation "x '^*q'" (at level 2, format "x '^*q'").
Reserved Notation "a *`i" (at level 3).
Reserved Notation "a *`j" (at level 3).
Reserved Notation "a *`k" (at level 3).
Reserved Notation "x '^*dq'" (at level 2, format "x '^*dq'").

Section quaternion0.
Variable R : ringType.

Record quat := mkQuat {quatl : R ; quatr : 'rV[R]_3 }.

Local Notation "x %:q" := (mkQuat x 0).
Local Notation "x %:v" := (mkQuat 0 x).
Local Notation "'`i'" := ('e_0)%:v.
Local Notation "'`j'" := ('e_1)%:v.
Local Notation "'`k'" := ('e_2%:R)%:v.
Local Notation "Q '`0'" := (quatl Q).
Local Notation "Q '`1'" := (quatr Q).
Local Notation "Q '_i'" := ((quatr Q)``_0).
Local Notation "Q '_j'" := ((quatr Q)``_1).
Local Notation "Q '_k'" := ((quatr Q)``_(2%:R : 'I_3)).

Definition pair_of_quat (a : quat) := let: mkQuat a0 a1 := a in (a0, a1).
Definition quat_of_pair (x : R * 'rV[R]_3) := let: (x0, x1) := x in mkQuat x0 x1.

Lemma quat_of_pairK : cancel pair_of_quat quat_of_pair.
Proof. by case. Qed.

Definition quat_eqMixin := CanEqMixin quat_of_pairK.
Canonical Structure quat_eqType := EqType quat quat_eqMixin.
Definition quat_choiceMixin := CanChoiceMixin quat_of_pairK.
Canonical Structure quat_choiceType := ChoiceType quat quat_choiceMixin.

Lemma eq_quat (a b : quat) : (a == b) = (a`0 == b`0) && (a`1 == b`1).
Proof.
case: a b => [a0 a1] [b0 b1] /=.
apply/idP/idP => [/eqP [ -> ->]|/andP[/eqP -> /eqP -> //]]; by rewrite !eqxx.
Qed.

Definition addq (a b : quat) := mkQuat (a`0 + b`0) (a`1 + b`1).

Lemma addqC : commutative addq.
Proof. move=> *; congr mkQuat; by rewrite addrC. Qed.

Lemma addqA : associative addq.
Proof. move=> *; congr mkQuat; by rewrite addrA. Qed.

Lemma add0q : left_id 0%:q addq.
Proof. case=> *; by rewrite /addq /= 2!add0r. Qed.

Definition oppq (a : quat) := mkQuat (- a`0) (- a`1).

Lemma addNq : left_inverse 0%:q oppq addq.
Proof. move=> *; congr mkQuat; by rewrite addNr. Qed.

Definition quat_ZmodMixin := ZmodMixin addqA addqC add0q addNq.
Canonical quat_ZmodType := ZmodType quat quat_ZmodMixin.

Lemma addqE (a b : quat) : a + b = addq a b. Proof. done. Qed.

Lemma oppqE (a : quat) : - a = oppq a. Proof. done. Qed.

Local Notation "a *`i" := (mkQuat 0 (a *: 'e_0)) (at level 3).
Local Notation "a *`j" := (mkQuat 0 (a *: 'e_1)) (at level 3).
Local Notation "a *`k" := (mkQuat 0 (a *: 'e_2%:R)) (at level 3).

Lemma quatE (a : quat) : a = (a`0)%:q + a _i *`i + a _j *`j + a _k *`k.
Proof.
apply/eqP; rewrite eq_quat /= !addr0 eqxx /= add0r.
by case: a => /= _ v; rewrite {1}[v]vec3E.
Qed.

Lemma quat_scalarE (a b : R) : (a%:q == b%:q) = (a == b).
Proof. by apply/idP/idP => [/eqP[] ->|/eqP -> //]. Qed.

Lemma quat_realD (x y : R) : (x + y)%:q = x%:q + y%:q.
Proof. by rewrite addqE /addq /= addr0. Qed.

Lemma quat_vectD (x y : 'rV[R]_3) : (x + y)%:v = x%:v + y%:v.
Proof. by rewrite addqE /addq /= addr0. Qed.

End quaternion0.

Delimit Scope quat_scope with quat.
Local Open Scope quat_scope.

Notation "x %:q" := (mkQuat x 0) : quat_scope.
Notation "x %:v" := (mkQuat 0 x) : quat_scope.
Notation "'`i'" := ('e_0)%:v : quat_scope.
Notation "'`j'" := ('e_1)%:v : quat_scope.
Notation "'`k'" := ('e_2%:R)%:v : quat_scope.
Notation "Q '`0'" := (quatl Q) : quat_scope.
Notation "Q '`1'" := (quatr Q) : quat_scope.
Notation "Q '_i'" := ((quatr Q)``_0) : quat_scope.
Notation "Q '_j'" := ((quatr Q)``_1) : quat_scope.
Notation "Q '_k'" := ((quatr Q)``_(2%:R : 'I_3)) : quat_scope.
Notation "a *`i" := (mkQuat 0 (a *: 'e_0)) : quat_scope.
Notation "a *`j" := (mkQuat 0 (a *: 'e_1)) : quat_scope.
Notation "a *`k" := (mkQuat 0 (a *: 'e_2%:R)) : quat_scope.

Section quaternion.
Variable R : comRingType.

Definition mulq (a b : quat R) :=
  mkQuat (a`0 * b`0 - a`1 *d b`1) (a`0 *: b`1 + b`0 *: a`1 + a`1 *v b`1).

Lemma mulqA : associative mulq.
Proof.
move=> [a a'] [b b'] [c c']; congr mkQuat => /=.
- rewrite mulrDr mulrDl mulrA -!addrA; congr (_ + _).
  rewrite mulrN !dotmulDr !dotmulDl !opprD !addrA dot_crossmulC; congr (_ + _).
  rewrite addrC addrA; congr (_ + _ + _).
  by rewrite mulrC dotmulvZ mulrN.
  by rewrite dotmulZv.
  by rewrite dotmulvZ dotmulZv.
- rewrite 2![in LHS]scalerDr 1![in RHS]scalerDl scalerA.
  rewrite -4![in LHS]addrA -3![in RHS]addrA; congr (_ + _).
  rewrite [in RHS]scalerDr [in RHS]addrCA -[in RHS]addrA -[in LHS]addrA; congr (_ + _).
    by rewrite scalerA mulrC -scalerA.
  rewrite [in RHS]scalerDr [in LHS]scalerDl [in LHS]addrCA -[in RHS]addrA -addrA; congr (_ + _).
    by rewrite scalerA mulrC.
  rewrite (addrC (a *: _)) linearD /= (addrC (a' *v _)) linearD /=.
  rewrite -![in LHS]addrA ![in LHS]addrA (addrC (- _ *: a')) -![in LHS]addrA; congr (_ + _).
    by rewrite linearZ.
  rewrite [in RHS]crossmulC linearD /= opprD [in RHS]addrCA ![in LHS]addrA addrC -[in LHS]addrA.
  congr (_ + _); first by rewrite linearZ /= crossmulC scalerN.
  rewrite addrA addrC linearD /= opprD [in RHS]addrCA; congr (_ + _).
    by rewrite !linearZ /= crossmulC.
  rewrite 2!double_crossmul opprD opprK [in RHS]addrC addrA; congr (_ + _); last first.
    by rewrite scaleNr.
  by rewrite dotmulC scaleNr; congr (_ + _); rewrite dotmulC.
Qed.

Lemma mul1q : left_id 1%:q mulq.
Proof.
case=> a a'; rewrite /mulq /=; congr mkQuat; Simp.r => /=.
  by rewrite dotmul0v subr0.
by rewrite crossmul0v addr0.
Qed.

Lemma mulq1 : right_id 1%:q mulq.
Proof.
case=> a a'; rewrite /mulq /=; congr mkQuat; Simp.r => /=.
  by rewrite dotmulv0 subr0.
by rewrite crossmulv0 addr0.
Qed.

Lemma mulqDl : left_distributive mulq (@addq R).
Proof.
move=> [a a'] [b b'] [c c']; rewrite /mulq /=; congr mkQuat => /=.
  by rewrite [in RHS]addrCA 2!addrA -mulrDl (addrC a) dotmulDl opprD addrA.
rewrite scalerDl -!addrA; congr (_ + _).
rewrite [in RHS](addrCA (a' *v c')) [in RHS](addrCA (c *: a')); congr (_ + _).
rewrite scalerDr -addrA; congr (_ + _).
rewrite addrCA; congr (_ + _).
by rewrite crossmulC linearD /= crossmulC opprD opprK (crossmulC b').
Qed.

Lemma mulqDr : right_distributive mulq (@addq R).
Proof.
move=> [a a'] [b b'] [c c']; rewrite /mulq /=; congr mkQuat => /=.
  rewrite mulrDr -!addrA; congr (_ + _).
  rewrite addrCA; congr (_ + _).
  by rewrite dotmulDr opprD.
rewrite scalerDr -!addrA; congr (_ + _).
rewrite [in RHS](addrCA (a' *v b')) [in RHS](addrCA (b *: a')); congr (_ + _).
rewrite scalerDl -addrA; congr (_ + _).
by rewrite addrCA linearD.
Qed.

Lemma oneq_neq0 : 1%:q != 0 :> quat R.
Proof. apply/eqP => -[]; apply/eqP. exact: oner_neq0. Qed.

Definition quat_RingMixin := RingMixin mulqA mul1q mulq1 mulqDl mulqDr oneq_neq0.
Canonical Structure quat_Ring := Eval hnf in RingType (quat R) quat_RingMixin.

Lemma mulqE a b : a * b = mulq a b. Proof. done. Qed.

Lemma quat_realM (x y : R) : (x * y)%:q = x%:q * y%:q.
Proof.
by rewrite mulqE /mulq /= dotmul0v subr0 scaler0 add0r scaler0 crossmulv0 addr0.
Qed.

Lemma iiN1 : `i * `i = -1.
Proof.
rewrite mulqE /mulq /= scale0r crossmulvv dotmulE sum3E !mxE /=; Simp.r => /=; congr mkQuat.
by rewrite /= oppr0.
Qed.

Lemma ikNj : `i * `k = - `j.
Proof.
rewrite mulqE /mulq /= 2!scale0r dotmulE sum3E !mxE /= crossmulE !mxE /=. Simp.r.
congr mkQuat; first by Simp.r.
by apply/rowP => -[[|[|[|?]]] ?] //=; rewrite !mxE //=; Simp.r.
Qed.

Definition scaleq k (a : quat R) := mkQuat (k * a`0) (k *: a`1).

Lemma scaleqA a b w : scaleq a (scaleq b w) = scaleq (a * b) w.
Proof. rewrite /scaleq /=; congr mkQuat; by [rewrite mulrA | rewrite scalerA]. Qed.

Lemma scaleq1 : left_id 1 scaleq.
Proof.
by move=> q; rewrite /scaleq mul1r scale1r; apply/eqP; rewrite eq_quat /= !eqxx.
Qed.

Lemma scaleqDr : @right_distributive R (quat R) scaleq +%R.
Proof. move=> a b c; by rewrite /scaleq /= mulrDr scalerDr. Qed.

Lemma scaleqDl w : {morph (scaleq^~ w : R -> quat R) : a b / a + b}.
Proof. move=> m n; rewrite /scaleq mulrDl /= scalerDl; congr mkQuat. Qed.

Definition quat_lmodMixin := LmodMixin scaleqA scaleq1 scaleqDr scaleqDl.
Canonical quat_lmodType := Eval hnf in LmodType R (quat R) quat_lmodMixin.

Lemma scaleqE (k : R) (a : quat R) :
  k *: a = k *: (a `0) %:q + k *: (a _i) *`i + k *: (a _j) *`j + k *: (a _k) *`k.
Proof.
apply/eqP; rewrite eq_quat //=; Simp.r.
by rewrite {1}[a`1]vec3E -!scalerDr.
Qed.

End quaternion.

Lemma ijk (R : comUnitRingType) : `i * `j = `k :> quat R.
Proof.
by apply/eqP; rewrite eq_quat /=; Simp.r; rewrite vecij dote2; Simp.r.
Qed.

Section quaternion1.
Variable R : rcfType.

Definition sqrq (a : quat R) := a`0 ^+ 2 + norm (a`1) ^+ 2.

Lemma sqrq_eq0 a : (sqrq a == 0) = (a == 0).
Proof.
case: a => a a' /=; apply/idP/idP.
  by rewrite /sqrq /= paddr_eq0 ?sqr_ge0 // ?norm_ge0 // 2!sqrf_eq0 norm_eq0 => /andP[/eqP -> /eqP ->].
by case/eqP => -> ->; rewrite /sqrq /= norm0 expr0n addr0.
Qed.

Definition conjq (a : quat R) := mkQuat (a`0) (- a`1).
Local Notation "x '^*q'" := (conjq x).

Lemma conjq_linear : linear conjq.
Proof.
move=> /= k [a0 a1] [b0 b1] /=; rewrite [in LHS]/conjq /= [in RHS]/conjq /=.
rewrite scaleqE /= addqE /= /addq /= !mxE !(mulr0,addr0,scaler0,add0r).
congr mkQuat; rewrite opprD; congr (_ - _).
by rewrite -2!scalerDr !scaleNr -!opprD -vec3E -scalerN.
Qed.

Canonical conjq_is_additive := Additive conjq_linear.
Canonical conjq_is_linear := AddLinear conjq_linear.

Lemma conjqI a : (a^*q)^*q = a.
Proof. by case: a => a0 a1; rewrite /conjq /= opprK. Qed.

Lemma conjq0 : (0%:v)^*q = 0.
Proof. apply/eqP; by rewrite eq_quat /= oppr0 !eqxx. Qed.

Lemma conjqP a : a * a^*q = (sqrq a)%:q.
Proof.
rewrite /mulq /=; congr mkQuat.
  by rewrite /= dotmulvN dotmulvv opprK -expr2.
by rewrite scalerN addNr add0r crossmulvN crossmulvv oppr0.
Qed.

Lemma conjqM a b : (a * b)^*q = b^*q * a^*q.
Proof.
case: a b => [a0 a1] [b0 b1].
rewrite /conjq /= mulqE /mulq /= mulrC dotmulC dotmulvN dotmulNv opprK; congr mkQuat.
by rewrite 2!opprD 2!scalerN linearN /= -(crossmulC a1) linearN /= -2!scaleNr -addrA addrCA addrA.
Qed.

Lemma conjqE a : a^*q = - (1 / 2%:R) *: (a + `i * a * `i + `j * a * `j + `k * a * `k).
Proof.
apply/eqP; rewrite eq_quat; apply/andP; split; apply/eqP.
  rewrite [in LHS]/= scaleqE /=.
  rewrite !(mul0r,mulr0,addr0) scale0r !add0r !dotmulDl.
  rewrite dotmulZv dotmulvv normeE expr1n mulr1 dotmulC dot_crossmulC crossmulvv dotmul0v addr0.
  rewrite subrr add0r dotmulZv dotmulvv normeE expr1n mulr1 dotmulC dot_crossmulC crossmulvv.
  rewrite dotmul0v addr0 dotmulZv dotmulvv normeE expr1n mulr1 opprD addrA dotmulC dot_crossmulC.
  rewrite crossmulvv dotmul0v subr0 -opprD mulrN mulNr opprK -mulr2n -(mulr_natl (a`0)) mulrA.
  by rewrite div1r mulVr ?mul1r // unitfE pnatr_eq0.
rewrite /=.
rewrite !(mul0r,scale0r,add0r,addr0).
rewrite [_ *v 'e_0]crossmulC ['e_0 *v _]linearD /= ['e_0 *v _]linearZ /= crossmulvv.
rewrite scaler0 add0r double_crossmul dotmulvv normeE expr1n scale1r.
rewrite [_ *v 'e_1]crossmulC ['e_1 *v _]linearD /= ['e_1 *v _]linearZ /= crossmulvv.
rewrite scaler0 add0r double_crossmul dotmulvv normeE expr1n scale1r.
rewrite [_ *v 'e_2%:R]crossmulC ['e_2%:R *v _]linearD /= ['e_2%:R *v _]linearZ /= crossmulvv.
rewrite scaler0 add0r double_crossmul dotmulvv normeE expr1n scale1r.
rewrite [X in _ = - _ *: X](_ : _ = 2%:R *:a`1).
  by rewrite scalerA mulNr div1r mulVr ?unitfE ?pnatr_eq0 // scaleN1r.
rewrite !opprB (addrCA _ a`1) addrA -mulr2n scaler_nat -[RHS]addr0 -3!addrA; congr (_ + _).
do 3 rewrite (addrCA _ a`1).
do 2 rewrite addrC -!addrA.
rewrite -opprB (scaleNr _ 'e_0) opprK -mulr2n addrA -mulr2n.
rewrite addrC addrA -opprB scaleNr opprK -mulr2n.
rewrite opprD.
rewrite (addrCA (- _ *: 'e_2%:R)).
rewrite -opprB scaleNr opprK -mulr2n.
rewrite -!mulNrn -3!mulrnDl -scaler_nat.
apply/eqP; rewrite scalemx_eq0 pnatr_eq0 /=.
rewrite addrA addrC eq_sym -subr_eq add0r opprB opprD 2!opprK.
rewrite !['e__ *d _]dotmulC !dotmul_delta_mx /=.
by rewrite addrA addrAC -addrA addrC [X in _ == X]vec3E.
Qed.

Lemma conjq_scalar a : (a`0)%:q = (1 / 2%:R) *: (a + a^*q).
Proof.
case: a => a0 a1.
rewrite /conjq /= addqE /addq /= subrr quat_realD scalerDr -scalerDl.
by rewrite -mulr2n -mulr_natr div1r mulVr ?scale1r // unitfE pnatr_eq0.
Qed.

Lemma conjq_vector a : (a`1)%:v = (1 / 2%:R) *: (a - a^*q).
Proof.
case: a => a0 a1.
rewrite /conjq /= addqE /addq /= subrr opprK quat_vectD scalerDr -scalerDl.
by rewrite -mulr2n -mulr_natr div1r mulVr ?scale1r // unitfE pnatr_eq0.
Qed.

Definition invq a := (1 / sqrq a) *: (a ^*q).

Definition unitq : pred (quat R) := [pred a | a != 0%:q].

Lemma mulVq : {in unitq, left_inverse 1 invq (@mulq R)}.
Proof.
move=> a; rewrite inE /= => a0.
rewrite /invq /mulq /=; congr mkQuat.
  rewrite dotmulZv -mulrA -mulrBr dotmulNv opprK dotmulvv.
  by rewrite div1r mulVr // unitfE sqrq_eq0.
rewrite scalerA scalerN -scalerBl mulrC subrr scale0r.
by rewrite scalerN crossmulNv crossmulZv crossmulvv scaler0 subrr.
Qed.

Lemma mulqV : {in unitq, right_inverse 1 invq (@mulq R)}.
Proof.
move=> a; rewrite inE /= => a0.
rewrite /invq /mulq /=; congr mkQuat.
  by rewrite scalerN dotmulvN opprK dotmulvZ mulrCA -mulrDr dotmulvv div1r mulVr // unitfE sqrq_eq0.
by rewrite scalerA scalerN -scaleNr -scalerDl mulrC addNr scale0r linearZ /= crossmulvN crossmulvv scalerN scaler0 subrr.
Qed.

Lemma unitqP a b : b * a = 1 /\ a * b = 1 -> unitq a.
Proof.
move=> [ba1 ab1]; rewrite /unitq inE; apply/eqP => x0.
move/esym: ab1; rewrite x0 mul0r.
apply/eqP; exact: oneq_neq0.
Qed.

Lemma invq0id : {in [predC unitq], invq =1 id}.
Proof.
move=> a; rewrite !inE negbK => /eqP ->.
by rewrite /invq /= conjq0 scaler0.
Qed.

Definition quat_UnitRingMixin := UnitRingMixin mulVq mulqV unitqP invq0id.
Canonical quat_unitRing := UnitRingType (quat R) quat_UnitRingMixin.

Lemma invqE a : a^-1 = invq a. Proof. by done. Qed.

Definition normq (a : quat R) : R := Num.sqrt (sqrq a).

Lemma normq0 : normq 0 = 0.
Proof. by rewrite /normq /sqrq expr0n /= norm0 add0r expr0n sqrtr0. Qed.

Lemma normqc a : normq a^*q = normq a.
Proof. by rewrite /normq /sqrq /= normN. Qed.

Lemma normqE a : (normq a ^+ 2)%:q = a^*q * a.
Proof.
rewrite -normqc /normq sqr_sqrtr; last by rewrite /sqrq addr_ge0 // sqr_ge0.
by rewrite -conjqP conjqI.
Qed.

Lemma normq_ge0 a : normq a >= 0.
Proof. by apply sqrtr_ge0. Qed.

Lemma normq_eq0 a : (normq a == 0) = (a == 0).
Proof.
rewrite /normq /sqrq -sqrtr0 eqr_sqrt //; last by rewrite addr_ge0 // sqr_ge0.
by rewrite paddr_eq0 ?sqr_ge0 // 2!sqrf_eq0 norm_eq0 eq_quat.
Qed.

Lemma quatAl k (a b : quat R) : k *: (a * b) = k *: a * b.
Proof.
case: a b => [a0 a1] [b0 b1]; apply/eqP.
rewrite !mulqE /mulq /= scaleqE /= eq_quat /=.
apply/andP; split; first by rewrite mulr0 !addr0 mulrBr mulrA dotmulZv.
apply/eqP.
rewrite scaler0 add0r -2!scalerDr -vec3E -scalerA (scalerA b0 k) mulrC.
rewrite -scalerA [in RHS]crossmulC [in X in _ = _ + _ + X]linearZ /=.
by rewrite -scalerDr -scalerBr crossmulC.
Qed.

Canonical quat_lAlgType := Eval hnf in LalgType _ (quat R) quatAl.

Lemma quatAr k (a b : quat R) : k *: (a * b) = a * (k *: b).
Proof.
case: a b => [a0 a1] [b0 b1]; apply/eqP.
rewrite !mulqE /mulq /= scaleqE /= eq_quat /=.
apply/andP; split; first by rewrite mulr0 !addr0 mulrBr mulrCA dotmulvZ.
apply/eqP.
rewrite scaler0 add0r -2!scalerDr -vec3E -scalerA (scalerA a0 k) mulrC.
by rewrite -scalerA [in X in _ = _ + _ + X]linearZ /= -2!scalerDr.
Qed.

Canonical quat_algType := Eval hnf in AlgType _ (quat R) quatAr.

Lemma quat_algE x : x%:q = x%:A.
Proof.
apply/eqP.
rewrite scaleqE !mxE eq_quat /= mulr0 mulr1 !addr0 eqxx /= scaler0 add0r.
by Simp.r.
Qed.

Lemma normqM (Q P : quat R) : normq (Q * P) = normq Q * normq P.
Proof.
apply/eqP; rewrite -(@eqr_expn2 _ 2) // ?normq_ge0 //; last first.
  by rewrite mulr_ge0 // normq_ge0.
rewrite -quat_scalarE normqE conjqM -mulrA (mulrA (Q^*q)) -normqE.
rewrite quat_algE mulr_algl -scalerAr exprMn quat_realM.
by rewrite (normqE P) -mulr_algl quat_algE.
Qed.

Lemma normqZ (k : R) (q : quat R) : normq (k *: q) = `|k| * normq q.
Proof.
by rewrite /normq /sqrq /= normZ 2!exprMn sqr_normr -mulrDr sqrtrM ?sqr_ge0 // sqrtr_sqr.
Qed.

Lemma normqV (q : quat R) : normq (q^-1) = normq q / sqrq q.
Proof.
rewrite invqE /invq normqZ ger0_norm; last first.
  by rewrite divr_ge0 // ?ler01 // /sqrq addr_ge0 // sqr_ge0.
by rewrite normqc mulrC mul1r.
Qed.

Definition normQ Q := (normq Q)%:q.

Lemma normQ_eq0 x : (normQ x == 0) = (x == 0).
Proof. by rewrite /normQ quat_scalarE normq_eq0. Qed.

Definition normalizeq (q : quat R) : quat R := 1 / normq q *: q.

Lemma normalizeq1 (q : quat R) : q != 0 -> normq (normalizeq q) = 1.
Proof.
move=> q0.
rewrite /normalizeq normqZ normrM normr1 mul1r normrV; last by rewrite unitfE normq_eq0.
by rewrite ger0_norm ?normq_ge0 // mulVr // unitfE normq_eq0.
Qed.

Definition lequat (Q P : quat R) :=
  let: mkQuat Q1 Q2 := Q in let: mkQuat P1 P2 := P in
  (Q2 == P2) && (Q1 <= P1).

Lemma lequat_normD x y : lequat (normQ (x + y)) (normQ x + normQ y).
Proof.
Abort.

Definition ltquat (Q P : quat R) :=
  let: mkQuat Q1 Q2 := Q in let: mkQuat P1 P2 := P in
  (Q2 == P2) && (Q1 < P1).

Lemma ltquat0_add : forall x y, ltquat 0 x -> ltquat 0 y -> ltquat 0 (x + y).
Abort.

Lemma ge0_lequat_total x y : lequat 0 x -> lequat 0 y -> lequat x y || lequat y x.
Abort.

Lemma normQM x y : normQ (x * y) = normQ x * normQ y.
Proof. by rewrite {1}/normQ normqM quat_realM. Qed.

Lemma lequat_def x y : lequat x y = (normQ (y - x) == y - x).
Abort.

Lemma ltquat_def x y : ltquat x y = (y != x) && lequat x y.
Abort.

Fail Definition quat_POrderedMixin := NumMixin lequat_normD ltquat0_add eq0_normQ
  ge0_lequat_total normQM lequat_def ltquat_def.
Fail Canonical Structure quat_numDomainType :=
  NumDomainType _ quat_POrderedMixin.

Definition uquat := [qualify x : quat R | normq x == 1].
Fact uquat_key : pred_key uquat. Proof. by []. Qed.
Canonical uquat_keyed := KeyedQualifier uquat_key.

Lemma uquatE a : (a \is uquat) = (normq a == 1).
Proof. done. Qed.

Lemma uquatE' (q : quat R) : (q \is uquat) = (sqrq q == 1).
Proof.
apply/idP/idP => [qu|].
  rewrite -eqr_sqrt ?ler01 //.
    rewrite uquatE in qu; by rewrite -/(normq q) (eqP qu) sqrtr1.
  by rewrite /sqrq addr_ge0 // sqr_ge0.
rewrite uquatE /normq => /eqP ->; by rewrite sqrtr1.
Qed.

Lemma muluq_proof a b : a \is uquat -> b \is uquat -> a * b \is uquat.
Proof. rewrite 3!uquatE => /eqP Hq /eqP Hp; by rewrite normqM Hq Hp mulr1. Qed.

Lemma invuq_proof a : a \is uquat -> normq (a^-1) == 1.
Proof.
move=> Hq; rewrite normqV.
move: (Hq); rewrite uquatE => /eqP ->.
move: Hq; rewrite uquatE' => /eqP ->.
by rewrite invr1 mulr1.
Qed.

Lemma invq_uquat a : a \is uquat -> a^-1 = a^*q.
Proof.
rewrite uquatE' => /eqP Hq; by rewrite invqE /invq Hq invr1 mul1r scale1r.
Qed.

Definition polar_of_quat (a : quat R) : 'rV[R]_3 * angle R :=
  (normalize a`1, atan (norm a`1 / a`0)).

Lemma norm_polar_of_uquat q : q \is uquat ->
  let: (u, a) := polar_of_quat q in
  normq (mkQuat (cos a) (sin a *: u)) = 1.
Proof.
move=> Hq.
case: q Hq => [q0 q1] nq.
case/boolP : (q1 == 0) => [/eqP /= ->|q10].
  by rewrite norm0 mul0r atan0 cos0 sin0 scale0r /normq /sqrq /= norm0 expr0n addr0 expr1n sqrtr1.
by rewrite /= /normq /sqrq /= normZ exprMn norm_normalize // expr1n mulr1 sqr_normr cos2Dsin2 sqrtr1.
Qed.

Definition quat_of_polar (a : angle R) (w : 'rV[R]_3) : quat R :=
  mkQuat (cos (half_angle a)) (sin (half_angle a) *: w).

Lemma uquat_of_polar a w (H : norm w = 1) : quat_of_polar a w \is uquat.
Proof.
by rewrite uquatE /normq /sqrq /= normZ exprMn H expr1n mulr1 sqr_normr cos2Dsin2 sqrtr1.
Qed.

Let vector := 'rV[R]_3.

Definition quat_rot (a : quat R) (v : vector) : quat R := (a : quat R) * v%:v * a^*q.

Lemma quat_rotE a v : quat_rot a v =
  ((a`0 ^+ 2 - norm a`1 ^+ 2) *: v +
   ((a`1 *d v) *: a`1) *+ 2 +
   (a`0 *: (a`1 *v v)) *+ 2)%:v.
Proof.
case: a => a0 a1 /=.
rewrite /quat_rot /= /conjq /= mulqE /mulq /=.
rewrite mulr0 scale0r addr0 add0r; congr mkQuat.
  rewrite dotmulvN opprK dotmulDl (dotmulC (_ *v _) a1) dot_crossmulC.
  by rewrite crossmulvv dotmul0v addr0 dotmulZv mulNr mulrC dotmulC addrC subrr.
rewrite scalerDr scalerA -expr2 addrCA scalerBl -!addrA; congr (_ + _).
rewrite [in X in _ + X = _]linearN /= (crossmulC _ a1) linearD /= opprK.
rewrite linearZ /= (addrA (a0 *: _ )) -mulr2n.
rewrite [in LHS]addrCA 2![in RHS]addrA [in RHS]addrC; congr (_ + _).
rewrite scalerN scaleNr opprK -addrA addrCA; congr (_ + _).
by rewrite double_crossmul [in RHS]addrC dotmulvv.
Qed.

Definition pureq (q : quat R) : bool := q`0 == 0.

Lemma quat_rot_is_vector a v : pureq (quat_rot a v).
Proof. by rewrite quat_rotE /pureq /=. Qed.

Lemma quat_rot_is_linear a : linear (fun v => (quat_rot a v)`1).
Proof.
move=> k x y.
rewrite !quat_rotE /= scalerDr scalerA (mulrC _ k) -scalerA.
rewrite 2![in RHS]scalerDr -2![in LHS]addrA -3![in RHS]addrA; congr (_ + _).
rewrite [in RHS]addrA [in RHS]addrCA -[in RHS]addrA; congr (_ + _).
rewrite dotmulDr scalerDl mulrnDl -addrA addrCA; congr (_ + _).
rewrite dotmulvZ -scalerA scalerMnr -addrA; congr (_ + _).
rewrite linearD /= scalerDr mulrnDl; congr (_ + _).
by rewrite linearZ /= scalerA mulrC -scalerA -scalerMnr.
Qed.

Lemma quat_rot_is_linearE q v : Linear (quat_rot_is_linear q) v = (quat_rot q v)`1.
Proof. done. Qed.

Lemma quat_rot_axis q k : q \is uquat -> quat_rot q (k *: q`1) = (k *: q`1)%:v.
Proof.
rewrite uquatE' /sqrq => /eqP q_is_uquat; rewrite quat_rotE.
rewrite [in X in (_ + _ + X)%:v = _]linearZ /= crossmulvv 2!scaler0 mul0rn addr0.
rewrite dotmulvZ dotmulvv scalerBl !scalerA (mulrC (norm _ ^+ 2)) mulr2n addrA.
by rewrite subrK -scalerDl mulrC -mulrDl q_is_uquat mul1r.
Qed.

Lemma cos_atan_uquat q : q \is uquat -> ~~ pureq q ->
  let a := atan (norm q`1 / q`0) in
  cos a ^+ 2 = q`0 ^+ 2.
Proof.
move=> nq q00 a.
rewrite /a cos_atan exprMn expr1n mul1r.
have /divrr <- : q`0 ^+ 2 \in GRing.unit by rewrite unitfE sqrf_eq0.
rewrite uquatE' /sqrq in nq.
rewrite expr_div_n -mulrDl (eqP nq) sqrtrM ?ler01 // sqrtr1 mul1r.
by rewrite -exprVn sqrtr_sqr normrV ?unitfE // invrK sqr_normr.
Qed.

Lemma sin_atan_uquat q : q \is uquat -> ~~ pureq q ->
  let a := atan (norm q`1 / q`0) in
  sin a ^+ 2 = norm q`1 ^+ 2.
Proof.
move=> nq q00 a.
rewrite /a sqr_sin_atan.
have /divrr <- : q`0 ^+ 2 \in GRing.unit by rewrite unitfE sqrf_eq0.
rewrite uquatE' /sqrq in nq.
rewrite expr_div_n -mulrDl.
by rewrite (eqP nq) mul1r invrK -mulrA mulVr ?mulr1 // unitrX // unitfE.
Qed.

Lemma polar_of_uquat_prop q : q \is uquat -> ~~ pureq q ->
  let: a := (polar_of_quat q).2 in
  cos (a *+ 2) = q`0 ^+ 2 - norm q`1 ^+ 2.
Proof.
move=> ? ?; by rewrite mulr2n cosD -2!expr2 cos_atan_uquat // sin_atan_uquat.
Qed.

Lemma polar_of_uquat_prop2 q : q \is uquat -> q`0 != 0 ->
  let: a := (polar_of_quat q).2 in
  sin (a *+ 2) = (q`0 * norm q`1) *+ 2.
Proof.
move=> q_is_uquat q00.
rewrite /= sin_mulr2n cos_atan sin_atan.
set k := Num.sqrt _; congr (_ *+ 2).
have k0 : k \is a GRing.unit.
  by rewrite unitfE sqrtr_eq0 -ltrNge -(addr0 0) ltr_le_add // ?ltr01 // sqr_ge0.
rewrite div1r mulrCA -invrM // [in RHS]mulrC -mulrA; congr (_ * _).
apply (@mulrI _ q`0); first by rewrite unitfE.
rewrite mulrA divrr ?unitfE // mul1r -2!expr2 sqr_sqrtr; last first.
  by rewrite addr_ge0 // ?ler01 // sqr_ge0.
have /divrr <- : q`0 ^+ 2 \is a GRing.unit by rewrite unitrX // unitfE.
rewrite uquatE' /sqrq in q_is_uquat.
by rewrite exprMn exprVn -mulrDl (eqP q_is_uquat) -exprVn mul1r -exprVn invrK.
Qed.

Local Open Scope frame_scope.

Lemma quat_rot_isRot (a : quat R) : a \is uquat -> ~~ pureq a ->
  let: (u, theta) := polar_of_quat a in
  u != 0 ->
  isRot (theta *+ 2) u (Linear (quat_rot_is_linear a)).
Proof.
move=> q_isuqat. rewrite /pureq => a00 a10.
rewrite normalize_eq0 in a10.
set a' := atan _.
apply/isRotP; split.
- set u : 'rV_3 := normalize a`1.
  by rewrite quat_rot_is_linearE quat_rot_axis.
- rewrite /normalize Base.Z ?invr_gt0 ?norm_gt0 //.
  set f := Base.frame a`1.
  rewrite quat_rot_is_linearE quat_rotE /=.
  rewrite (_ : a`1 *d f|,1 = 0); last first.
    move/eqP: (dot_row_of_O (NOFrame.MO f) 0 1).
    by rewrite -2!rowframeE Base.frame0E // dotmulZv mulf_eq0 invr_eq0 norm_eq0 (negbTE a10) /= => /eqP.
  rewrite scale0r mul0rn addr0.
  rewrite (_ : a`1 *v f|,1 = norm a`1 *: f|,2%:R); last first.
    rewrite -Base.kE -Base.icrossj Base.iE Base.jE -crossmulZv Base.frame0E //.
    by rewrite norm_scale_normalize rowframeE.
  rewrite scalerMnl [in X in _ + X = _]scalerA; congr (_ *: _ + _ *: _).
  by rewrite polar_of_uquat_prop.
  by rewrite mulrnAl polar_of_uquat_prop2.
- rewrite /normalize Base.Z ?invr_gt0 ?norm_gt0 //.
  set f := Base.frame a`1.
  rewrite quat_rot_is_linearE quat_rotE /=.
  rewrite (_ : a`1 *d f|,2%:R = 0); last first.
    (* TODO: looks like the above *)
    move/eqP: (dot_row_of_O (NOFrame.MO f) 0 2%:R).
    by rewrite -2!rowframeE Base.frame0E // dotmulZv mulf_eq0 invr_eq0 norm_eq0 (negbTE a10) /= => /eqP.
  rewrite scale0r mul0rn addr0.
  rewrite (_ : a`1 *v f|,2%:R = - norm a`1 *: f|,1); last first.
    rewrite scaleNr -scalerN -Base.jE -Base.icrossk -crossmulZv -Base.kE; congr (_ *v _).
    by rewrite Base.iE Base.frame0E // ?norm_scale_normalize.
  rewrite addrC; congr (_ + _ *: _); last first.
    by rewrite -polar_of_uquat_prop.
  rewrite scaleNr scalerN scalerA mulNrn scalerMnl -scaleNr; congr (_ *: _).
  by rewrite polar_of_uquat_prop2.
Qed.

Lemma quat_rot_isRot_test (u : 'rV[R]_3) (theta : angle R) : norm u = 1 ->
  let a := mkQuat (cos (half_angle theta)) ((sin (half_angle theta)) *: u) in
  isRot (theta *+ 2) u (Linear (quat_rot_is_linear a)).
Proof.
move=> u1 /=.
set a := mkQuat _ _.
have a_uquat : a \is uquat.
  by rewrite uquatE' /sqrq /= normZ exprMn u1 expr1n mulr1 sqr_normr cos2Dsin2.
have a_not_pure : ~~ pureq a.
  admit.
have polar_of_quat1_neq_0 : (polar_of_quat a).1 != 0.
  rewrite /= normalize_eq0 scaler_eq0 negb_or -norm_eq0 u1 oner_neq0 andbT.
  admit.
move: (quat_rot_isRot a_uquat a_not_pure polar_of_quat1_neq_0).
Abort.

End quaternion1.

Notation "x '^*q'" := (conjq x) : quat_scope.

Section dual_number.

Variables (R : ringType).

Record dual := mkDual {ldual : R ; rdual : R }.

Definition dual0 : dual := mkDual 0 0.
Definition dual1 : dual := mkDual 1 0.

Local Notation "x '``0'" := (ldual x) (at level 1, format "x '``0'").
Local Notation "x '``1'" := (rdual x) (at level 1, format "x '``1'").

Definition pair_of_dual (a : dual) := let: mkDual a0 a1 := a in (a0, a1).
Definition dual_of_pair (x : R * R) := let: (x0, x1) := x in mkDual x0 x1.

Lemma dual_of_pairK : cancel pair_of_dual dual_of_pair.
Proof. by case. Qed.

Definition dual_eqMixin := CanEqMixin dual_of_pairK.
Canonical Structure dual_eqType := EqType dual dual_eqMixin.
Definition dual_choiceMixin := CanChoiceMixin dual_of_pairK.
Canonical Structure dual_choiceType := ChoiceType dual dual_choiceMixin.

Definition oppd a := mkDual (- a``0) (- a``1).

Definition deps : 'M[R]_2 :=
  \matrix_(i < 2, j < 2) ((i == 0) && (j == 1))%:R.

Lemma deps2 : deps ^+2 = 0.
Proof.
rewrite expr2; apply/matrixP => i j.
by rewrite !mxE sum2E !mxE /= mulr0 addr0 -ifnot01 eqxx andbF mul0r.
Qed.

Definition mat_of_dual (x : dual) : 'M[R]_2 := x``0%:M + x``1 *: deps.

Definition dual_of_mat (M : 'M[R]_2) := mkDual (M 0 0) (M 0 1).

Definition addd (x y : dual) := dual_of_mat (mat_of_dual x + mat_of_dual y).

Definition muld (x y : dual) := dual_of_mat (mat_of_dual x * mat_of_dual y).

Let adddE' (a b : dual) : addd a b = mkDual (a``0 + b``0) (a``1 + b``1).
Proof.
rewrite /addd /dual_of_mat /mat_of_dual /= !mxE; congr mkDual.
by rewrite !eqxx !(mulr1n,andbF,mulr1,mulr0,addr0).
by rewrite !mulr0n !eqxx !mulr1 !add0r.
Qed.

Let muldE' (a b : dual) : muld a b = mkDual (a``0 * b``0) (a``0 * b``1 + a``1 * b``0).
Proof.
rewrite /muld /dual_of_mat /mat_of_dual /= !mxE !sum2E !mxE; congr mkDual.
by rewrite !eqxx !(mulr0n,mulr1n,mulr0,mulr1,addr0).
by rewrite !eqxx !(mulr0n,mulr1n,mulr0,add0r,addr0,mulr1).
Qed.

Lemma adddA : associative addd.
Proof. move=> x y z; by rewrite !adddE' /= 2!addrA. Qed.

Lemma adddC : commutative addd.
Proof. move=> x y; by rewrite !adddE' /= addrC [in X in mkDual _ X = _]addrC. Qed.

Lemma add0d : left_id dual0 addd.
Proof. move=> x; rewrite adddE' /= 2!add0r; by case: x. Qed.

Lemma addNd : left_inverse dual0 oppd addd.
Proof. move=> x; by rewrite adddE' /= 2!addNr. Qed.

Definition dual_ZmodMixin := ZmodMixin adddA adddC add0d addNd.
Canonical dual_ZmodType := ZmodType dual dual_ZmodMixin.

Lemma muldA : associative muld.
Proof.
move=> x y z; rewrite !muldE' /=; congr mkDual; first by rewrite mulrA.
by rewrite mulrDr mulrDl !mulrA addrA.
Qed.

Lemma mul1d : left_id dual1 muld.
Proof. case=> x0 x1; by rewrite muldE' /= 2!mul1r mul0r addr0. Qed.

Lemma muld1 : right_id dual1 muld.
Proof. case=> x0 x1; by rewrite muldE' /= 2!mulr1 mulr0 add0r. Qed.

Lemma muldDl : left_distributive muld addd.
Proof.
move=> x y z; rewrite !muldE' !adddE' /= mulrDl; congr mkDual.
rewrite mulrDl -!addrA; congr (_ + _); by rewrite mulrDl addrCA.
Qed.

Lemma muldDr : right_distributive muld addd.
Proof.
move=> x y z; rewrite !muldE' !adddE' /= mulrDr; congr mkDual.
rewrite mulrDr -!addrA; congr (_ + _); by rewrite mulrDr addrCA.
Qed.

Lemma oned_neq0 : dual1 != 0 :> dual.
Proof. apply/eqP; case; apply/eqP; exact: oner_neq0. Qed.

Definition dual_RingMixin := RingMixin muldA mul1d muld1 muldDl muldDr oned_neq0.
Canonical Structure dual_Ring := Eval hnf in RingType dual dual_RingMixin.

Lemma adddE (a b : dual) : a + b = mkDual (a``0 + b``0) (a``1 + b``1).
Proof. exact: adddE'. Qed.

Lemma muldE (a b : dual) : a * b = mkDual (a``0 * b``0) (a``0 * b``1 + a``1 * b``0).
Proof. exact: muldE'. Qed.

Definition scaled k (a : dual) := mkDual (k * a``0) (k * a``1).

Lemma scaledA a b w : scaled a (scaled b w) = scaled (a * b) w.
Proof. by rewrite /scaled /=; congr mkDual; rewrite mulrA. Qed.

Lemma scaled1 : left_id 1 scaled.
Proof. rewrite /left_id /scaled /=; case=> a1 a2 /=; by rewrite !mul1r. Qed.

Lemma scaledDr : @right_distributive R dual scaled +%R.
Proof.
move=> a b c; rewrite /scaled; congr mkDual; by rewrite !mxE /=
  !(mulr0,addr0,mulr1n,mulr1,mulr0n,add0r) mxE mulrDr !mxE /=
  !(eqxx,mulr1n,mulr0,addr0,mulr1,mulr0n,add0r).
Qed.

Lemma scaledDl w : {morph (scaled^~ w : R -> dual) : a b / a + b}.
Proof. move=> a b; by rewrite /scaled /= !mulrDl adddE. Qed.

Definition dual_lmodMixin := LmodMixin scaledA scaled1 scaledDr scaledDl.
Canonical dual_lmodType := Eval hnf in LmodType R dual dual_lmodMixin.

End dual_number.

Section dual_number_unit.

Variable (R : unitRingType).

Local Notation "x '``0'" := (ldual x) (at level 1, format "x '``0'").
Local Notation "x '``1'" := (rdual x) (at level 1, format "x '``1'").

Definition unitd : pred (dual R) := [pred a | a``0 \is a GRing.unit].

Definition invd (a : dual R) :=
  if a \in unitd then
    dual_of_mat ((a``0)^-1%:M * (1 - deps R * a``1%:M * (a``0)^-1%:M))
  else
    a.

Lemma mulVd : {in unitd, left_inverse 1 invd (@muld R)}.
Proof.
move=> a0 ua0.
rewrite /invd ua0 /dual_of_mat; congr mkDual.
  rewrite !mxE !sum2E !mxE !sum2E !mxE !sum2E !mxE /=.
  by rewrite !(mul0r,mulr1n,addr0,mulr0,subr0,mulr1) mulVr.
rewrite !mxE !sum2E !mxE !sum2E !mxE !sum2E !mxE /=.
rewrite !(mul0r,mulr1n,addr0,mulr0,subr0,mulr1,mulr0n,add0r,mul1r).
by rewrite !(mulrN,mulNr) -!mulrA mulVr // mulr1 subrr.
Qed.

Lemma muldV : {in unitd, right_inverse 1 invd (@muld R)}.
Proof.
move=> a0 ua0.
rewrite /invd ua0 /dual_of_mat; congr mkDual.
  rewrite !mxE !sum2E !mxE !sum2E !mxE !sum2E !mxE /=.
  by rewrite !(mul0r,mulr1n,addr0,mulr0,subr0,mulr1) divrr.
rewrite !mxE !sum2E !mxE !sum2E !mxE !sum2E !mxE /=.
rewrite !(mul0r,mulr1n,addr0,mulr0,subr0,mulr1,mulr0n,add0r,mul1r).
by rewrite !(mulrN,mulNr) mulrA divrr // mul1r addrC subrr.
Qed.

Lemma unitdP a b : b * a = 1 /\ a * b = 1 -> unitd a.
Proof. rewrite 2!muldE => -[[ba1 _] [ab1 _]]; apply/unitrP; by exists b``0. Qed.

(* The inverse of a non-unit x is constrained to be x itself *)
Lemma invd0id : {in [predC unitd], invd =1 id}.
Proof. move=> a; by rewrite inE /= /invd => /negbTE ->. Qed.

Definition dual_UnitRingMixin := UnitRingMixin mulVd muldV unitdP invd0id.
Canonical dual_unitRing := UnitRingType (dual R) dual_UnitRingMixin.

End dual_number_unit.

Notation "x '..1'" := (ldual x) (at level 1, format "x '..1'") : dual_scope.
Notation "x '..2'" := (rdual x) (at level 1, format "x '..2'") : dual_scope.

(* TODO: dual quaternions and rigid body transformations *)
Section dual_quaternion.
Variable R : rcfType (*realType*).

Definition dquat := @dual (quat_unitRing R).

Local Open Scope dual_scope.

Definition conjdq (a : dquat) : dquat := mkDual (a..1)^*q (a..2)^*q.

Local Notation "x '^*dq'" := (conjdq x).

Lemma conjdqM (a b : dquat) : (a * b)^*dq = b^*dq * a^*dq.
Proof.
rewrite /conjdq !muldE /= conjqM; congr mkDual.
by rewrite linearD /= 2!conjqM [in LHS]addrC.
Qed.

(* squared norm *)

Definition sqrdq (a : dquat) : dquat := a * a^*dq.

(* inverse *)

Definition invdq (a : dquat) : dquat := a^-1.

Lemma invdqE (a : dquat) : a..1 != 0 -> invdq a = 0 (*(sqrdq a)^-1*) *: (a^*dq).
Abort.

(* unit dual quaternions *)

Definition udquat := [qualify x : dquat | sqrdq x == 1].
Fact udquat_key : pred_key udquat. Proof. by []. Qed.
Canonical udquat_keyed := KeyedQualifier udquat_key.

Lemma udquatE (x : dquat) : (x \is udquat) = (sqrdq x == 1).
Proof. done. Qed.

(* dual quaternions and rbt's *)

Definition dquat_from_rot_trans (r t : quat R)
  (_ : r \is uquat R) (_ : ~~ pureq r) (_ : (polar_of_quat r).1 != 0)
  (* i.e., rotation around (polar_of_quat r).1 of angle (polar_of_quat r).2 *+ 2 *)
  (_ : pureq t)
  : dquat := mkDual r t.

Definition rot_trans_from_dquat (x : dquat) :=
  (x..1, 2%:R *: (x..2 * x..1^*q)).

End dual_quaternion.

Notation "x '^*dq'" := (conjdq x).
