From mathcomp Require Import ssreflect ssrbool ssrfun eqtype ssrnat seq choice.
From mathcomp Require Import fintype tuple finfun bigop ssralg ssrint div.
From mathcomp Require Import ssrnum rat (*poly*) closed_field polyrcf matrix.
From mathcomp Require Import mxalgebra tuple mxpoly zmodp binomial realalg.
From mathcomp Require Import complex finset fingroup perm.

Require Import Reals.
From mathcomp.analysis Require Import boolp reals Rstruct Rbar classical_sets posnum.
From mathcomp.analysis Require Import topology hierarchy landau forms derive.

Require Import ssr_ext euclidean3 rot skew rigid.

(* contents (roughly follows [sciavicco] chap. 3):
  1. Section derive_mx.
     Section derive_mx_R.
     Section derive_mx_SE.
     matrix derivatives
  2. Section product_rules.
     derivative of dot product, cross product
  3. Section cross_product_matrix.
     differential of cross product
  4. Section derivative_of_a_rotation_matrix.
     angular velocity
  5. Module BoundVect.
     Module RFrame.
     relative frame
     (NB: to be moved to frame.v)
  6. Section kinematics
     velocity composition rule
  7. Section link_velocity.
  8. Lemma ang_vel_mx_Rz
     example: angular velocity of Rz as a spinor
  9. Section chain. (wip)
  10. Section geometric_jacobian_computation.
      geometric jacobian
  11. Section scara_geometric_jacobian.
      computation of SCARA's geometric jacobian
*)

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Import GRing.Theory Num.Def Num.Theory.

Local Open Scope ring_scope.

Lemma mx_lin1N (R : ringType) n (M : 'M[R]_n) :
  mx_lin1 (- M) = -1 \*: mx_lin1 M :> ( _ -> _).
Proof. rewrite funeqE => v /=; by rewrite scaleN1r mulmxN. Qed.

Section mx.

Variable (V W : normedModType R).

Lemma mxE_funeqE n m (f : V -> 'I_n -> 'I_m -> W) i j :
  (fun x => (\matrix_(i < n, j < m) (f x i j)) i j) =
  (fun x => f x i j).
Proof. by rewrite funeqE => ?; rewrite mxE. Qed.

End mx.

Lemma derive1_cst (V : normedModType R) (f : V) t : (cst f)^`() t = 0.
Proof. by rewrite derive1E derive_val. Qed.

Local Open Scope frame_scope.

Section derive_mx.

Variable (V W : normedModType R).

Definition derivable_mx m n (M : R -> 'M[W]_(m, n)) t v :=
  forall i j, derivable (fun x : R^o => (M x) i j) t v.

Definition derive1mx m n (M : R -> 'M[W]_(m, n)) := fun t =>
  \matrix_(i < m, j < n) (derive1 (fun x => M x i j) t : W).

Lemma derive1mxE m n t (f : 'I_m -> 'I_n -> R -> W) :
  derive1mx (fun x => \matrix_(i, j) f i j x) t =
  \matrix_(i, j) (derive1 (f i j) t : W).
Proof.
rewrite /derive1mx; apply/matrixP => ? ?; rewrite !mxE; congr (derive1 _ t).
rewrite funeqE => ?; by rewrite mxE.
Qed.

Variables m n : nat.
Implicit Types M N : R -> 'M[W]_(m, n).

Lemma derivable_mxD M N t : derivable_mx M t 1 -> derivable_mx N t 1 ->
  derivable_mx (fun x => M x + N x) t 1.
Proof.
move=> Hf Hg a b. evar (f1 : R -> W). evar (f2 : R -> W).
rewrite (_ : (fun x => _) = f1 + f2); last first.
  rewrite funeqE => x; rewrite -[RHS]/(f1 x + f2 x) mxE /f1 /f2; reflexivity.
rewrite {}/f1 {}/f2; exact: derivableD.
Qed.

Lemma derivable_mxN M t : derivable_mx M t 1 ->
  derivable_mx (fun x => - M x) t 1.
Proof.
move=> HM a b.
rewrite (_ : (fun x => _) = (fun x => - (M x a b))); first exact: derivableN.
by rewrite funeqE => ?; rewrite mxE.
Qed.

Lemma derivable_mxB M N t : derivable_mx M t 1 -> derivable_mx N t 1 ->
  derivable_mx (fun x => M x - N x) t 1.
Proof. move=> Hf Hg; apply derivable_mxD => //; exact: derivable_mxN. Qed.

Lemma trmx_derivable M t v :
  derivable_mx M t v = derivable_mx (fun x => (M x)^T) t v.
Proof.
rewrite propeqE; split => [H j i|H i j].
by rewrite (_ : (fun _ => _) = (fun x => M x i j)) // funeqE => z; rewrite mxE.
by rewrite (_ : (fun _ => _) = (fun x => (M x)^T j i)) // funeqE => z; rewrite mxE.
Qed.

Lemma derivable_mx_row M t i :
  derivable_mx M t 1 -> derivable_mx (row i \o M) t 1.
Proof.
move=> H a b.
by rewrite (_ : (fun _ => _) = (fun x => (M x) i b)) // funeqE => z; rewrite mxE.
Qed.

Lemma derivable_mx_col M t i :
  derivable_mx M t 1 -> derivable_mx (trmx \o col i \o M) t 1.
Proof.
move=> H a b.
by rewrite (_ : (fun _ => _) = (fun x => (M x) b i)) // funeqE => z; rewrite 2!mxE.
Qed.

Lemma derivable_mx_cst (P : 'M[W]_(m, n)) t : derivable_mx (cst P) t 1.
Proof. move=> a b; by rewrite (_ : (fun x : R^o => _) = cst (P a b)). Qed.

Lemma derive1mx_cst (P : 'M[W]_(m, n)) : derive1mx (cst P) = cst 0.
Proof.
rewrite /derive1mx funeqE => t; apply/matrixP => i j; rewrite !mxE.
by rewrite (_ : (fun x : R => _) = (cst (P i j))) // derive1_cst.
Qed.

Lemma derive1mx_tr M t : derive1mx (trmx \o M) t = (derive1mx M t)^T.
Proof.
apply/matrixP => i j; rewrite !mxE.
by rewrite (_ : (fun _ => _) = (fun t => M t j i)) // funeqE => ?; rewrite mxE.
Qed.

Lemma derive1mxD M N t : derivable_mx M t 1 -> derivable_mx N t 1 ->
  derive1mx (M + N) t = derive1mx M t + derive1mx N t.
Proof.
move=> Hf Hg; apply/matrixP => a b; rewrite /derive1mx !mxE.
rewrite (_ : (fun _ => _) = (fun x => M x a b) \+ fun x => N x a b); last first.
  by rewrite funeqE => ?; rewrite mxE.
by rewrite derive1E deriveD // 2!derive1E.
Qed.

Lemma derive1mxN M t : derivable_mx M t 1 -> derive1mx (- M) t = - derive1mx M t.
Proof.
move=> Hf; apply/matrixP => a b; rewrite !mxE [in RHS]derive1E -deriveN //.
rewrite -derive1E; f_equal; rewrite funeqE => x; by rewrite mxE.
Qed.

Lemma derive1mxB M N t : derivable_mx M t 1 -> derivable_mx N t 1 ->
  derive1mx (M - N) t = derive1mx M t - derive1mx N t.
Proof.
move=> Hf Hg; rewrite derive1mxD // ?derive1mxN //; exact: derivable_mxN.
Qed.

End derive_mx.

Section derive_mx_R.

Variables m n k : nat.

Lemma derivable_mxM (f : R -> 'M[R^o]_(m, k)) (g : R -> 'M[R^o]_(k, n)) t :
  derivable_mx f t 1 -> derivable_mx g t 1 -> derivable_mx (fun x => f x *m g x) t 1.
Proof.
move=> Hf Hg a b. evar (f1 : 'I_k -> R^o -> R^o).
rewrite (_ : (fun x => _) = (\sum_i f1 i)); last first.
  rewrite funeqE => t'; rewrite mxE fct_sumE; apply: eq_bigr => k0 _.
  rewrite /f1; reflexivity.
rewrite {}/f1; apply derivable_sum => k0.
evar (f1 : R^o -> R^o). evar (f2 : R^o -> R^o).
rewrite (_ : (fun t' => _) = f1 * f2); last first.
  rewrite funeqE => t'; rewrite -[RHS]/(f1 t' * f2 t') /f1 /f2; reflexivity.
rewrite {}/f1 {}/f2; exact: derivableM.
Qed.

End derive_mx_R.

Section derive_mx_SE.

Variable M : R^o -> 'M[R^o]_4.

Lemma derivable_rot_of_hom : (forall t, derivable_mx M t 1) ->
  forall x, derivable_mx (@rot_of_hom [rcfType of R^o] \o M) x 1.
Proof.
move=> H x i j.
rewrite (_ : (fun _ => _) = (fun y => (M y) (lshift 1 i) (lshift 1 j))); last first.
  rewrite funeqE => y; by rewrite !mxE.
exact: H.
Qed.

Lemma derive1mx_SE : (forall t, M t \in 'SE3[[rcfType of R^o]]) ->
  forall t, derive1mx M t = block_mx
    (derive1mx (@rot_of_hom [rcfType of R^o] \o M) t) 0
    (derive1mx (@trans_of_hom [rcfType of R^o] \o M) t) 0.
Proof.
move=> MSE t.
rewrite block_mxEh.
rewrite {1}(_ : M = (fun x => hom (rot_of_hom (M x)) (trans_of_hom (M x)))); last first.
  rewrite funeqE => x; by rewrite -(SE3E (MSE x)).
apply/matrixP => i j.
rewrite 2!mxE; case: splitP => [j0 jj0|j0 jj0].
  rewrite (_ : j = lshift 1 j0); last exact/val_inj.
  rewrite mxE; case: splitP => [i1 ii1|i1 ii1].
    rewrite (_ : i = lshift 1 i1); last exact/val_inj.
    rewrite mxE; congr (derive1 _ t); rewrite funeqE => x.
    by rewrite /hom (block_mxEul _ _ _ _ i1 j0).
  rewrite (_ : i = rshift 3 i1); last exact/val_inj.
  rewrite mxE; congr (derive1 _ t); rewrite funeqE => x.
  by rewrite /hom (block_mxEdl (rot_of_hom (M x))).
rewrite (_ : j = rshift 3 j0) ?mxE; last exact/val_inj.
rewrite (ord1 j0).
case: (@splitP 3 1 i) => [i0 ii0|i0 ii0].
  rewrite (_ : i = lshift 1 i0); last exact/val_inj.
  rewrite (_ : (fun _ => _) = (fun=> 0)) ?derive1_cst ?mxE //.
  rewrite funeqE => x; by rewrite /hom (block_mxEur (rot_of_hom (M x))) mxE.
rewrite (_ : i = rshift 3 i0); last exact/val_inj.
rewrite (_ : (fun _ => _) = (fun=> 1)) ?derive1_cst // (ord1 i0) ?mxE //.
by rewrite funeqE => x; rewrite /hom (block_mxEdr (rot_of_hom (M x))) mxE.
Qed.

End derive_mx_SE.

Section row_belast.

Definition row_belast {R : ringType} n (v : 'rV[R]_n.+1) : 'rV[R]_n :=
  \row_(i < n) (v ``_ (widen_ord (leqnSn n) i)).

Lemma row_belast_last (R : ringType) n (r : 'rV[R]_n.+1) H :
  r = castmx (erefl, H) (row_mx (row_belast r) (r ``_ ord_max)%:M).
Proof.
apply/rowP => i; rewrite castmxE mxE.
case: fintype.splitP => /= [j Hj|[] [] //= ? ni]; rewrite mxE /=.
  congr (_ ``_ _); exact: val_inj.
rewrite mulr1n; congr (_ ``_ _); apply val_inj; by rewrite /= ni addn0.
Qed.

Lemma derivable_row_belast n (u : R^o -> 'rV[R^o]_n.+1) (t : R^o) (v : R^o):
  derivable_mx u t v -> derivable_mx (fun x => row_belast (u x)) t v.
Proof.
move=> H i j; move: (H ord0 (widen_ord (leqnSn n) j)) => {H}.
set f := fun _ => _. set g := fun _ => _.
by rewrite (_ : f = g) // funeqE => x; rewrite /f /g mxE.
Qed.

Lemma dotmul_belast {R : rcfType} n (u : 'rV[R]_n.+1) (v1 : 'rV[R]_n) v2 H :
  u *d castmx (erefl 1%nat, H) (row_mx v1 v2) =
    u *d castmx (erefl 1%nat, H) (row_mx v1 0%:M) +
    u *d castmx (erefl 1%nat, H) (row_mx 0 v2).
Proof.
rewrite -dotmulDr; congr dotmul; apply/matrixP => i j; rewrite !(castmxE,mxE) /=.
case: fintype.splitP => [k /= jk|[] [] // ? /= jn]; by rewrite !(mxE,addr0,add0r,mul0rn).
Qed.

Lemma derive1mx_dotmul_belast n (u v : R^o -> 'rV[R^o]_n.+1) t :
  let u' x := row_belast (u x) in let v' x := row_belast (v x) in
  u' t *d derive1mx v' t + (u t)``_ord_max *: derive (fun x => (v x)``_ord_max) t 1 =
  u t *d derive1mx v t.
Proof.
move=> u' v'.
rewrite (row_belast_last (derive1mx v t)) ?addn1 // => ?.
rewrite dotmul_belast; congr (_ + _).
  rewrite 2!dotmulE [in RHS]big_ord_recr /=.
  rewrite castmxE mxE /=; case: fintype.splitP => [j /= /eqP/negPn|j _].
    by rewrite (gtn_eqF (ltn_ord j)).
  rewrite !mxE (_ : _ == _); last by apply/eqP/val_inj => /=; move: j => [[] ?].
  rewrite mulr0 addr0; apply/eq_bigr => i _; rewrite castmxE !mxE; congr (_ * _).
  case: fintype.splitP => [k /= ik|[] [] //= ?]; rewrite !mxE.
    f_equal.
    rewrite funeqE => x; rewrite /v' !mxE; congr ((v _) _ _); by apply/val_inj.
  rewrite addn0 => /eqP/negPn; by rewrite (ltn_eqF (ltn_ord i)).
apply/esym.
rewrite dotmulE big_ord_recr /= (eq_bigr (fun=> 0)); last first.
  move=> i _.
  rewrite !castmxE !mxE; case: fintype.splitP => [j /= ij| [] [] //= ?].
    by rewrite mxE mulr0.
  rewrite addn0 => /eqP/negPn; by rewrite (ltn_eqF (ltn_ord i)).
rewrite sumr_const mul0rn add0r castmxE /=; congr (_ * _); rewrite !mxE.
case: fintype.splitP => [j /= /eqP/negPn | [] [] //= ? Hn].
  by rewrite (gtn_eqF (ltn_ord j)).
by rewrite mxE derive1E (_ : _ == _).
Qed.

End row_belast.

(* TODO: could be derived from more generic lemmas about bilinearity in derive.v? *)
Section product_rules.

Lemma derive1mx_dotmul n (u v : R^o -> 'rV[R^o]_n) (t : R^o) :
  derivable_mx u t 1 -> derivable_mx v t 1 ->
  derive1 (fun x => u x *d v x : R^o) t =
  derive1mx u t *d v t + u t *d derive1mx v t.
Proof.
move=> U V.
evar (f : R -> R); rewrite (_ : (fun x : R => _) = f); last first.
  rewrite funeqE => x /=; exact: dotmulE.
rewrite derive1E {}/f.
set f := fun i : 'I__ => fun x => ((u x) ``_ i * (v x) ``_ i).
rewrite (_ : (fun _ : R => _) = \sum_(k < _) f k); last first.
  by rewrite funeqE => x; rewrite /f /= fct_sumE.
rewrite derive_sum; last by move=> ?; exact: derivableM (U _ _) (V _ _).
rewrite {}/f.
elim: n u v => [|n IH] u v in U V *.
  rewrite big_ord0 (_ : v t = 0) ?dotmulv0 ?add0r; last by apply/rowP => [[]].
  rewrite (_ : u t = 0) ?dotmul0v //; by apply/rowP => [[]].
rewrite [LHS]big_ord_recr /=.
set u' := fun x => row_belast (u x). set v' := fun x => row_belast (v x).
transitivity (derive1mx u' t *d v' t + u' t *d derive1mx v' t +
    derive (fun x => (u x)``_ord_max * (v x)``_ord_max) t 1).
  rewrite -(IH _ _ (derivable_row_belast U) (derivable_row_belast V)).
  congr (_ + _); apply eq_bigr => i _; congr (derive _ t 1).
  by rewrite funeqE => x; rewrite !mxE.
rewrite (deriveM (U _ _) (V _ _)) /= -!addrA addrC addrA.
rewrite -(addrA (_ + _)) [in RHS]addrC derive1mx_dotmul_belast; congr (_ + _).
by rewrite [in RHS]dotmulC -derive1mx_dotmul_belast addrC dotmulC.
Qed.

Lemma derive1mxM n m p (M : R -> 'M[R^o]_(n, m))
  (N : R^o -> 'M[R^o]_(m, p)) (t : R^o) :
  derivable_mx M t 1 -> derivable_mx N t 1 ->
  derive1mx (fun t => M t *m N t) t =
    derive1mx M t *m N t + M t *m (derive1mx N t).
Proof.
move=> HM HN; apply/matrixP => i j; rewrite ![in LHS]mxE.
rewrite (_ : (fun x => _) = fun x => \sum_k (M x) i k * (N x) k j); last first.
  by rewrite funeqE => x; rewrite !mxE.
rewrite (_ : (fun x => _) =
    fun x => (row i (M x)) *d (col j (N x))^T); last first.
  rewrite funeqE => z; rewrite dotmulE; apply eq_bigr => k _.
  by rewrite 3!mxE.
rewrite (derive1mx_dotmul (derivable_mx_row HM) (derivable_mx_col HN)).
rewrite [in RHS]mxE; congr (_  + _); rewrite [in RHS]mxE dotmulE;
  apply/eq_bigr => /= k _; rewrite !mxE; congr (_ * _); congr (derive1 _ t);
  by rewrite funeqE => z; rewrite !mxE.
Qed.

Lemma derive1mx_crossmul (u v : R -> 'rV[R^o]_3) t :
  derivable_mx u t 1 -> derivable_mx v t 1 ->
  derive1mx (fun x => (u x *v v x) : 'rV[R^o]_3) t =
  derive1mx u t *v v t + u t *v derive1mx v t.
Proof.
move=> U V.
evar (f : R -> 'rV[R]_3); rewrite (_ : (fun x : R => _) = f); last first.
  rewrite funeqE => x; exact: crossmulE.
rewrite {}/f {1}/derive1mx; apply/rowP => i; rewrite mxE derive1E.
rewrite (mxE_funeqE (fun x : R^o => _)) /= mxE 2!crossmulE ![in RHS]mxE /=.
case: ifPn => [/eqP _|/ifnot0P/orP[]/eqP -> /=];
  rewrite ?derive1E (deriveD (derivableM (U _ _) (V _ _))
    (derivableN (derivableM (U _ _) (V _ _))));
  rewrite (deriveN (derivableM (U _ _) (V _ _))) 2!(deriveM (U _ _) (V _ _));
  rewrite addrCA -!addrA; congr (_ + (_ + _)); by [ rewrite mulrC |
  rewrite opprD addrC; congr (_ + _); rewrite mulrC ].
Qed.

End product_rules.

Section cross_product_matrix.

Lemma coord_continuous {K : absRingType} m n i j :
  continuous (fun M : 'M[K]_(m, n) => M i j).
Proof.
move=> /= M s /= /locallyP; rewrite locally_E => -[e e0 es].
apply/locallyP; rewrite locally_E; exists e => //= N MN; exact/es/MN.
Qed.

Lemma differentiable_coord m n (M : 'M[R]_(m.+1, n.+1)) i j :
  differentiable (fun N : 'M[R]_(m.+1, n.+1) => N i j : R^o) M.
Proof.
have @f : {linear 'M[R]_(m.+1, n.+1) -> R^o}.
  by exists (fun N : 'M[R]_(_, _) => N i j); eexists; move=> ? ?; rewrite !mxE.
rewrite (_ : (fun _ => _) = f) //; exact/linear_differentiable/coord_continuous.
Qed.

Lemma differential_cross_product (v : 'rV[R]_3) y :
  'd (crossmul v) y = mx_lin1 \S( v ) :> (_ -> _).
Proof.
rewrite (_ : crossmul v = (fun x => x *m \S( v ))); last first.
  by rewrite funeqE => ?; rewrite -spinE.
rewrite (_ : mulmx^~ \S(v) = mulmxr_linear 1 \S(v)); last by rewrite funeqE.
rewrite diff_lin //= => x.
suff : differentiable (mulmxr \S(v)) x by move/differentiable_continuous.
rewrite (_ : mulmxr \S(v) = (fun z => \sum_i z``_i *: row i \S(v))); last first.
  rewrite funeqE => z; by rewrite -mulmx_sum_row.
set f := fun (i : 'I_3) (z : 'rV_3) => z``_i *: row i \S(v) : 'rV_3.
rewrite (_ : (fun _ => _) = \sum_i f i); last by rewrite funeqE => ?; by rewrite fct_sumE.
apply: differentiable_sum => i.
exact/differentiableZl/differentiable_coord.
Qed.

Lemma differential_cross_product2 (v y : 'rV[R]_3) :
  'd (fun x : 'rV[R^o]_3 => x *v v) y = -1 \*: mx_lin1 \S( v ) :> (_ -> _).
Proof.
transitivity ('d (crossmul (- v)) y); last first.
  by rewrite differential_cross_product spinN mx_lin1N.
congr diff.
by rewrite funeqE => /= u; rewrite crossmulC crossmulNv.
Qed.

End cross_product_matrix.

(* [sciavicco] p.80-81 *)
Section derivative_of_a_rotation_matrix.

Variable M : R -> 'M[R^o]_3. (* time-varying matrix *)

(* angular velocity matrix *)
Definition ang_vel_mx t : 'M_3 := (M t)^T * derive1mx M t.

Definition body_ang_vel_mx t : 'M_3 := derive1mx M t *m (M t)^T.

(* angular velocity (a free vector) *)
Definition ang_vel t := unspin (ang_vel_mx t).

Hypothesis MO : forall t, M t \is 'O[ [ringType of R] ]_3.
Hypothesis derivable_M : forall t, derivable_mx M t 1.

Lemma ang_vel_mx_is_so t : ang_vel_mx t \is 'so[ [ringType of R] ]_3.
Proof.
have : (fun t => (M t)^T * M t) = cst 1.
  rewrite funeqE => x; by rewrite -orthogonal_inv // mulVr // orthogonal_unit.
move/(congr1 (fun f => derive1mx f t)); rewrite derive1mx_cst -[cst 0 _]/(0).
rewrite derive1mxM // -?trmx_derivable // derive1mx_tr.
move=> /eqP; rewrite addr_eq0 => /eqP H.
by rewrite antiE /ang_vel_mx trmx_mul trmxK H opprK.
Qed.

Lemma ang_vel_mxE t : ang_vel_mx t = \S( ang_vel t).
Proof. by rewrite /ang_vel unspinK // ang_vel_mx_is_so. Qed.

(* [sciavicco] eqn 3.7 *)
Lemma derive1mx_ang_vel t : derive1mx M t = M t * ang_vel_mx t.
Proof.
move: (ang_vel_mx_is_so t); rewrite antiE -subr_eq0 opprK => /eqP.
rewrite {1 2}/ang_vel_mx trmx_mul trmxK => /(congr1 (fun x => (M t) * x)).
rewrite mulr0 mulrDr !mulrA -{1}(orthogonal_inv (MO t)).
rewrite divrr ?orthogonal_unit // mul1r.
move=> /eqP; rewrite addr_eq0 => /eqP {1}->.
rewrite -mulrA -mulrN -mulrA; congr (_ * _).
move: (ang_vel_mx_is_so t); rewrite antiE -/(ang_vel_mx t) => /eqP ->.
by rewrite /ang_vel_mx trmx_mul trmxK mulmxE.
Qed.

Lemma derive1mx_rot (p' : 'rV[R^o]_3 (* constant vector *)) :
  let p := fun t => p' *m M t in
  forall t, derive1mx p t = ang_vel t *v p t.
Proof.
move=> p t; rewrite /p derive1mxM; last first.
  exact: derivable_M.
  rewrite /derivable_mx => i j; exact: ex_derive.
rewrite derive1mx_cst mul0mx add0r derive1mx_ang_vel mulmxA.
by rewrite -{1}(unspinK (ang_vel_mx_is_so t)) spinE.
Qed.

End derivative_of_a_rotation_matrix.

Require Import frame.

Module BoundVect. (* i.e., point of application prescribed *)
Section bound_vector.
Variable T : ringType.
Record t (F : tframe T) := mk { endp : 'rV[T]_3 }.
Definition startp F (v : t F) : 'rV[T]_3 := \o{F}.
End bound_vector.
End BoundVect.
Notation bvec := BoundVect.t.
Coercion boundvectendp T (F : tframe T) (v : bvec F) := BoundVect.endp v.

Definition bvec0 T (F : tframe T) : bvec F := BoundVect.mk _ 0.

Reserved Notation "a \+b b" (at level 39).
Reserved Notation "a \-b b" (at level 39).

Section about_bound_vectors.

Variables (T : ringType) (F : tframe T).

Definition FramedVect_of_Bound (p : bvec F) : fvec F := `[ BoundVect.endp p $ F ].

Definition BoundVect_add (a b : bvec F) : bvec F :=
  BoundVect.mk F (BoundVect.endp a + BoundVect.endp b).

Definition BoundFramed_add (a : bvec F) (b : fvec F) : bvec F :=
  BoundVect.mk F (BoundVect.endp a + FramedVect.v b).

Local Notation "a \+b b" := (BoundFramed_add a b).

Lemma BoundFramed_addA (a : bvec F) (b c : fvec F) :
  a \+b b \+b c = a \+b (b \+f c).
Proof. by rewrite /BoundFramed_add /= addrA. Qed.

Definition BoundVect_sub (F : tframe T) (a b : bvec F) : fvec F :=
  `[ BoundVect.endp a - BoundVect.endp b $ F ].

Local Notation "a \-b b" := (BoundVect_sub a b).

Lemma bv_eq (a b : bvec F) : a = b :> 'rV[T]_3 -> a = b.
Proof. by move: a b => [a] [b] /= ->. Qed.

End about_bound_vectors.

Notation "a \+b b" := (BoundFramed_add a b).
Notation "a \-b b" := (BoundVect_sub a b).

Lemma derive1mx_BoundFramed_add (F : tframe [ringType of R^o])
  (Q : R -> bvec F) (Z : R -> fvec F) t :
  derivable_mx (fun x => BoundVect.endp (Q x)) t 1 ->
  derivable_mx (fun x => FramedVect.v (Z x)) t 1 ->
  derive1mx (fun x => BoundVect.endp (Q x \+b Z x)) t =
  derive1mx (fun x => BoundVect.endp (Q x)) t +
    derive1mx (fun x => FramedVect.v (Z x)) t.
Proof.
move=> H H'.
rewrite (_ : (fun x : R => _) = (fun x : R => BoundVect.endp (Q x) +
  (FramedVect.v (Z x)))); last by rewrite funeqE.
rewrite derive1mxD.
- by [].
- exact: H.
- exact H'.
Qed.

Module RFrame.
Section rframe.
Variable T : ringType.
Record t (F0 : tframe T) := mk {
  o : bvec F0 ;
  i : fvec F0 ;
  j : fvec F0 ;
  k : fvec F0 ;
  F : tframe T ;
  _ : BoundVect.endp o = \o{F} ;
  _ : FramedVect.v i = (F|,0) ;
  _ : FramedVect.v j = (F|,1) ;
  _ : FramedVect.v k = (F|,2%:R) ;
}.
End rframe.
End RFrame.
Notation rframe := RFrame.t.
Coercion tframe_of_rframe R (F : tframe R) (F : rframe F) : tframe R := RFrame.F F.

Lemma RFrame_o T (F0 : tframe T) (F1 : rframe F0) :
  BoundVect.endp (RFrame.o F1) = \o{RFrame.F F1}.
Proof. by destruct F1. Qed.

(* lemmas about relative frames *)

Lemma BoundVect0_fixed T (F : tframe T) (F1 : R -> rframe F) t :
  BoundVect.endp (bvec0 (F1 t)) = BoundVect.endp (bvec0 (F1 0)).
Proof. by []. Qed.

Section derivable_FromTo.

Lemma derivable_mx_FromTo' (F : R -> tframe [ringType of R^o])
  (G' : forall t, rframe (F t)) (G : forall t, rframe (F t)) t :
  derivable_mx F t 1 -> derivable_mx G t 1 -> derivable_mx G' t 1 ->
  derivable_mx (fun x => (G x) _R^ (G' x)) t 1.
Proof.
move=> HF HG HG' a b.
rewrite (_ : (fun x => _) = (fun x => row a (G x) *d row b (G' x))); last first.
  by rewrite funeqE => t'; rewrite !mxE.
evar (f : 'I_3 -> R^o -> R^o).
rewrite (_ : (fun x => _) = \sum_i f i); last first.
  rewrite funeqE => t'; rewrite dotmulE fct_sumE; apply: eq_bigr => /= i _.
  rewrite !mxE /f; reflexivity.
rewrite {}/f.
apply: derivable_sum => i.
apply: derivableM; [exact: HG | exact: HG'].
Qed.

Lemma derivable_mx_FromTo (F : R -> tframe [ringType of R^o])
  (G : forall t, rframe (F t)) t :
  derivable_mx F t 1 -> derivable_mx G t 1 ->
  derivable_mx (fun x => (G x) _R^ (F x)) t 1.
Proof.
move=> HF HG a b.
have @G' : forall t0, rframe (F t0).
  move=> t0.
  exact: (@RFrame.mk _ _ (@BoundVect.mk _ _ \o{F t0}) `[(F t0)|,0 $ F t0] `[(F t0)|,1 $ F t0] `[(F t0)|,2%:R $ F t0] (F t0)).
apply: (@derivable_mx_FromTo' F G' G).
by [].
by [].
by [].
Qed.

Lemma derivable_mx_FromTo_fixed
  (F : tframe [ringType of R^o]) (G : R -> rframe F) t :
  derivable_mx G t 1 -> derivable_mx (fun x => (G x) _R^ F) t 1.
Proof.
move=> H; apply derivable_mx_FromTo; [move=> a b; exact: ex_derive | exact H].
Qed.

Lemma derivable_mx_FromTo_tr
  (F : tframe [ringType of R^o]) (G : R -> rframe F) t :
  derivable_mx (fun x => F _R^ (G x)) t 1 = derivable_mx (fun x => F _R^ (G x)) t 1.
Proof. by rewrite trmx_derivable. Qed.

End derivable_FromTo.

(* the coordinate transformation of a point P1 from frame F1 to frame F
  (eqn 2.33, 3.10) *)
Definition coortrans (F : tframe [ringType of R^o]) (F1 : rframe F)
    (P1 : bvec F1) : bvec F :=
  RFrame.o F1 \+b rmap F (FramedVect_of_Bound P1).

(* motion of P1 w.r.t. the fixed frame F (eqn B.2) *)
Definition motion (F : tframe [ringType of R^o]) (F1 : R -> rframe F)
  (P1 : forall t, bvec (F1 t)) t : bvec F := coortrans (P1 t).

(* [sciavicco] p.351-352  *)
Section kinematics.

Variable F : tframe [ringType of R^o]. (* fixed frame *)
Variable F1 : R -> rframe F. (* time-varying frame (origin and basis in F) *)
Hypothesis derivable_F1 : forall t, derivable_mx F1 t 1.
Hypothesis derivable_F1o : forall t, derivable_mx (@TFrame.o [ringType of R^o] \o F1) t 1.

Variable P1 : forall t, bvec (F1 t). (* point with coordinates in F1 *)
(* NB: compared with [sciavicco] p.351, P1 not necessarily fixed in F1 *)
Hypothesis derivable_mxP1 : forall t, derivable_mx (fun x => BoundVect.endp (P1 x)) t 1.

Let P : R -> bvec F := motion P1.

Variable Q1 : forall t, bvec (F1 t).
Hypothesis Q1_fixed_in_F1 : forall t, BoundVect.endp (Q1 t) = BoundVect.endp (Q1 0).

Let Q : R -> bvec F := motion Q1.

(* eqn B.3 *)
Lemma eqnB3 t : P t = Q t \+b rmap F (P1 t \-b Q1 t).
Proof.
rewrite /P /Q /motion /coortrans BoundFramed_addA; congr (_ \+b _).
apply fv_eq => /=; rewrite -mulmxDl; congr (_ *m _).
by rewrite addrCA subrr addr0.
Qed.

Lemma derivable_mx_Q t : derivable_mx (fun x => BoundVect.endp (Q x)) t 1.
Proof.
rewrite /Q /=; apply derivable_mxD.
  move=> a b.
  move: (@derivable_F1o t a b).
  rewrite (_ : (fun x => \o{F1 x} a b) =
    (fun x => BoundVect.endp (RFrame.o (F1 x)) a b)) // funeqE => x.
  destruct (F1 x) => /=; by rewrite e.
apply derivable_mxM; last exact: derivable_mx_FromTo.
rewrite (_ : (fun x => _) = (fun _ => BoundVect.endp (Q1 0))); last first.
  rewrite funeqE => x; by rewrite Q1_fixed_in_F1.
move=> a b; exact: ex_derive.
Qed.

Let Rot := fun t => (F1 t) _R^ F.

(* generalization of B.4  *)
Lemma velocity_composition_rule (t : R) :
  derive1mx (fun x => BoundVect.endp (P x)) t =
  derive1mx (fun x => BoundVect.endp (Q x)) t +
  derive1mx P1 t *m Rot t (* rate of change of the coordinates P1 expressed in the frame F *) +
  ang_vel Rot t *v FramedVect.v (P t \-b Q t).
Proof.
rewrite {1}(_ : P = fun t => Q t \+b rmap F (P1 t \-b Q1 t)); last first.
  by rewrite funeqE => t'; rewrite eqnB3.
rewrite (derive1mx_BoundFramed_add (@derivable_mx_Q t)); last first.
  apply derivable_mxM; last exact: derivable_mx_FromTo.
  rewrite (_ : (fun x => _) = (fun x => FramedVect.v (FramedVect_of_Bound (P1 x)) -
    FramedVect.v (FramedVect_of_Bound (Q1 0)))); last first.
    rewrite funeqE => x; by rewrite /= Q1_fixed_in_F1.
  apply: derivable_mxB => /=.
  exact: derivable_mxP1.
  move=> a b; exact: ex_derive.
rewrite -addrA; congr (_ + _).
rewrite [in LHS]/rmap [in LHS]/= derive1mxM; last 2 first.
  rewrite {1}(_ : (fun x  => _) = (fun x  => BoundVect.endp (P1 x) -
    BoundVect.endp (Q1 0))); last first.
    by rewrite funeqE => ?; rewrite Q1_fixed_in_F1.
  apply: derivable_mxB.
    exact: derivable_mxP1.
    move=> a b; exact: ex_derive.
  exact: derivable_mx_FromTo.
rewrite derive1mxB; last 2 first.
  exact: derivable_mxP1.
  rewrite (_ : (fun x => _) = cst (BoundVect.endp (Q1 0))); last first.
    by rewrite funeqE => x; rewrite Q1_fixed_in_F1.
  exact: derivable_mx_cst.
congr (_*m _  + _).
  rewrite [in X in _ + X = _](_ : (fun x => _) = cst (BoundVect.endp (Q1 0))); last first.
    by rewrite funeqE => x; rewrite Q1_fixed_in_F1.
  by rewrite derive1mx_cst subr0.
rewrite -spinE unspinK; last first.
  rewrite ang_vel_mx_is_so; first by [].
  move=> t'; by rewrite FromTo_is_O.
  move=> t'; exact: derivable_mx_FromTo.
rewrite /ang_vel_mx mulmxA; congr (_ *m _).
rewrite /P /Q /= opprD addrACA subrr add0r mulmxBl -!mulmxA.
by rewrite orthogonal_mul_tr ?FromTo_is_O // !mulmx1.
Qed.

Hypothesis P1_fixed_in_F1 : forall t, BoundVect.endp (P1 t) = BoundVect.endp (P1 0).

(* eqn B.4 *)
Lemma velocity_composition_rule_spec (t : R) :
  derive1mx (fun x => BoundVect.endp (P x)) t =
  derive1mx (fun x => BoundVect.endp (Q x)) t +
  ang_vel Rot t *v (FramedVect.v (P t \-b Q t)).
Proof.
rewrite velocity_composition_rule; congr (_ + _).
suff -> : derive1mx P1 t = 0 by rewrite mul0mx addr0.
apply/matrixP => a b; rewrite !mxE.
rewrite (_ : (fun x => _) = cst (P1 0 a b)); last first.
  rewrite funeqE => x /=; by rewrite /boundvectendp (P1_fixed_in_F1 x).
by rewrite derive1_cst.
Qed.

End kinematics.

(* [sciavicco] p.81-82 *)
Section derivative_of_a_rotation_matrix_contd.

Variable F : tframe [ringType of R^o].
Variable F1 : R -> rframe F.
Hypothesis derivable_F1 : forall t, derivable_mx F1 t 1.
Variable p1 : forall t, bvec (F1 t).
Hypothesis derivable_mx_p1 : forall t, derivable_mx (fun x => BoundVect.endp (p1 x)) t 1.
Hypothesis derivable_F1o : forall t, derivable_mx (@TFrame.o [ringType of R^o] \o F1) t 1.

Definition p0 := motion p1.

Lemma eqn312 t :
  derive1mx (fun x => BoundVect.endp (motion p1 x)) t =
  derive1mx (fun x => BoundVect.endp (motion (fun=> bvec0 (F1 x)) t)) t +
  derive1mx p1 t *m (F1 t) _R^ F +
  ang_vel (fun t => (F1 t) _R^ F) t *v (p1 t *m (F1 t) _R^ F).
Proof.
rewrite (@velocity_composition_rule F _ derivable_F1 derivable_F1o p1 derivable_mx_p1
  (fun t => bvec0 (F1 t)) (@BoundVect0_fixed _ _ F1)).
congr (_ + _ *v _).
by rewrite /= mul0mx addr0 addrAC subrr add0r.
Qed.

End derivative_of_a_rotation_matrix_contd.

Require Import screw.

(* [murray p.54] chapter 2, section 4.2*)
Section rigid_body_velocity.

Section spatial_velocity.

Variable M : R -> 'M[R^o]_4.
Hypothesis derivableM : forall t, derivable_mx M t 1.
Hypothesis MSE : forall t, M t \in 'SE3[[rcfType of R]].

Definition spatial_velocity t : 'M_4 := (M t)^-1 * derive1mx M t.

Definition spatial_lin_vel :=
  let r : R -> 'M[R^o]_3 := @rot_of_hom _ \o M in
  let p : R -> 'rV[R^o]_3:= @trans_of_hom _ \o M in
  fun t => - p t *m (r t)^T *m derive1mx r t + derive1mx p t.

Lemma spatial_velocityE t :
  let r : R -> 'M[R^o]_3 := @rot_of_hom _ \o M in
  spatial_velocity t = block_mx (ang_vel_mx r t) 0 (spatial_lin_vel t) 0.
Proof.
move=> r.
rewrite /spatial_velocity.
rewrite -inv_homE //.
rewrite /inv_hom.
rewrite /hom.
rewrite derive1mx_SE //.
rewrite (_ : rot_of_hom (M t) = r t) // -/r.
rewrite -mulmxE.
rewrite (mulmx_block (r t)^T _ _ _ (derive1mx r t)).
rewrite !(mul0mx,add0r,mul1mx,mulmx0,trmx0,addr0,mulmx1).
by rewrite mulmxE -/(ang_vel_mx r t).
Qed.

Lemma spatial_velocity_in_se3 x : spatial_velocity x \in 'se3[[rcfType of R^o]].
Proof.
rewrite spatial_velocityE. set r := @rot_of_hom _.
rewrite qualifE block_mxKul block_mxKur block_mxKdr 2!eqxx 2!andbT.
rewrite ang_vel_mx_is_so // => t0.
by rewrite rotation_sub // rot_of_hom_is_SO.
exact: derivable_rot_of_hom.
Qed.

Lemma spatial_velocity_is_twist x :
  let r : R -> 'M[R^o]_3 := @rot_of_hom _ \o M in
  spatial_velocity x = wedge \T( spatial_lin_vel x , unspin (ang_vel_mx r x)).
Proof.
move=> r.
rewrite spatial_velocityE.
rewrite /wedge lin_tcoorE ang_tcoorE unspinK //.
rewrite ang_vel_mx_is_so // => t0.
by rewrite rotation_sub // rot_of_hom_is_SO.
exact: derivable_rot_of_hom.
Qed.

End spatial_velocity.

Section body_velocity.

Variable M : R -> 'M[R^o]_4.
Hypothesis derivableM : forall t, derivable_mx M t 1.
Hypothesis MSE : forall t, M t \in 'SE3[[rcfType of R]].

Definition body_velocity t : 'M_4 := derive1mx M t * (M t)^-1.

Definition body_lin_vel :=
  let r : R -> 'M[R^o]_3 := @rot_of_hom _ \o M in
  let p : R -> 'rV[R^o]_3:= @trans_of_hom _ \o M in
  fun t => derive1mx p t *m (r t)^T.

Lemma body_ang_vel_is_so t : body_ang_vel_mx (@rot_of_hom _ \o M) t \is 'so[R_rcfType]_3.
Proof.
rewrite /body_ang_vel_mx.
have : forall t, (@rot_of_hom [rcfType of R^o] \o M) t \is 'O[[ringType of R]]_3.
  move=> t0; by rewrite rotation_sub // rot_of_hom_is_SO.
move/ang_vel_mx_is_so => /(_ (derivable_rot_of_hom derivableM))/(_ t).
rewrite /ang_vel_mx.
move/(conj_so (((rot_of_hom (T:=[rcfType of R^o]) \o M) t)^T)).
rewrite !mulmxA !trmxK orthogonal_mul_tr ?rotation_sub // ?rot_of_hom_is_SO //.
by rewrite mul1mx.
Qed.

Lemma body_velocityE t : let r : R -> 'M[R^o]_3 := @rot_of_hom _ \o M in
  body_velocity t = block_mx (body_ang_vel_mx r t) 0 (body_lin_vel t) 0.
Proof.
move=> r.
rewrite /body_velocity.
rewrite -inv_homE // /inv_hom.
rewrite /hom.
rewrite derive1mx_SE //.
rewrite (_ : rot_of_hom (M t) = r t) // -/r.
rewrite -mulmxE.
rewrite (mulmx_block (derive1mx r t) _ _ _ (r t)^T).
rewrite !(mul0mx,add0r,mul1mx,mulmx0,trmx0,addr0,mulmx1).
by rewrite -/(body_ang_vel_mx _) -/(body_lin_vel _).
Qed.

Lemma body_velocity_is_se x : body_velocity x \is 'se3[R_rcfType].
Proof.
rewrite body_velocityE.
rewrite qualifE block_mxKul block_mxKur block_mxKdr 2!eqxx 2!andbT.
by rewrite body_ang_vel_is_so.
Qed.

End body_velocity.

Section spatial_body_adjoint.

Variable M : R -> 'M[R^o]_4.
Hypothesis derivableM : forall t, derivable_mx M t 1.
Hypothesis MSE : forall t, M t \in 'SE3[[rcfType of R]].

Lemma spatial_body_velocity x :
  vee (spatial_velocity M x) = vee (body_velocity M x) *m Adjoint (M x).
Proof.
rewrite -/(SE3_action _ _) action_Adjoint; last by [].
congr vee; rewrite /spatial_velocity -mulmxE -mulmxA; congr (_ * _).
rewrite veeK; last by rewrite body_velocity_is_se.
by rewrite /body_velocity -mulmxA mulVmx ?mulmx1 // SE3_in_unitmx.
Qed.

End spatial_body_adjoint.

End rigid_body_velocity.

(* [sciavicco] p.83 *)
Section link_velocity.

Variable F : tframe [ringType of R^o].
Variable F1 : R -> rframe F.
Variable F2 : R -> rframe F.
Let o1 t : bvec F := RFrame.o (F1 t).
Let o2 t : bvec F := RFrame.o (F2 t).

Let r12 : forall t : R, bvec (F1 t) := fun t =>
  BoundVect.mk (F1 t)
    (FramedVect.v (rmap (F1 t) `[ \o{F2 t} - \o{F1 t} $ F ])).

Hypothesis derivable_F1 : forall t, derivable_mx F1 t 1.
Hypothesis derivable_F1o : forall t, derivable_mx (@TFrame.o [ringType of R^o] \o F1) t 1.
Hypothesis derivable_r12 : forall t, derivable_mx (fun x => BoundVect.endp (r12 x)) t 1.
Hypothesis derivable_F2 : forall t, derivable_mx F2 t 1.

Lemma eqn310' t : o2 t = o1 t \+b rmap F (FramedVect_of_Bound (r12 t)).
Proof.
rewrite /o2 /o1 /= /r12 /= /rmap /= /BoundFramed_add /=; apply bv_eq => /=.
rewrite -mulmxA FromTo_comp FromToI mulmx1 /= addrCA RFrame_o /=.
by rewrite subrr addr0 -RFrame_o.
Qed.

Definition w1 := ang_vel (fun t => (F1 t) _R^ F).

Lemma eqn314_helper t : FramedVect.v (rmap F `[r12 t $ F1 t]) = \o{F2 t} - \o{F1 t}.
Proof. by rewrite /= -mulmxA FromTo_comp FromToI mulmx1. Qed.

(* lin. vel. of Link i as a function of
   the translational and rotational velocities of Link i-1 *)
Lemma eqn314 t : derive1mx o2 t = derive1mx o1 t +
  FramedVect.v (rmap F `[derive1mx r12 t $ F1 t])
    (* velocity of the origin of Frame i w.r.t. the origin of Frame i-1 *) +
  w1 t *v (\o{F2 t} - \o{F1 t}).
Proof.
rewrite -eqn314_helper.
move: (@eqn312 F _ derivable_F1 _ derivable_r12 derivable_F1o t).
have -> : derive1mx (fun x => BoundVect.endp (motion r12 x)) t = derive1mx o2 t.
  rewrite (_ : (fun x => BoundVect.endp (motion r12 x)) = o2) //.
  rewrite funeqE => t' /=; rewrite -mulmxA FromTo_comp FromToI mulmx1.
  rewrite addrCA RFrame_o subrr addr0.
  by rewrite /o2 -RFrame_o.
move=> ->.
rewrite -!addrA; congr (_ + _).
rewrite (_ : (fun x => BoundVect.endp (motion (fun _ : R => bvec0 (F1 x)) t)) = o1) //.
rewrite funeqE => t'.
by rewrite /motion /= mul0mx addr0.
Qed.

Definition w2 : R -> 'rV_3 := ang_vel (fun t => (F2 t) _R^ F).
Definition w12 : R -> 'rV_3 := ang_vel (fun t => (F2 t) _R^ (F1 t)).

(* ang. vel. of Link i as a function of the ang. vel. of Link i-1 and of Link i w.r.t. Link i-1 *)
Lemma eqn316 t : w2 t = w1 t + w12 t *m ((F1 t) _R^ F).
Proof.
have : (fun t => (F2 t) _R^ F) = (fun t => ((F2 t) _R^ (F1 t)) *m ((F1 t) _R^ F)).
  by rewrite funeqE => ?; rewrite FromTo_comp.
move/(congr1 (fun x => derive1mx x)).
rewrite funeqE.
move/(_ t).
rewrite derive1mxM; last 2 first.
  move=> t'; exact: derivable_mx_FromTo'.
  move=> t'; exact: derivable_mx_FromTo.
rewrite derive1mx_ang_vel; last 2 first.
  move=> t'; by rewrite FromTo_is_O.
  move=> t'; exact: derivable_mx_FromTo.
rewrite derive1mx_ang_vel; last 2 first.
  move=> t'; by rewrite FromTo_is_O.
  move=> t'; exact: derivable_mx_FromTo'.
rewrite derive1mx_ang_vel; last 2 first.
  move=> t'; by rewrite FromTo_is_O.
  move=> t'; exact: derivable_mx_FromTo.
rewrite ang_vel_mxE; last 2 first.
  move=> t'; by rewrite FromTo_is_O.
  move=> t'; exact: derivable_mx_FromTo.
rewrite ang_vel_mxE; last 2 first.
  move=> t'; by rewrite FromTo_is_O.
  move=> t'; exact: derivable_mx_FromTo'.
rewrite ang_vel_mxE; last 2 first.
  move=> t'; by rewrite FromTo_is_O.
  move=> t'; exact: derivable_mx_FromTo.
rewrite mulmxE -[in X in _ = X + _](mulr1 ((F2 t) _R^ (F1 t))).
rewrite -(@orthogonal_tr_mul _ _ (F _R^ (F1 t))) ?FromTo_is_O //.
rewrite -{2}(trmx_FromTo (F1 t) F).
rewrite -!mulrA.
rewrite (mulrA _ _ ((F1 t) _R^ F)).
rewrite (@spin_similarity _ ((F1 t) _R^ F)) ?FromTo_is_SO //.
rewrite mulrA -mulmxE.
rewrite trmx_FromTo.
rewrite FromTo_comp.
rewrite mulmxA.
rewrite FromTo_comp.
rewrite -mulmxDr.
rewrite -spinD.
rewrite -/w2 -/w1 -/w12.
rewrite mulmxE.
move/mulrI.
rewrite FromTo_unit => /(_ isT)/eqP.
rewrite spin_inj => /eqP.
by rewrite addrC.
Qed.

End link_velocity.

Require Import angle.

Lemma chain_rule (f g : R^o -> R^o) x :
  derivable f x 1 -> derivable g (f x) 1 ->
  derive1 (g \o f) x = derive1 g (f x) * derive1 f x.
Proof.
move=> /derivable1_diffP df /derivable1_diffP dg.
rewrite derive1E'; last exact/differentiable_comp.
by rewrite diff_comp // !derive1E' //= -{1}(mulr1 ('d f x 1)) linearZ mulrC.
Qed.

Definition Cos (x : R^o) : R^o := cos (Rad.angle_of x).
Definition Sin (x : R^o) : R^o := sin (Rad.angle_of x).

Axiom derive1_Cos : forall t, derive1 Cos t = - Sin t.
Axiom derive1_Sin : forall t, derive1 Sin t = Cos t.
Axiom derivable_Sin : forall t, derivable Sin t 1.
Axiom derivable_Cos : forall t, derivable Cos t 1.
Axiom derivable_Cos_comp : forall t (a : R^o -> R^o), derivable a t 1 ->
  derivable (Cos \o a) t 1.
Axiom derivable_Sin_comp : forall t (a : R^o -> R^o), derivable a t 1 ->
  derivable (Sin \o a) t 1.

Lemma derive1_Cos_comp t (a : R^o -> R^o) : derivable a t 1 ->
  derive1 (Cos \o a) t = - (derive1 a t) * Sin (a t).
Proof.
move=> H; rewrite (chain_rule H) ?derive1_Cos 1?mulrC ?(mulNr,mulrN).
by [].
exact: derivable_Cos.
Qed.

Lemma derive1mx_RzE (a : R^o -> R^o) t : derivable a t 1 ->
  derive1mx (fun x => Rz (@Rad.angle_of [realType of R^o] (a x))) t =
  derive1 a t *: col_mx3 (row3 (- Sin (a t)) (Cos (a t)) 0) (row3 (- Cos (a t)) (- Sin (a t)) 0) 0.
Proof.
move=> Ha.
apply/matrix3P/and9P; split; rewrite !mxE /=.
- rewrite (_ : (fun _ => _) = Cos \o a); last by rewrite funeqE => x; rewrite !mxE.
  rewrite (chain_rule Ha); last exact/derivable_Cos.
  by rewrite derive1_Cos mulrC.
- rewrite (_ : (fun _ => _) = Sin \o a); last by rewrite funeqE => x; rewrite !mxE.
  rewrite (chain_rule Ha); last exact/derivable_Sin.
  by rewrite derive1_Sin mulrC.
- rewrite (_ : (fun _ => _) = \0); last by rewrite funeqE => x; rewrite !mxE.
  by rewrite derive1_cst mulr0.
- rewrite (_ : (fun _ => _) = - Sin \o a); last by rewrite funeqE => x; rewrite !mxE.
  rewrite (_ : - _ \o _ = - (Sin \o a)) // derive1E deriveN; last first.
    apply/derivable1_diffP/differentiable_comp.
    exact/derivable1_diffP.
    exact/derivable1_diffP/derivable_Sin.
  rewrite -derive1E (chain_rule Ha); last exact/derivable_Sin.
  by rewrite derive1_Sin mulrN mulrC.
- rewrite (_ : (fun _ => _) = Cos \o a); last by rewrite funeqE => x; rewrite !mxE.
  rewrite (chain_rule Ha); last exact/derivable_Cos.
  by rewrite derive1_Cos mulrN mulNr mulrC.
- rewrite (_ : (fun _ => _) = \0); last by rewrite funeqE => x; rewrite !mxE.
  by rewrite derive1_cst mulr0.
- rewrite (_ : (fun _ => _) = \0); last by rewrite funeqE => x; rewrite !mxE.
  by rewrite derive1_cst mulr0.
- rewrite (_ : (fun _ => _) = \0); last by rewrite funeqE => x; rewrite !mxE.
  by rewrite derive1_cst mulr0.
- rewrite (_ : (fun _ => _) = cst 1); last by rewrite funeqE => x; rewrite !mxE.
  by rewrite derive1_cst mulr0.
Qed.

(* example 3.1 [sciavicco]*)
(* rotational motion of one degree of freedom manipulator *)
Lemma ang_vel_mx_Rz (a : R^o -> R^o) t : derivable a t 1 ->
  ang_vel_mx (@Rz _ \o (@Rad.angle_of [realType of R^o]) \o a) t = \S(row3 0 0 (derive1 a t)).
Proof.
move=> Ha.
rewrite /ang_vel_mx trmx_Rz (derive1mx_RzE Ha) /Rz -mulmxE.
rewrite -!scalemxAr mulmx_col3.
rewrite mulmx_row3_col3 scale0r addr0.
rewrite mulmx_row3_col3 scale0r addr0.
rewrite e2row mulmx_row3_col3 !(scale0r,scaler0,addr0).
rewrite !row3Z !(cosN,sinN,opprK,mulr0,mulrN,mulNr).
rewrite !row3D mulrC addrC subrr addr0.
rewrite -!expr2 cos2Dsin2 -opprD addrC cos2Dsin2.
by apply/matrix3P; rewrite !spinij !mxE /= !(eqxx,oppr0,mulr0,mulrN1,mulr1).
Qed.

(* see also the end of dh.v *)
Section chain.

Inductive joint (R : rcfType) :=
  Revolute of (R^o -> (*angle*) R) | Prismatic of (R^o -> R).

Definition joint_variable (R : realType) (j : joint [rcfType of R]) : R^o -> R :=
  fun t => match j with Revolute a => (* Rad.f ( *) a t(*) *) | Prismatic a => a t end.

Record chain (R : rcfType) n (* number of joints *) := mkChain {
  joint_of_chain : 'I_n -> joint R ;
  frame_of_chain : 'I_n.+1 -> (R^o -> tframe R) }.

End chain.

Section geometric_jacobian_computation.

Variables (n : nat) (c : chain [rcfType of R^o] n).

Definition prev_frame (i : 'I_n) : 'I_n.+1 := widen_ord (leqnSn n) i.
Definition next_frame (i : 'I_n) : 'I_n.+1 := fintype.lift ord0 i.
Lemma next_frameE i : next_frame i = i.+1 :> nat. Proof. by []. Qed.
Definition last_frame : 'I_n.+1 := ord_max.

Section geo_jac_row.
Variable i : 'I_n.
Let j : joint [rcfType of R^o] := joint_of_chain c i.
Let q : R^o -> R^o := joint_variable j.
Let Fim1 := frame_of_chain c (prev_frame i).
(*Let Fi := frame_of_chain c (next_frame i).*)
Let Fmax := frame_of_chain c last_frame.
(* contribution to the angular velocity *)
Definition geo_jac_ang t : 'rV_3 := if j is Revolute _ then \z{Fim1 t} else 0.
(* contribution to the linear velocity *)
Definition geo_jac_lin t : 'rV_3 :=
  if j is Revolute _ then \z{Fim1 t} *v (\o{Fmax t} - \o{Fim1 t}) else \z{Fim1 t}.
End geo_jac_row.

Definition geo_jac t : 'M_(n, 6) :=
  row_mx (\matrix_(i < n) geo_jac_lin i t) (\matrix_(i < n) geo_jac_ang i t).

End geometric_jacobian_computation.

Require Import scara.

Section scara_geometric_jacobian.

Variable theta1 : R -> angle [rcfType of R^o].
Variable a1 : R.
Variable theta2 : R -> angle [rcfType of R^o].
Variable a2 : R.
Variable d3 : R -> R^o.
Variable theta4 : R -> angle [rcfType of R^o].
Variable d4 : R.
Let Theta1 : R^o -> R^o := @rad [realType of R^o] \o theta1.
Let Theta2 : R^o -> R^o := @rad [realType of R^o] \o theta2.
Let Theta4 : R^o -> R^o := @rad [realType of R^o] \o theta4.
(* direct kinematics equation written in function of the joint variables,
   from scara.v  *)
Let rot t := scara_rot (theta1 t) (theta2 t) (theta4 t).
Let trans t := scara_trans (theta1 t) a1 (theta2 t) a2 (d3 t) d4.
Definition scara_end_effector t : 'M[R^o]_4 := hom (rot t) (trans t).

Let scara_lin_vel : R -> 'rV[R^o]_3 :=
  derive1mx (@trans_of_hom [rcfType of R^o] \o scara_end_effector).
Let scara_ang_vel : R -> 'rV[R^o]_3 :=
  ang_vel (@rot_of_hom [rcfType of R^o] \o scara_end_effector).

Definition scara_joints : 'I_4 -> joint [rcfType of R] :=
  [eta (fun=> Prismatic 0) with
  0 |-> Revolute Theta1,
  1 |-> Revolute Theta2,
  2%:R |-> Prismatic d3,
  3%:R |-> Revolute Theta4].

Definition scara_joint_variables t : 'rV[R^o]_4 :=
  \row_i (joint_variable (scara_joints i) t).

Let scara_joint_velocities : R^o -> 'rV[R^o]_4 := derive1mx scara_joint_variables.

(* specification of scara frames *)
Variables scara_frames : 'I_5 -> R^o -> tframe [rcfType of R^o].
Let Fim1 (i : 'I_4) := scara_frames (prev_frame i).
Let Fi (i : 'I_4) := scara_frames (next_frame i).
Let Fmax := scara_frames ord_max.
Hypothesis Hzvec : forall t i, \z{Fim1 i t} = 'e_2%:R.
Hypothesis o0E : forall t, \o{Fim1 0 t} = 0.
Hypothesis o1E : forall t, \o{Fim1 1 t} =
  a1 * Cos (Theta1 t) *: 'e_0 + a1 * Sin (Theta1 t) *: 'e_1.
Hypothesis o2E : forall t, \o{Fim1 2%:R t} = \o{Fim1 1 t} +
  (a2 * Cos (Theta1 t + Theta2 t)) *: 'e_0 +
  (a2 * Sin (Theta1 t + Theta2 t)) *: 'e_1.
Hypothesis o3E : forall t, \o{Fim1 3%:R t} = \o{Fim1 2%:R t} + (d3 t) *: 'e_2.
Hypothesis o4E : forall t, \o{Fmax t} = \o{Fim1 3%:R t} + d4 *: 'e_2.

Lemma scara_geometric_jacobian t :
  derivable Theta1 t 1 ->
  derivable Theta2 t 1 ->
  derivable (d3 : R^o -> R^o) t 1 ->
  derivable Theta4 t 1 ->
  scara_joint_velocities t *m geo_jac (mkChain scara_joints scara_frames) t =
  row_mx (scara_lin_vel t) (scara_ang_vel t).
Proof.
move=> H1 H2 H3 H4.
rewrite /geo_jac; set a := (X in _ *m @row_mx _ _ 3 3 X _).
rewrite (mul_mx_row _ a) {}/a; congr (@row_mx _ _ 3 3 _ _).
- rewrite /scara_lin_vel (_ : @trans_of_hom [rcfType of R^o] \o _ = trans); last first.
    rewrite funeqE => x /=; exact: trans_of_hom_hom.
  rewrite /trans /scara_trans derive1mxE [RHS]row3_proj /= ![in RHS]mxE [in RHS]/=.
  transitivity (
      derive1 Theta1 t *: \z{Fim1 0 t} *v (\o{Fmax t} - \o{Fim1 0 t}) +
      derive1 (Theta2) t *: \z{Fim1 1 t} *v (\o{Fmax t} - \o{Fim1 1 t}) +
      derive1 d3 t *: \z{Fim1 2 t} +
      derive1 Theta4 t *: \z{Fim1 3%:R t} *v (\o{Fmax t} - \o{Fim1 3%:R t})).
    rewrite /scara_joint_velocities /scara_joint_variables derive1mxE /geo_jac_lin /=.
    apply/rowP => i; rewrite 3![in RHS]mxE [in LHS]mxE sum4E; congr (_ + _ + _ + _).
    - by rewrite 2!mxE /= crossmulZv [in RHS]mxE.
    - by rewrite 2!mxE /= crossmulZv [in RHS]mxE.
    - by rewrite 2!mxE [in RHS]mxE.
    - by rewrite 2!mxE /= crossmulZv [in RHS]mxE.
  rewrite o0E subr0.
  rewrite {1}o4E.
  rewrite crossmulDr.
  rewrite (@crossmulvZ _ _ 'e_2) {2}Hzvec (@crossmulZv _ _ 'e_2) crossmulvv 2!scaler0 addr0.
  rewrite (_ : \o{Fmax t} - \o{Fim1 1 t} =
    (a2 * Cos (Theta1 t + Theta2 t) *: 'e_0 +
    (a1 * Sin (Theta1 t) + a2 * Sin (Theta1 t + Theta2 t) - a1 * Sin (Theta1 t)) *: 'e_1 +
    (d3 t + d4) *: 'e_2)); last first.
    rewrite (addrC (a1 * Sin _)) addrK.
    rewrite o4E o3E o2E o1E.
    set a := _ *: 'e_0 + _ *: 'e_1.
    rewrite -3!addrA addrC 3!addrA subrK.
    rewrite addrC -[in RHS]addrA; congr (_ + _).
    by rewrite -addrA -scalerDl.
  rewrite crossmulDr.
  rewrite (@crossmulvZ _ _ 'e_2) (@crossmulZv _ _ 'e_2) {2}(Hzvec t 1) crossmulvv 2!scaler0 addr0.
  rewrite (addrC (a1 * Sin _)) addrK.
  rewrite (_ : \o{Fmax t} - \o{Fim1 3%:R t} = d4 *: 'e_2%:R); last first.
    by rewrite o4E -addrA addrC subrK.
  rewrite (crossmulvZ _ 'e_2) (crossmulZv _ 'e_2) {1}(Hzvec t 3%:R) crossmulvv 2!scaler0 addr0.
  rewrite o3E.
  rewrite crossmulDr (@crossmulvZ _ _ 'e_2) (@crossmulZv _ _ 'e_2) {2}(Hzvec t 0) crossmulvv 2!scaler0 addr0.
  rewrite {1}o2E {1}o1E.
  rewrite (_ : (fun _ => _) = (a2 \*: (Cos \o (Theta2 + Theta1))) + (a1 *: (Cos \o Theta1))); last first.
    rewrite funeqE => x /=.
    rewrite -[RHS]/(_ x + _ x); congr (_ * _ + _ * _) => /=; last first.
      by rewrite /Theta1 /Cos /= Rad.fK.
    rewrite -[(Theta2 + Theta1) x]/(_ x + _ x).
    rewrite /Theta2 /Theta1 /=.
    admit.
  rewrite (_ : (fun _ => _) = (a2 \*: (Sin \o (Theta2 + Theta1))) + (a1 *: (Sin \o Theta1))); last first.
    rewrite funeqE => x /=.
    rewrite -[RHS]/(_ x + _ x); congr (_ * _ + _ * _) => /=; last first.
      by rewrite /Theta1 /Sin /= Rad.fK.
    rewrite -[(Theta2 + Theta1) x]/(_ x + _ x).
    rewrite /Theta2 /Theta1 /=.
    admit.
  rewrite row3e2; congr (_ + _ *: _); last first.
  - by rewrite Hzvec.
  - rewrite [in RHS]derive1E deriveD; [|exact: ex_derive|by []].
    by rewrite deriveE // diff_cst add0r derive1E.
  - rewrite !crossmulDr !crossmulvZ !crossmulZv !Hzvec veckj vecki !scalerN.
    rewrite -!addrA addrCA addrC -!addrA (addrCA (- _)) !addrA.
    rewrite -2!addrA [in RHS]addrC; congr (_ + _).
    - rewrite !scalerA -2!scalerDl row3e1; congr (_ *: _).
      rewrite [in RHS]derive1E deriveD; last 2 first.
        exact/derivableZ/derivable_Sin_comp/derivableD.
        exact/derivableZ/derivable_Sin_comp.
      rewrite deriveZ /=; last exact/derivable_Sin_comp/derivableD.
      rewrite deriveZ /=; last exact/derivable_Sin_comp.
      rewrite -derive1E chain_rule; [|exact: derivableD|exact: derivable_Sin].
      rewrite derive1_Sin.
      rewrite -derive1E chain_rule; [|by [] |exact: derivable_Sin].
      rewrite derive1_Sin -addrA addrC; congr (_ + _); last first.
        by rewrite -mulrA.
      rewrite -mulrDr [in RHS]derive1E deriveD // -mulrA; congr (_ * _).
      rewrite addrC; congr (_ * _).
      by rewrite addrC !derive1E.
    - rewrite !scalerA !addrA -3!scaleNr -2!scalerDl row3e0; congr (_ *: _).
      rewrite [in RHS]derive1E deriveD; last 2 first.
        exact/derivableZ/derivable_Cos_comp/derivableD.
        exact/derivableZ/derivable_Cos_comp.
      rewrite deriveZ /=; last exact/derivable_Cos_comp/derivableD.
      rewrite deriveZ /=; last exact/derivable_Cos_comp.
      rewrite -derive1E chain_rule; [|exact: derivableD|exact: derivable_Cos].
      rewrite derive1_Cos mulNr scalerN.
      rewrite -derive1E chain_rule; [|by [] |exact: derivable_Cos].
      rewrite derive1_Cos mulNr scalerN; congr (_ - _); last first.
        by rewrite -mulrA.
      rewrite -mulrN -mulrBr -opprD mulrN [in RHS]derive1E deriveD //.
      rewrite -!mulrA -!mulNr; congr (_ * _).
      rewrite addrC; congr (_ * _).
      by rewrite addrC !derive1E.
- rewrite /scara_ang_vel (_ : @rot_of_hom [rcfType of R^o] \o _ = rot); last first.
    rewrite funeqE => x /=; exact: rot_of_hom_hom.
  rewrite /rot /ang_vel /scara_rot.
  rewrite (_ : (fun _ => _) = (@Rz _ \o @Rad.angle_of _ \o (Theta1 + Theta2 + Theta4))); last first.
    rewrite funeqE => x; congr Rz.
    rewrite -[(Theta1 + Theta2 + Theta4) x]/(Theta1 x + Theta2 x + Theta4 x).
    admit.
  rewrite ang_vel_mx_Rz; last by apply derivableD; [exact/derivableD|by []].
  rewrite spinK.
  transitivity (derive1 Theta1 t *: \z{Fim1 0 t} +
                derive1 (Theta2) t *: \z{Fim1 1 t} +
                derive1 Theta4 t *: \z{Fim1 3%:R t}).
    rewrite /scara_joint_velocities /scara_joint_variables derive1mxE /geo_jac_ang /=.
    apply/rowP => i; rewrite !mxE sum4E !mxE mulr0 addr0.
    by rewrite -!/(Fim1 _) [Fim1 0 _]lock [Fim1 1 _]lock [Fim1 3%:R _]lock /= -!lock.
  rewrite !Hzvec -2!scalerDl e2row row3Z mulr0 mulr1.
  rewrite [in RHS]derive1E deriveD; [|exact/derivableD|by []].
  rewrite deriveD; [|by [] |by []].
  by rewrite 3!derive1E.
Admitted.

End scara_geometric_jacobian.

Section analytical_jacobian.

Variable n' : nat.
Let n := n'.+1.
Variable (p : 'rV[R^o]_n -> 'rV[R^o]_3).
Let Jp := jacobian p.
Variable (phi : 'rV[R^o]_n -> 'rV[R^o]_3).
Let Jphi := jacobian phi.

Lemma dp (q : R^o -> 'rV[R^o]_n) t :
  derive1mx (p \o q) t = derive1mx q t *m Jp (q t). (* 3.56 *)
Proof.
rewrite /Jp /jacobian mul_rV_lin1.
rewrite /derive1mx.
Abort.

End analytical_jacobian.

(*Section tangent_vectors.

Variable R : realType.
Let vector := 'rV[R]_3.
Let point := 'rV[R]_3.
Implicit Types p : point.

(* tangent vector *)
Record tvec p := TVec {tvec_field :> vector}.
Definition vtvec p (v : tvec p) := let: TVec v := v in v.

Local Notation "p .-vec" := (tvec p) (at level 5).
Local Notation "u :@ p" := (TVec p u) (at level 11).

Definition addt (p : point) (u : p.-vec) (v : vector) : p.-vec :=
  TVec p (tvec_field u + v).

Local Notation "p +@ u" := (addt p u) (at level 41).

End tangent_vectors.

Coercion vtvec_field_coercion := vtvec.
Notation "p .-vec" := (tvec p) (at level 5).
Notation "u :@ p" := (TVec p u) (at level 11).
Notation "p +@ u" := (addt p u) (at level 41).*)
