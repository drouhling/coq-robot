(* coq-robot (c) 2017 AIST and INRIA. License: LGPL v3. *)
From mathcomp Require Import ssreflect ssrfun ssrbool eqtype ssrnat seq choice.
From mathcomp Require Import fintype tuple finfun bigop ssralg ssrint div.
From mathcomp Require Import ssrnum rat poly closed_field polyrcf matrix.
From mathcomp Require Import mxalgebra tuple mxpoly zmodp binomial realalg.
From mathcomp Require Import complex finset fingroup perm.

From mathcomp.analysis Require Import forms.

Require Import ssr_ext.

(*
 OUTLINE:
 1. section dot_product
 2. section norm
    includes section norm1 (unit norm)
 3. section row2
    section row3
 4. section col_mx2_col_mx3
    specialization of col_mx to row vectors of length 2, 3
 5. section extra_linear3
    extra lemmas about linear algebra specialized to dimensions <= 3
 6. section normal
 7. section crossmul
    (sample lemma: double_crossmul)
 8. section orthogonal_rotation_def
    section orthogonal_rotation_properties.
    section orthogonal_crossmul
    (most lemmas specialized for dim 3)
    (sample lemma: Euler's theorem,
                   orth_preserves_dotmul)
    (sample lemma: multiplication by O_3[R] preserves norm)
 9. section norm3
    (some specialized lemmas for dimension 3)
 10. section properties_of_canonical_vectors
 11. section normalize
 12. section characteristic_polynomial_dim3
     closed formula for the characteristic polynomial of a 3x3 matrix
*)
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory Num.Theory.

Reserved Notation "*d%R".
Reserved Notation "u *d w" (at level 40).
Reserved Notation "*v%R".
Reserved Notation "u *v w" (at level 40).
Reserved Notation "''O[' T ]_ n"
  (at level 8, n at level 2, format "''O[' T ]_ n").
Reserved Notation "''SO[' T ]_ n"
  (at level 8, n at level 2, format "''SO[' T ]_ n").

Local Open Scope ring_scope.

From mathcomp.analysis Require Import topology hierarchy.

Section dot_product0.

Variables (R : ringType) (n : nat).

Implicit Types u v w : 'rV[R]_n.

Definition dotmul u v : R := (u *m v^T)``_0.
Local Notation "*d%R" := (@dotmul _).
Local Notation "u *d w" := (dotmul u w).

Lemma dotmulP u v : u *m v^T = (u *d v)%:M.
Proof. by rewrite /dotmul -mx11_scalar. Qed.

Lemma dotmulE u v : u *d v = \sum_k u``_k * v``_k.
Proof. by rewrite [LHS]mxE; apply: eq_bigr=> i; rewrite mxE. Qed.

Lemma dotmul0v v : 0 *d v = 0.
Proof. by rewrite [LHS]mxE big1 // => i; rewrite mxE mul0r. Qed.

Lemma dotmulv0 v : v *d 0 = 0.
Proof. by rewrite /dotmul trmx0 mulmx0 mxE. Qed.

Lemma dotmulDr u b c : u *d (b + c) = u *d b + u *d c.
Proof. by rewrite {1}/dotmul linearD /= mulmxDr mxE. Qed.

Lemma dotmulDl u b c : (b + c) *d u = b *d u + c *d u.
Proof. by rewrite {1}/dotmul mulmxDl mxE. Qed.

Lemma dotmulvN u v : u *d -v = - (u *d v).
Proof. by rewrite /dotmul linearN /= mulmxN mxE. Qed.

Lemma dotmulNv u v : - u *d v = - (u *d v).
Proof. by rewrite /dotmul mulNmx mxE. Qed.

Lemma dotmulBr u b c : u *d (b - c) = u *d b - u *d c.
Proof. by rewrite dotmulDr dotmulvN. Qed.

Lemma dotmulBl u b c : (b - c) *d u = b *d u - c *d u.
Proof. by rewrite dotmulDl dotmulNv. Qed.

Lemma dotmulZv u k v : (k *: u) *d v = k * (u *d v).
Proof. by rewrite /dotmul -scalemxAl mxE. Qed.

Lemma dotmul_delta_mx u i : u *d 'e_i = u``_i.
Proof.
rewrite /dotmul trmx_delta mxE (bigD1 i) //= mxE !eqxx mulr1.
by rewrite big1 ?addr0 // => j jnei; rewrite mxE (negbTE jnei) /= mulr0.
Qed.

Lemma dote2 i j : ('e_i : 'rV[R]_n) *d 'e_j = (i == j)%:R.
Proof. by rewrite dotmul_delta_mx mxE eqxx eq_sym. Qed.

(* Lemma dotmul_eq u v : (forall x, u *d x = v *d x) -> u = v. *)
(* Proof. by move=> uv; apply/rowP => i; rewrite -!dotmul_delta_mx uv. Qed. *)

Lemma mxE_dotmul_row_col m p (M : 'M[R]_(m, n)) (N : 'M[R]_(n, p)) i j :
  (M *m N) i j = (row i M) *d (col j N)^T.
Proof. rewrite !mxE dotmulE; apply/eq_bigr => /= k _; by rewrite !mxE. Qed.

Lemma coorE (p : 'rV[R]_n) i : p``_i = p *d 'e_i.
Proof. by rewrite dotmul_delta_mx. Qed.

Lemma colE (v : 'rV[R]_n) j : col j v = 'e_j *m v^T.
Proof.
apply/colP => i; rewrite {i}(ord1 i) !mxE coorE /dotmul mxE.
apply: eq_bigr => /= i _; rewrite !mxE eqxx /=.
case: (eqVneq i j)=> [->|/negbTE->] /=; first by rewrite eqxx mulr1 mul1r.
by rewrite mulr0 mul0r.
Qed.

Lemma mxE_dotmul (M : 'M[R]_n) i j : M i j = 'e_j *d row i M.
Proof. by rewrite mxE_col_row /dotmul colE. Qed.

End dot_product0.

Notation "*d%R" := (@dotmul _ _) : ring_scope.
Notation "u *d w" := (dotmul u w) : ring_scope.

Section com_dot_product.

Variables (R : comRingType) (n : nat).

Implicit Types u v : 'rV[R]_n.

Lemma dotmulC u v : u *d v = v *d u.
Proof. by rewrite /dotmul -[_ *m _]trmxK trmx_mul !trmxK mxE. Qed.

Lemma dotmulD u v : (u + v) *d (u + v) = u *d u + (u *d v) *+ 2 + v *d v.
Proof. by rewrite dotmulDr 2!dotmulDl mulr2n !addrA ![v *d _]dotmulC. Qed.

Lemma dotmulvZ u k v : u *d (k *: v) = k * (u *d v).
Proof. by rewrite /dotmul linearZ /= -scalemxAr mxE. Qed.

Lemma dotmul_trmx u M v : u *d (v *m M) = (u *m M^T) *d v.
Proof. by rewrite /dotmul trmx_mul mulmxA. Qed.

End com_dot_product.

(* TODO: make better use of the bilinear theory? *)
Section dotmul_bilinear.

Variables (R : comRingType) (n : nat).

Definition dotmul_rev (v u : 'rV[R]_n) := u *d v.
Canonical rev_dotmul := @RevOp _ _ _ dotmul_rev (@dotmul R n)
  (fun _ _ => erefl).

Lemma dotmul_is_linear u : GRing.linear (dotmul u : 'rV[R]_n -> R^o).
Proof. move=> /= k v w; by rewrite dotmulDr dotmulvZ. Qed.
Canonical dotmul_linear x := Linear (dotmul_is_linear x).

Lemma dotmul_rev_is_linear v : GRing.linear (dotmul_rev v : 'rV[R]_n -> R^o).
Proof. move=> /= k u w; by rewrite /dotmul_rev dotmulDl dotmulZv. Qed.
Canonical dotmul_rev_linear v := Linear (dotmul_rev_is_linear v).

Canonical dotmul_bilinear := [bilinear of (@dotmul R n)].

End dotmul_bilinear.

Section dot_product.

Variables (T : realDomainType) (n : nat).

Implicit Types u v w : 'rV[T]_n.

Lemma le0dotmul u : 0 <= u *d u.
Proof. rewrite dotmulE sumr_ge0 // => i _; by rewrite -expr2 sqr_ge0. Qed.

Lemma dotmulvv0 u : (u *d u == 0) = (u == 0).
Proof.
apply/idP/idP; last by move/eqP ->; rewrite dotmul0v.
rewrite dotmulE psumr_eq0; last by move=> i _; rewrite -expr2 sqr_ge0.
move/allP => H; apply/eqP/rowP => i.
apply/eqP; by rewrite mxE -sqrf_eq0 expr2 -(implyTb ( _ == _)) H.
Qed.

End dot_product.

Section norm.

Variables (T : rcfType) (n : nat).
Implicit Types u v : 'rV[T]_n.

Definition norm u := Num.sqrt (u *d u).

Lemma normN u : norm (- u) = norm u.
Proof. by rewrite /norm dotmulNv dotmulvN opprK. Qed.

Lemma norm0 : norm 0 = 0.
Proof. by rewrite /norm dotmul0v sqrtr0. Qed.

Lemma norm_delta_mx i : norm 'e_i = 1.
Proof. by rewrite /norm /dotmul trmx_delta mul_delta_mx mxE !eqxx sqrtr1. Qed.

Lemma norm_ge0 u : norm u >= 0.
Proof. by apply sqrtr_ge0. Qed.
Hint Resolve norm_ge0.

Lemma normr_norm u : `|norm u| = norm u.
Proof. by rewrite ger0_norm. Qed.

Lemma norm_eq0 u : (norm u == 0) = (u == 0).
Proof. by rewrite -sqrtr0 eqr_sqrt // ?dotmulvv0 // le0dotmul. Qed.

Lemma norm_gt0 u : (0 < norm u) = (u != 0).
Proof. by rewrite ltr_neqAle norm_ge0 andbT eq_sym norm_eq0. Qed.

Lemma normZ (k : T) u : norm (k *: u) = `|k| * norm u.
Proof.
by rewrite /norm dotmulvZ dotmulZv mulrA sqrtrM -expr2 ?sqrtr_sqr // sqr_ge0.
Qed.

Lemma dotmulvv u : u *d u = norm u ^+ 2.
Proof.
rewrite /norm [_ ^+ _]sqr_sqrtr // dotmulE sumr_ge0 //.
by move=> i _; rewrite sqr_ge0.
Qed.

Lemma polarization_identity v u :
  v *d u = 1 / 4%:R * (norm (v + u) ^+ 2 - norm (v - u) ^+ 2).
Proof.
apply: (@mulrI _ 4%:R); first exact: pnatf_unit.
rewrite [in RHS]mulrA div1r divrr ?pnatf_unit // mul1r.
rewrite -2!dotmulvv dotmulD dotmulD mulr_natl (addrC (v *d v)).
rewrite (_ : 4 = 2 + 2)%N // mulrnDr -3![in RHS]addrA; congr (_ + _).
rewrite opprD addrCA [_ + (- _ + _)]addrA subrr add0r.
by rewrite addrC opprD 2!dotmulvN dotmulNv opprK subrK -mulNrn opprK.
Qed.

Lemma sqr_norm u : norm u ^+ 2 = \sum_i u``_i ^+ 2.
Proof. rewrite -dotmulvv dotmulE; apply/eq_bigr => /= i _; by rewrite expr2. Qed.

Lemma mxtrace_tr_mul u : \tr (u^T *m u) = norm u ^+ 2.
Proof.
rewrite /mxtrace sqr_norm; apply/eq_bigr => /= i _; by rewrite mulmx_trE -expr2.
Qed.

Section norm1.

Variable u : 'rV[T]_n.
Hypothesis u1 : norm u = 1.

Lemma norm1_neq0 : u != 0.
Proof. move: u1; rewrite -norm_eq0 => ->; exact: oner_neq0. Qed.

Lemma dotmul1 : u *m u^T = 1.
Proof. by rewrite dotmulP dotmulvv u1 expr1n. Qed.

End norm1.

End norm.

Section row2.

Variable T : ringType.

Definition row2 (a b : T) : 'rV[T]_2 :=
  \row_p [eta \0 with 0 |-> a, 1 |-> b] p.

Lemma row2_of_row (M : 'M[T]_2) i : row i M = row2 (M i 0) (M i 1).
Proof. by apply/rowP=> j; rewrite !mxE /=; case: ifPn=> [|/ifnot01P]/eqP->. Qed.

End row2.

Section row3.

Variable T : ringType.
Implicit Types a b c : T.

Definition row3 a b c : 'rV[T]_3 :=
  \row_p [eta \0 with 0 |-> a, 1 |-> b, 2%:R |-> c] p.

Lemma col_row3 a b c i : col i (row3 a b c) = ((row3 a b c) ``_ i)%:M.
Proof. by apply/rowP => k; rewrite (ord1 k) !mxE /= mulr1n. Qed.

Lemma row_mx_colE n (A : 'M[T]_(n, 3)) :
  row_mx (col 0 A) (row_mx (col 1 A) (col 2%:R A)) = A.
Proof.
rewrite -[in RHS](@hsubmxK _ n 1 2 A) (_ : lsubmx _ = col 0 A); last first.
  apply/colP => i; rewrite !mxE /= (_ : lshift 2 0 = 0) //; exact/val_inj.
rewrite (_ : rsubmx _ = row_mx (col 1 A) (col 2%:R A)) //.
set a := rsubmx _; rewrite -[in LHS](@hsubmxK _ n 1 1 a); congr row_mx.
  apply/colP => i; rewrite !mxE /= (_ : rshift 1 _ = 1) //; exact/val_inj.
apply/colP => i; rewrite !mxE /= (_ : rshift 1 (rshift 1 0) = 2%:R) //.
exact/val_inj.
Qed.

Lemma row3E a b c : row3 a b c = row_mx a%:M (row_mx b%:M c%:M).
Proof. by rewrite -[LHS]row_mx_colE !col_row3 !mxE. Qed.

Lemma row_row3 n (M : 'M[T]_(n, 3)) i : row i M = row3 (M i 0) (M i 1) (M i 2%:R).
Proof.
by apply/rowP=> k; rewrite !mxE /=; case: ifPn=>[|/ifnot0P/orP[]]/eqP->.
Qed.

Lemma row3N a b c : - row3 a b c = row3 (- a) (- b) (- c).
Proof.
apply/rowP => i; rewrite !mxE /= ; case: ifPn; rewrite ?opprB // => ?.
by case: ifPn; rewrite ?opprB // => ?; case: ifPn; rewrite ?opprB // oppr0.
Qed.

Lemma row3Z a b c k : k *: row3 a b c = row3 (k * a) (k * b) (k * c).
Proof.
apply/rowP => i; rewrite !mxE /=.
case: ifPn => // ?; case: ifPn => // ?; case: ifPn => // ?; by Simp.r.
Qed.

Lemma row3D a b c a' b' c' :
  row3 a b c + row3 a' b' c' = row3 (a + a') (b + b') (c + c').
Proof.
rewrite 3!row3E (add_row_mx a%:M) (add_row_mx b%:M).
rewrite -(scalemx1 _ a) -(scalemx1 _ a') -(scalemx1 _ b) -(scalemx1 _ b').
rewrite -(scalemx1 _ c) -(scalemx1 _ c'); by do 3! rewrite -scalerDl scalemx1.
Qed.

Lemma row30 : row3 0 0 0 = 0 :> 'rV[T]_3.
Proof. by apply/rowP => a; rewrite !mxE /=; do 3 case: ifPn => //. Qed.

Lemma e0row : 'e_0 = row3 1 0 0.
Proof.
by apply/rowP=> i; rewrite !mxE /=; case: ifPn=> //;
  rewrite ifnot0=> /orP[]/eqP ->.
Qed.

Lemma e1row : 'e_1 = row3 0 1 0.
Proof.
by apply/rowP => i; rewrite !mxE /=; case: ifPn => [/eqP -> //|];
  rewrite ifnot0=> /orP[]/eqP ->.
Qed.

Lemma e2row : 'e_2%:R = row3 0 0 1.
Proof.
by apply/rowP => i; rewrite !mxE /=; case: ifPn => [/eqP -> //|];
  rewrite ifnot0=> /orP[]/eqP ->.
Qed.

Lemma row3_proj (u : 'rV[T]_3) :
  u = row3 (u``_0) 0 0 + row3 0 (u``_1) 0 + row3 0 0 (u``_2%:R).
Proof.
rewrite 2!row3D !(addr0,add0r); apply/rowP => k; by rewrite -row_row3 mxE.
Qed.

Lemma row3e0 a : row3 a 0 0 = a *: 'e_0.
Proof. by rewrite e0row row3Z mulr1 mulr0. Qed.

Lemma row3e1 a : row3 0 a 0 = a *: 'e_1.
Proof. by rewrite e1row row3Z mulr1 mulr0. Qed.

Lemma row3e2 a : row3 0 0 a = a *: 'e_2%:R.
Proof. by rewrite e2row row3Z mulr1 mulr0. Qed.

End row3.

Lemma norm_row3z (T : rcfType) (z : T) : norm (row3 0 0 z) = `|z|.
Proof. by rewrite /norm dotmulE sum3E !mxE /= ?(mul0r,add0r) sqrtr_sqr. Qed.

Section col_mx2_col_mx3.

Section col_mx2.
Variable (T : ringType).
Implicit Types (u v : 'rV[T]_2) (M : 'M[T]_2).

Definition col_mx2 u v := \matrix_(i < 2) [eta \0 with 0 |-> u, 1 |-> v] i.

Lemma eq_col_mx2 a a' b b' c c' d d' :
  col_mx2 (row2 a b) (row2 c d) = col_mx2 (row2 a' b') (row2 c' d') ->
  [/\ a = a', b = b', c = c' & d = d'].
Proof.
move/matrixP => H; split; by [
  move/(_ 0 0) : H; rewrite !mxE | move/(_ 0 1) : H; rewrite !mxE |
  move/(_ 1 0) : H; rewrite !mxE | move/(_ 1 1) : H; rewrite !mxE].
Qed.

Lemma col_mx2_rowE M : M = col_mx2 (row 0 M) (row 1 M).
Proof.
apply/row_matrixP => i; by rewrite rowK /=; case: ifPn => [|/ifnot01P]/eqP->.
Qed.

Lemma mul_col_mx2 n (c1 c2 : 'cV[T]_n) u v :
  row_mx c1 c2 *m col_mx2 u v =
  row_mx (c1 *m u``_0%:M + c2 *m v``_0%:M) (c1 *m u``_1%:M + c2 *m v``_1%:M).
Proof.
suff -> : col_mx2 u v = @block_mx _ 1 1 1 1 u``_0%:M u``_1%:M v``_0%:M v``_1%:M.
  by rewrite (mul_row_block c1 c2 u``_0%:M).
apply/matrixP => a b; case/boolP : (a == 0) => a0.
- case/boolP : (b == 0) => b0.
  + rewrite (eqP a0) (eqP b0) !mxE /= split1 unlift_none //=.
    by rewrite !mxE split1 unlift_none /= !mxE eqxx mulr1n.
  + have /eqP b1 : b == 1 by rewrite -ifnot01.
    rewrite b1 (eqP a0) [in LHS]mxE /=.
    transitivity ((block_mx u``_0%:M u``_1%:M v``_0%:M v``_1%:M)
                    (lshift 1 0) (rshift 1 0)); last by f_equal; exact/val_inj.
    by rewrite block_mxEur mxE eqxx mulr1n.
- have a1 : a == 1 by rewrite -ifnot01.
  case/boolP : (b == 0) => b0.
  + rewrite (eqP a1) (eqP b0) [in LHS]mxE /=.
    transitivity ((block_mx u``_0%:M u``_1%:M v``_0%:M v``_1%:M)
                    (rshift 1 0) (lshift 1 0)); last by f_equal; exact/val_inj.
    by rewrite block_mxEdl mxE eqxx mulr1n.
  + have /eqP b1 : b == 1 by rewrite -ifnot01.
    rewrite (eqP a1) b1 [in LHS]mxE /=.
    transitivity ((block_mx u``_0%:M u``_1%:M v``_0%:M v``_1%:M)
      (rshift 1 0) (rshift 1 0)); last by f_equal; exact/val_inj.
    by rewrite block_mxEdr mxE eqxx mulr1n.
Qed.

End col_mx2.

Section col_mx3.
Variable (T : ringType).
Implicit Types (u v w : 'rV[T]_3) (M : 'M[T]_3).

Definition col_mx3 u v w :=
  \matrix_(i < 3) [eta \0 with 0 |-> u, 1 |-> v, 2%:R |-> w] i.

Lemma col_mx3_rowE M : M = col_mx3 (row 0 M) (row 1 M) (row 2%:R M).
Proof.
apply/row_matrixP=> i; by rewrite rowK /=; case: ifPn=> [|/ifnot0P/orP[]]/eqP->.
Qed.

Lemma mulmx_row3_col3 a b c u v w :
  row3 a b c *m col_mx3 u v w = a *: u + b *: v + c *: w.
Proof. apply/rowP => n; by rewrite !mxE sum3E !mxE. Qed.

Lemma col_mx3E u v w : col_mx3 u v w = col_mx u (col_mx v w).
Proof.
rewrite [LHS]col_mx3_rowE; apply/row_matrixP => i; rewrite !rowK /=.
case: ifPn => [|/ifnot0P/orP[]]/eqP->.
- rewrite (_ : 0 = @lshift 1 _ 0) ?(@rowKu _ 1) ?row_id //; exact: val_inj.
- rewrite (_ : 1 = @rshift 1 _ 0) ?(@rowKd _ 1); last exact: val_inj.
  rewrite  (_ : 0 = @lshift 1 _ 0) ?(@rowKu _ 1) ?row_id //; exact: val_inj.
- rewrite (_ : 2%:R = @rshift 1 _ 1) ?(@rowKd _ 1); last exact: val_inj.
  rewrite (_ : 1 = @rshift 1 1 0) ?(@rowKd _ 1) ?row_id //; exact: val_inj.
Qed.

Lemma row'_col_mx3 (i : 'I_3) (u v w : 'rV[T]_3) :
  row' i (col_mx3 u v w) = [eta \0 with
  0 |-> \matrix_(k < 2) [eta \0 with 0 |-> v, 1 |-> w] k,
  1 |-> \matrix_(k < 2) [eta \0 with 0 |-> u, 1 |-> w] k,
  2%:R |-> \matrix_(k < 2) [eta \0 with 0 |-> u, 1 |-> v] k] i.
Proof.
case: i => [[|[|[|?]]]] ?; apply/matrixP=> [] [[|[|[|?]]]] ? j;
by rewrite !mxE.
Qed.

Lemma col_mx3_perm_12 u v w : xrow 1 2%:R (col_mx3 u v w) = col_mx3 u w v.
Proof.
apply/matrixP => -[[|[|[] //]] ?] [[|[|[] //]] ?]; by rewrite !mxE permE.
Qed.

Lemma col_mx3_perm_01 u v w : xrow 0 1 (col_mx3 u v w) = col_mx3 v u w.
Proof.
apply/matrixP => -[[|[|[] //]] ?] [[|[|[] //]] ?]; by rewrite !mxE permE.
Qed.

Lemma col_mx3_perm_02 u v w : xrow 0 2%:R (col_mx3 u v w) = col_mx3 w v u.
Proof.
apply/matrixP => -[[|[|[] //]] ?] [[|[|[] //]] ?]; by rewrite !mxE permE.
Qed.

Lemma mulmx_col3 M u v w : col_mx3 u v w *m M = col_mx3 (u *m M) (v *m M) (w *m M).
Proof.
apply/matrixP => i j.
move: i => -[[|[|[] // ]] ?]; rewrite !mxE; apply eq_bigr => /= ? _; by rewrite mxE.
Qed.

Lemma mul_tr_col_mx3 (x : 'rV[T]_3) a b c :
  x *m (col_mx3 a b c)^T = row3 (x *d a) (x *d b) (x *d c).
Proof.
rewrite col_mx3E (tr_col_mx a) (tr_col_mx b) (mul_mx_row x a^T).
by rewrite row3E (mul_mx_row x b^T) 3!dotmulP.
Qed.

End col_mx3.

End col_mx2_col_mx3.

Section extra_linear3.

Lemma matrix2P (T : eqType) (A B : 'M[T]_2) :
  reflect (A = B)
    [&& A 0 0 == B 0 0, A 0 1 == B 0 1, A 1 0 == B 1 0 & A 1 1 == B 1 1].
Proof.
apply (iffP idP); last by move=> ->; rewrite !eqxx.
case/and4P => /eqP ? /eqP ? /eqP ? /eqP ?; apply/matrixP => i j.
case/boolP : (i == 0) => [|/ifnot01P]/eqP->;
  by case/boolP : (j == 0) => [|/ifnot01P]/eqP->.
Qed.

Lemma matrix3P (T : eqType) (A B : 'M[T]_3) :
  reflect (A = B)
    [&& A 0 0 == B 0 0, A 0 1 == B 0 1, A 0 2%:R == B 0 2%:R,
        A 1 0 == B 1 0, A 1 1 == B 1 1, A 1 2%:R == B 1 2%:R,
        A 2%:R 0 == B 2%:R 0, A 2%:R 1 == B 2%:R 1 & A 2%:R 2%:R == B 2%:R 2%:R].
Proof.
apply (iffP idP) => [|]; last by move=> ->; rewrite !eqxx.
case/and9P; do 9 move/eqP => ?; apply/matrixP => i j.
case/boolP : (i == 0) => [|/ifnot0P/orP[]]/eqP->;
  by case/boolP : (j == 0) => [|/ifnot0P/orP[]]/eqP->.
Qed.

Lemma vec3E (T : ringType) (u : 'rV[T]_3) :
  u = (u``_0) *: 'e_0 + (u``_1) *: 'e_1 + (u``_2%:R) *: 'e_2%:R.
Proof. rewrite [LHS]row3_proj e0row e1row e2row !row3Z. by Simp.r. Qed.

Lemma mx_lin1K (T : ringType) (Q : 'M[T]_3) : lin1_mx (mx_lin1 Q) = Q.
Proof. apply/matrix3P; by rewrite !mxE !sum3E !mxE !eqxx /=; Simp.r. Qed.

Lemma det_mx11 (T : comRingType) (A : 'M[T]_1) : \det A = A 0 0.
Proof. by rewrite {1}[A]mx11_scalar det_scalar. Qed.

Lemma cofactor_mx22 (T : comRingType) (A : 'M[T]_2) i j :
  cofactor A i j = (-1) ^+ (i + j) * A (i + 1) (j + 1).
Proof.
rewrite /cofactor det_mx11 !mxE; congr (_ * A _ _);
by apply/val_inj; move: i j => [[|[|?]]?] [[|[|?]]?].
Qed.

Lemma det_mx22 (T : comRingType) (A : 'M[T]_2) : \det A = A 0 0 * A 1 1 -  A 0 1 * A 1 0.
Proof.
rewrite (expand_det_row _ ord0) !(mxE, big_ord_recl, big_ord0).
rewrite !(mul0r, mul1r, addr0) !cofactor_mx22 !(mul1r, mulNr, mulrN).
by rewrite !(lift0E, add0r) /= addrr_char2.
Qed.

Lemma cofactor_mx33 (T : comRingType) (A : 'M[T]_3) i j :
  cofactor A i j = (-1) ^+ (i + j) *
                   (A (i == 0)%:R (j == 0)%:R * A ((i <= 1).+1%:R) ((j <= 1).+1%:R) -
                    A (i == 0)%:R ((j <= 1).+1%:R) * A ((i <= 1).+1%:R) (j == 0)%:R).
Proof.
rewrite /cofactor det_mx22 !mxE; congr (_ * (A _ _ * A _ _ - A _ _ * A _ _));
  by rewrite (liftE0, liftE1).
Qed.

Lemma det_mx33 (T : comRingType) (M : 'M[T]_3) :
  \det M = M 0 0 * (M 1 1 * M 2%:R 2%:R - M 2%:R 1 * M 1 2%:R) +
           M 0 1 * (M 2%:R 0 * M 1 2%:R - M 1 0 * M 2%:R 2%:R) +
           M 0 2%:R * (M 1 0 * M 2%:R 1 - M 2%:R 0 * M 1 1).
Proof.
rewrite (expand_det_row M 0) sum3E -2!addrA; congr (_ * _ + (_ * _ + _ * _)).
  by rewrite cofactor_mx33 /= expr0 mul1r [in X in _ - X]mulrC.
by rewrite cofactor_mx33 /= expr1 mulN1r opprB mulrC.
by rewrite cofactor_mx33 expr2 mulN1r opprK mul1r /= [in X in _ - X]mulrC.
Qed.

Lemma mxtrace_sqr (T : comRingType) (M : 'M[T]_3) : \tr (M ^+ 2) =
  \sum_i (M i i ^+2) + M 0 1 * M 1 0 *+ 2 + M 0 2%:R * M 2%:R 0 *+ 2 +
  M 1 2%:R * M 2%:R 1 *+ 2.
Proof.
rewrite sum3E.
transitivity (\sum_(i < 3) (row i M) *d (col i M)^T).
  by apply/eq_bigr => i _; rewrite mxE_dotmul_row_col.
rewrite sum3E !dotmulE !sum3E !mxE -!expr2 -!addrA; congr (_ + _).
do 3 rewrite addrC -!addrA; congr (_ + _).
do 3 rewrite addrC -!addrA; congr (_ + _).
congr (_ + _).
rewrite addrC -!addrA mulrC; congr (_ + _).
rewrite addrC -!addrA mulrC; congr (_ + _).
rewrite addrC -!addrA; congr (_ + _).
by rewrite mulrC.
Qed.

Lemma sqr_mxtrace {T : comRingType} (M : 'M[T]_3) : (\tr M) ^+ 2 =
  \sum_i (M i i ^+2) + M 0 0 * M 1 1 *+ 2 + (M 0 0 + M 1 1) * M 2%:R 2%:R *+ 2.
Proof.
rewrite /mxtrace sum3E 2!sqrrD sum3E -!addrA; congr (_ + _).
do 2 rewrite addrC -!addrA; congr (_ + _).
do 2 rewrite addrC -!addrA; congr (_ + _).
Qed.

End extra_linear3.

Section normal.

Variable T : fieldType.

Local Notation "A _|_ B" := (A%MS <= kermx B%MS^T)%MS (at level 69).

Lemma normal_sym k m (A : 'M[T]_(k,3)) (B : 'M[T]_(m,3)) :
  A _|_ B = B _|_ A.
Proof.
rewrite !(sameP sub_kermxP eqP) -{1}[A]trmxK -trmx_mul.
by rewrite -{1}trmx0 (inj_eq (@trmx_inj _ _ _)).
Qed.

Lemma normalNm k m (A : 'M[T]_(k,3)) (B : 'M[T]_(m,3)) : (- A) _|_ B = A _|_ B.
Proof. by rewrite eqmx_opp. Qed.

Lemma normalmN k m (A : 'M[T]_(k,3)) (B : 'M[T]_(m,3)) : A _|_ (- B) = A _|_ B.
Proof. by rewrite ![A _|_ _]normal_sym normalNm. Qed.

Lemma normalDm k m p (A : 'M[T]_(k,3)) (B : 'M[T]_(m,3)) (C : 'M[T]_(p,3)) :
  (A + B _|_ C) = (A _|_ C) && (B _|_ C).
Proof. by rewrite addsmxE !(sameP sub_kermxP eqP) mul_col_mx col_mx_eq0. Qed.

Lemma normalmD  k m p (A : 'M[T]_(k,3)) (B : 'M[T]_(m,3)) (C : 'M[T]_(p,3)) :
  (A _|_ B + C) = (A _|_ B) && (A _|_ C).
Proof. by rewrite ![A _|_ _]normal_sym normalDm. Qed.

Implicit Types u v w : 'rV[T]_3.

Lemma normalvv u v : (u _|_ v) = (u *d v == 0).
Proof. by rewrite (sameP sub_kermxP eqP) dotmulP fmorph_eq0. Qed.

End normal.

Local Notation "A _|_ B" := (A%MS <= kermx B%MS^T)%MS (at level 69).
(*Local Notation "u _|_ A" := (u <= kermx A^T)%MS (at level 8).
Local Notation "u _|_ A , B " := (u _|_ (col_mx A B))
 (A at next level, at level 8,
 format "u  _|_  A , B ").*)

Section crossmul.

Variable T : comRingType.

Implicit Types u v w : 'rV[T]_3.

Definition crossmul u v := \row_(k < 3) \det (col_mx3 'e_k u v).

Local Notation "*v%R" := (@crossmul _).
Local Notation "u *v w" := (crossmul u w).

Lemma crossmulC u v : u *v v = - (v *v u).
Proof.
rewrite /crossmul; apply/rowP => k; rewrite !mxE.
set M := (X in - \det X).
transitivity (\det (row_perm (tperm (1 : 'I__) 2%:R) M)); last first.
  by rewrite row_permE detM det_perm odd_tperm /= expr1 mulN1r.
congr (\det _); apply/matrixP => i j; rewrite !mxE permE /=.
by case: i => [[|[|[]]]] ?.
Qed.

Lemma crossmulvv u : u *v u = 0.
Proof.
apply/rowP=> i; rewrite !mxE (@determinant_alternate _ _ _ 1 2%:R) //.
by move=> j; rewrite !mxE.
Qed.

Lemma crossmul0v u : 0 *v u = 0.
Proof.
apply/rowP=> k; rewrite !mxE (expand_det_row _ 1) big1 // => i _.
by rewrite 2!mxE mul0r.
Qed.

Lemma crossmulv0 u : u *v 0 = 0.
Proof. by rewrite crossmulC crossmul0v oppr0. Qed.

Lemma crossmul_triple u v w : u *d (v *v w) = \det (col_mx3 u v w).
Proof.
pose M (k : 'I_3) : 'M_3 := col_mx3 ('e_k) v w.
pose Mu12 := col_mx3 (u``_1 *: 'e_1 + u``_2%:R *: 'e_2%:R) v w.
rewrite (@determinant_multilinear _ _ _ (M 0) Mu12 0 (u``_0) 1) ?mul1r
        ?row'_col_mx3 //; last first.
  apply/matrixP => i j; rewrite !mxE !eqxx /tnth /=.
  by case: j => [[|[|[]]]] ? //=; Simp.ord; Simp.r.
rewrite [\det Mu12](@determinant_multilinear _ _ _
  (M 1) (M 2%:R) 0 (u``_1) (u``_2%:R)) ?row'_col_mx3 //; last first.
  apply/matrixP => i j; rewrite !mxE !eqxx.
  by case: j => [[|[|[]]]] ? //=; Simp.ord; Simp.r.
by rewrite dotmulE !big_ord_recl big_ord0 addr0 /= !mxE; Simp.ord.
Qed.

(* u /\ (v + w) = u /\ v + u /\ w *)
Lemma crossmul_linear u : linear (crossmul u).
Proof.
move=> a v w; apply/rowP => k; rewrite !mxE.
pose M w := col_mx3 ('e_k) u w.
rewrite (@determinant_multilinear _ _ (M _) (M v) (M w) 2%:R a 1);
  rewrite ?row'_col_mx3 ?mul1r ?scale1r ?mxE //=.
by apply/rowP => j; rewrite !mxE.
Qed.

Canonical crossmul_is_additive u := Additive (crossmul_linear u).
Canonical crossmul_is_linear u := AddLinear (crossmul_linear u).

Definition crossmulr u := crossmul^~ u.

Lemma crossmulr_linear u : linear (crossmulr u).
Proof.
move=> a v w; rewrite /crossmulr crossmulC linearD linearZ /=.
by rewrite opprD -scalerN -!crossmulC.
Qed.

Canonical crossmulr_is_additive u := Additive (crossmulr_linear u).
Canonical crossmulr_is_linear u := AddLinear (crossmulr_linear u).

Lemma crossmulE u v : (u *v v) = row3
  (u``_1 * v``_2%:R - u``_2%:R * v``_1)
  (u``_2%:R * v``_0 - u``_0 * v``_2%:R)
  (u``_0 * v``_1 - u``_1 * v``_0).
Proof.
apply/rowP => i; rewrite !mxE (expand_det_row _ ord0).
rewrite !(mxE, big_ord_recl, big_ord0) !(mul0r, mul1r, addr0).
rewrite /cofactor !det_mx22 !mxE /= mul1r mulN1r opprB -signr_odd mul1r.
by Simp.ord; case: i => [[|[|[]]]] //= ?; rewrite ?(mul1r,mul0r,add0r,addr0).
Qed.

Lemma nth_crossmul u v i :
  (u *v v)``_i = u``_(i + 1) * v``_(i + 2%:R) - u``_(i + 2%:R) * v``_(i + 1).
Proof. by case: i => [[|[|[|?]]] ?]; rewrite crossmulE !mxE; Simp.ord. Qed.

Lemma crossmulNv u v : - u *v v = - (u *v v).
Proof. by rewrite crossmulC linearN /= opprK crossmulC. Qed.

Lemma crossmulvN u v : u *v (- v) = - (u *v v).
Proof. by rewrite linearN. Qed.

Lemma crossmulZv u v k : ((k *: u) *v v) = k *: (u *v v).
Proof. by rewrite crossmulC linearZ /= crossmulC scalerN opprK. Qed.

Lemma crossmulvZ u v k : (u *v (k *: v)) = k *: (u *v v).
Proof. by rewrite linearZ. Qed.

Lemma crossmulDl u v w : (u + v) *v w = u *v w + v *v w.
Proof.
rewrite crossmulC linearD /= opprD; congr (_ + _); by rewrite crossmulC opprK.
Qed.

Lemma crossmulDr u v w : w *v (u + v) = w *v u + w *v v.
Proof.
by rewrite crossmulC crossmulDl opprD crossmulC opprK (crossmulC v) opprK.
Qed.

Lemma crossmulBl u v w : (u - v) *v w = u *v w - v *v w.
Proof.
rewrite crossmulC linearD /= opprD; congr (_ + _);
  by rewrite ?crossmulvN crossmulC ?opprK.
Qed.

Lemma crossmul0E u v :
  (u *v v == 0) =
  [forall i, [forall j, (i != j) ==> (u``_j * v``_i == u``_i * v``_j)]].
Proof.
apply/eqP/'forall_'forall_implyP; last first.
  move=> uv_eq_vu; apply/rowP=> k; rewrite nth_crossmul mxE.
  rewrite (eqP (uv_eq_vu _ _ _)) ?subrr //.
  by case: k => [[|[|[|?]]] ?] //=.
move=> uv_eq0 i j neq_ij; have := nth_crossmul u v (-(i + j)).
rewrite uv_eq0 !mxE => /(canLR (@addrNK _ _)); rewrite add0r.
move: i j neq_ij; do 2![move=> [[|[|[|?]]] ?] //=; Simp.ord => //=];
by do ?[move=> _ -> //].
Qed.

Lemma mulmxl_crossmulr M u v : M *m (u *v v) = u *v (M *m v).
Proof. by rewrite -(mul_rV_lin1 [linear of crossmul u]) mulmxA mul_rV_lin1. Qed.

Lemma mulmxl_crossmull M u v : M *m (u *v v) = ((M *m u) *v v).
Proof. by rewrite crossmulC mulmxN mulmxl_crossmulr -crossmulC. Qed.

Lemma dotmul_crossmul_shift u v w : u *d (v *v w) = w *d (u *v v).
Proof.
rewrite crossmul_triple.
rewrite -col_mx3_perm_12 xrowE det_mulmx det_perm /= odd_tperm /=.
rewrite -col_mx3_perm_01 xrowE det_mulmx det_perm /= odd_tperm /=.
by rewrite expr1 mulrA mulrNN 2!mul1r -crossmul_triple.
Qed.

Lemma dot_crossmulC u v x : u *d (v *v x) = (u *v v) *d x.
Proof. by rewrite dotmul_crossmul_shift dotmulC. Qed.

Lemma dot_crossmulCA u v w : u *d (v *v w) = - v *d (u *v w).
Proof. do 2 rewrite dot_crossmulC; by rewrite crossmulNv crossmulC. Qed.

Lemma det_crossmul_dotmul M u v x :
  (\det M *: (u *v v)) *d x = (((u *m M) *v (v *m M)) *m M^T) *d x.
Proof.
transitivity (\det M * \det (col_mx3 u v x)).
  by rewrite dotmulZv -dot_crossmulC crossmul_triple.
transitivity (\det (col_mx3 (u *m M) (v *m M) (x *m M))).
  by rewrite mulrC -det_mulmx mulmx_col3.
by rewrite -crossmul_triple dot_crossmulC dotmul_trmx.
Qed.

Lemma mulmx_crossmul' M u v : \det M *: (u *v v) = ((u *m M) *v (v *m M)) *m M^T.
Proof. by apply/rowP=> i; rewrite -!dotmul_delta_mx det_crossmul_dotmul. Qed.

Lemma double_crossmul u v w :
  u *v (v *v w) = (u *d w) *: v - (u *d v) *: w.
Proof.
suff aux i : u *d w * v``_i - u *d v * w``_i =
   u``_(i + 1) * (v``_i * w``_(i + 1) - v``_(i + 1) * w``_i) -
   u``_(i + 2%:R) * (v``_(i + 2%:R) * w``_i - v``_i * w``_(i + 2%:R)).
  apply/rowP=> -[[|[|[|?]]] ? //=];
  by rewrite !crossmulE !mxE /= aux; Simp.ord.
have neq_iSi: i + 1 != i by case: i => [[|[|[|?]]] ? //=].
have neq_iSSi:  (i + 2%:R != i) && (i + 2%:R != i + 1).
   by case: i neq_iSi => [[|[|[|?]]] ? //=].
do ![rewrite dotmulE (bigD1 i) // (bigD1 (i + 1)) // (bigD1 (i + 2%:R)) //=;
     rewrite big1 ?mul0r ?addr0 ?mulrDl ?opprD;
   last by move: i {neq_iSi neq_iSSi}; do 2![move => [[|[|[|?]]] ? //=]]].
rewrite addrACA mulrAC subrr add0r addrACA -!mulrA -!mulrBr ![w``__ * _]mulrC.
by congr (_ + _); rewrite -[RHS]mulrN opprB.
Qed.

Lemma dotmul_crossmul2 u v w : (u *v v) *v (u *v w) = (u *d (v *v w)) *: u.
Proof.
rewrite double_crossmul dot_crossmulC (dotmulC _ u) dot_crossmulC crossmulvv.
by rewrite dotmul0v scale0r subr0.
Qed.

(* TODO: move *)
Definition jacobi (T : zmodType) (op : T -> T -> T) := forall x y z,
  op x (op y z) + op y (op z x) + op z (op x y) = 0.

Lemma jacobi_crossmul : jacobi crossmul.
Proof.
move=> u v w.
rewrite 3!double_crossmul.
rewrite !addrA -(addrA (_ *: v)) (dotmulC u v) -(addrC (_ *: w)) subrr addr0.
rewrite -!addrA addrC -!addrA (dotmulC w u) -(addrC (_ *: v)) subrr addr0.
by rewrite addrC dotmulC subrr.
Qed.

Lemma crossmul0_dotmul (u v : 'rV[T]_3) : u *v v == 0 -> (u *d v) ^+ 2 = u *d u * (v *d v).
Proof.
rewrite crossmul0E => uv0.
rewrite !dotmulE expr2 !big_distrl /=.
apply eq_bigr => i _; rewrite -!mulrA; congr (_ * _).
rewrite 2!big_distrr /=.
apply eq_bigr => j /= _; rewrite mulrCA !mulrA; congr (_ * _).
case/boolP : (i == j) => [/eqP ->|ij]; first by rewrite mulrC.
move/forallP : uv0 => /(_ i)/forallP/(_ j).
by rewrite ij implyTb => /eqP.
Qed.

End crossmul.

Notation "*v%R" := (@crossmul _) : ring_scope.
Notation "u *v w" := (crossmul u w) : ring_scope.

Section comUnit_crossmul.

Variable (T : comUnitRingType).

Implicit Types u v : 'rV[T]_3.

Lemma vece2 (i j : 'I_3) (k := - (i + j) : 'I_3) :
  'e_i *v 'e_j = (-1)^(perm3 i j)%N *+ (i != j) *: 'e_k :> 'rV[T]__.
Proof.
have [->|neq_ij] := altP (i =P j); rewrite (mulr0n,mulr1n).
  by rewrite scale0r crossmulvv.
apply/rowP => k'; case: (I3P k' neq_ij); rewrite !mxE.
- rewrite (@determinant_alternate _ _ _ 0 1) //=.
    by move: i j @k neq_ij => [[|[|[|?]]] ?] [[|[|[|?]]] ?] //=; rewrite mulr0.
  by move=> k''; rewrite !mxE.
- rewrite (@determinant_alternate _ _ _ 0 2%:R) //=.
    by move: i j @k neq_ij => [[|[|[|?]]] ?] [[|[|[|?]]] ?] //=; rewrite mulr0.
  by move=> k''; rewrite !mxE.
rewrite !eqxx mulr1 -[_ ^ _](@det_perm T) {k k'}; congr (\det _).
apply/matrixP => a b; rewrite !mxE permE ffunE /=.
by move: a b i j neq_ij; do 4![move=> [[|[|[|?]]] ?]; rewrite ?mxE //=].
Qed.

Lemma mulmx_crossmul M u v : M \is a GRing.unit ->
  (u *v v) *m (\det M *: M^-1^T) = (u *m M) *v (v *m M).
Proof.
move=> invM.
move: (mulmx_crossmul' M u v) => /(congr1 (fun x => x *m M^T^-1)).
rewrite -mulmxA mulmxV ?unitmx_tr // mulmx1 => <-.
by rewrite -scalemxAr trmx_inv scalemxAl.
Qed.

End comUnit_crossmul.

Section field_crossmul.

Variable (T : fieldType).

Implicit Types u v w : 'rV[T]_3.

Lemma crossmul_normal u v : u _|_ (u *v v).
Proof.
rewrite normalvv crossmul_triple.
rewrite (determinant_alternate (oner_neq0 _)) => [|i] //.
by rewrite !mxE.
Qed.

Lemma common_normal_crossmul u v : (u *v v) _|_ u + v.
Proof.
rewrite normalmD ![(_ *v _) _|_ _]normal_sym crossmul_normal.
by rewrite crossmulC normalmN crossmul_normal.
Qed.

End field_crossmul.

(* TODO: make better use of the bilinear theory? *)
Section crossmul_bilinear.

Variables (R : comRingType).

Definition crossmul_rev (v u : 'rV[R]_3) := u *v v.
Canonical rev_crossmul := @RevOp _ _ _ crossmul_rev (@crossmul R)
  (fun _ _ => erefl).

(*Lemma crossmul_is_linear u : GRing.linear (crossmul u : 'rV[R]_3 -> 'rV[R]_3).
Proof. move=> /= k v w; by rewrite crossmulDr crossmulvZ. Qed.
Canonical crossmul_linear x := Linear (crossmul_is_linear x).*)

Lemma crossmul_rev_is_linear v : GRing.linear (crossmul_rev v : 'rV[R]_3 -> 'rV[R]_3).
Proof. move=> /= k u w; by rewrite /crossmul_rev crossmulDl crossmulZv. Qed.
Canonical crossmul_rev_linear v := Linear (crossmul_rev_is_linear v).

Canonical crossmul_bilinear := [bilinear of (@crossmul R)].

End crossmul_bilinear.

Section orthogonal_rotation_def.

Variables (n : nat) (T : ringType).

Definition orthogonal := [qualify M : 'M[T]_n | M *m M^T == 1%:M].
Fact orthogonal_key : pred_key orthogonal. Proof. by []. Qed.
Canonical orthogonal_keyed := KeyedQualifier orthogonal_key.

Definition rotation := [qualify M : 'M[T]_n | (M \is orthogonal) && (\det M == 1)].
Fact rotation_key : pred_key rotation. Proof. by []. Qed.
Canonical rotation_keyed := KeyedQualifier rotation_key.

End orthogonal_rotation_def.

Notation "''O[' T ]_ n" := (orthogonal n T) : ring_scope.

Notation "''SO[' T ]_ n" := (rotation n T) : ring_scope.

Section orthogonal_rotation_properties0.

Variables (n' : nat) (T : ringType).
Let n := n'.+1.

Lemma orthogonalE M : (M \is 'O[T]_n) = (M * M^T == 1). Proof. by []. Qed.

Lemma orthogonal1 : 1 \is 'O[T]_n.
Proof. by rewrite orthogonalE trmx1 mulr1. Qed.

Lemma orthogonal_mul_tr M : (M \is 'O[T]_n) -> M *m M^T = 1.
Proof. by move/eqP. Qed.

Lemma orthogonal_oppr_closed : oppr_closed 'O[T]_n.
Proof. by move=> x; rewrite !orthogonalE linearN /= mulNr mulrN opprK. Qed.
Canonical orthogonal_is_oppr_closed := OpprPred orthogonal_oppr_closed.

Lemma rotation_sub : {subset 'SO[T]_n <= 'O[T]_n}.
Proof. by move=> M /andP []. Qed.

Lemma orthogonalP M :
  reflect (forall i j, row i M *d row j M = (i == j)%:R) (M \is 'O[T]_n).
Proof.
apply: (iffP idP) => [|H] /=.
  rewrite orthogonalE => /eqP /matrixP H i j.
  move/(_ i j) : H; rewrite /dotmul !mxE => <-.
  apply eq_bigr => k _; by rewrite !mxE.
rewrite orthogonalE.
apply/eqP/matrixP => i j; rewrite !mxE -H /dotmul !mxE.
apply eq_bigr => k _; by rewrite !mxE.
Qed.

Lemma OSn_On m (P : 'M[T]_n) :
  (block_mx (1%:M : 'M_m) 0 0 P \is 'O[T]_(m + n)) = (P \is 'O[T]_n).
Proof.
rewrite !qualifE tr_block_mx trmx1 !trmx0 mulmx_block.
rewrite !(mulmx0, mul0mx, mulmx1, mul1mx, addr0, add0r) scalar_mx_block.
by apply/eqP/eqP => [/eq_block_mx[] |->//].
Qed.

End orthogonal_rotation_properties0.

Lemma SOSn_SOn (T : comRingType) n m (P : 'M[T]_n.+1) :
  (block_mx (1%:M : 'M_m) 0 0 P \is 'SO[T]_(m + n.+1)) = (P \is 'SO[T]_n.+1).
Proof. by rewrite qualifE OSn_On det_lblock det1 mul1r. Qed.

Section orthogonal_rotation_properties.

Variables (n' : nat) (T : comUnitRingType).
Let n := n'.+1.

Lemma orthogonalEinv M : (M \is 'O[T]_n) = (M \is a GRing.unit) && (M^-1 == M^T).
Proof.
rewrite orthogonalE; have [Mu | notMu] /= := boolP (M \in unitmx); last first.
  by apply: contraNF notMu => /eqP /mulmx1_unit [].
by rewrite -(inj_eq (@mulrI _ M^-1 _)) ?unitrV // mulr1 mulKr.
Qed.

Lemma orthogonal_unit M : (M \is 'O[T]_n) -> (M \is a GRing.unit).
Proof. by rewrite orthogonalEinv => /andP []. Qed.

Lemma orthogonalV M : (M^T \is 'O[T]_n) = (M \is 'O[T]_n).
Proof.
by rewrite !orthogonalEinv unitmx_tr -trmxV (inj_eq (@trmx_inj _ _ _)).
Qed.

Lemma orthogonal_inv M : M \is 'O[T]_n -> M^-1 = M^T.
Proof. by rewrite orthogonalEinv => /andP [_ /eqP]. Qed.

Lemma orthogonalEC M : (M \is 'O[T]_n) = (M^T * M == 1).
Proof. by rewrite -orthogonalV orthogonalE trmxK. Qed.

Lemma orthogonal_tr_mul M : (M \is 'O[T]_n) -> M^T *m M = 1.
Proof. by rewrite orthogonalEC => /eqP. Qed.

Lemma orthogonal_divr_closed : divr_closed 'O[T]_n.
Proof.
split => [| P Q HP HQ]; first exact: orthogonal1.
rewrite orthogonalE orthogonal_inv // trmx_mul trmxK -mulrA.
by rewrite -orthogonal_inv // mulKr // orthogonal_unit.
Qed.
Canonical orthogonal_is_mulr_closed := MulrPred orthogonal_divr_closed.
Canonical orthogonal_is_divr_closed := DivrPred orthogonal_divr_closed.
Canonical orthogonal_is_smulr_closed := SmulrPred orthogonal_divr_closed.
Canonical orthogonal_is_sdivr_closed := SdivrPred orthogonal_divr_closed.

Lemma rotationE M : (M \is 'SO[T]_n) = (M \is 'O[T]_n) && (\det M == 1). Proof. by []. Qed.

Lemma rotationV M : (M^T \is 'SO[T]_n) = (M \is 'SO[T]_n).
Proof. by rewrite rotationE orthogonalV det_tr -rotationE. Qed.

Lemma rotation_inv M : M \is 'SO[T]_n -> M^-1 = M^T.
Proof. by rewrite rotationE orthogonalEinv => /andP[/andP[_ /eqP]]. Qed.

Lemma rotation_det M : M \is 'SO[T]_n -> \det M = 1.
Proof. by move=> /andP[_ /eqP]. Qed.

Lemma rotation1 : 1 \is 'SO[T]_n.
Proof. apply/andP; by rewrite orthogonal1 det1. Qed.

Lemma rotation_tr_mul M : (M \is 'SO[T]_n) -> M^T *m M = 1.
Proof. by move=> /rotation_sub /orthogonal_tr_mul. Qed.

Lemma rotation_divr_closed : divr_closed 'SO[T]_n.
Proof.
split => [|P Q Prot Qrot]; first exact: rotation1.
rewrite rotationE rpred_div ?rotation_sub //=.
by rewrite det_mulmx det_inv !rotation_det // divr1.
Qed.

Canonical rotation_is_mulr_closed := MulrPred rotation_divr_closed.
Canonical rotation_is_divr_closed := DivrPred rotation_divr_closed.

Lemma orthogonalPcol M :
  reflect (forall i j, (col i M)^T *d (col j M)^T = (i == j)%:R) (M \is 'O[T]_n).
Proof.
apply: (iffP idP) => [MSO i j|H] /=.
- move: (MSO); rewrite -rpredV orthogonal_inv // => /orthogonalP <-.
  by rewrite 2!tr_col.
- suff MSO : M^T \is 'O[T]_n.
    move/orthogonal_inv: (MSO); rewrite trmxK => <-; by rewrite rpredV.
  apply/orthogonalP => i j; by rewrite -H 2!tr_col.
Qed.

End orthogonal_rotation_properties.

Section orthogonal_rotation_properties1.

Variables (n' : nat) (T : realDomainType).
Let n := n'.+1.

Lemma orthogonal_det M : M \is 'O[T]_n -> `|\det M| = 1.
Proof.
move=> /eqP /(congr1 determinant); rewrite detM det_tr det1 => /eqP.
by rewrite sqr_norm_eq1 => /eqP.
Qed.

End orthogonal_rotation_properties1.

Lemma orthogonal2P (T : ringType) M : reflect (M \is 'O[T]_2)
    [&& row 0 M *d row 0 M == 1, row 0 M *d row 1 M == 0,
        row 1 M *d row 0 M == 0 & row 1 M *d row 1 M == 1].
Proof.
apply (iffP idP) => [/and4P[] /eqP H1 /eqP H2 /eqP H3 /eqP H4|]; last first.
  move/orthogonalP => H; by rewrite !H /= !eqxx.
apply/orthogonalP => i j.
case/boolP : (i == 0) => [|/ifnot01P]/eqP->;
  by case/boolP : (j == 0) => [|/ifnot01P]/eqP->.
Qed.

(* TODO: move? use *d? *)
Lemma dotmul_conjc_eq0 {T : rcfType} n (v : 'rV[T[i]]_n.+1) :
  (v *m map_mx conjc v^T == 0) = (v == 0).
Proof.
apply/idP/idP => [H|/eqP ->]; last by rewrite mul0mx.
have : \sum_(i < n.+1) v``_i * (v``_i)^* = 0.
  move/eqP/matrixP : H =>/(_ 0 0).
  rewrite !mxE => H; rewrite -{2}H.
  apply/eq_bigr => /= i _; by rewrite !mxE.
move/eqP; rewrite psumr_eq0 /= => [/allP K|]; last first.
  move=> i _; by rewrite -sqr_normc exprn_ge0.
apply/eqP/rowP => i.
move: (K i); rewrite /index_enum -enumT mem_enum inE => /(_ isT).
rewrite -sqr_normc sqrf_eq0 normr_eq0 => /eqP ->; by rewrite mxE.
Qed.

(* eigenvalues of orthogonal matrices have norm 1 *)

Lemma eigenvalue_O (T : rcfType) n M : M \is 'O[T]_n.+1 -> forall k,
   k \in eigenvalue (map_mx (fun x => x%:C%C) M) -> `| k | = 1.
Proof.
move=> MSO /= k.
case/eigenvalueP => v kv v0.
move/(congr1 trmx)/(congr1 (fun x => map_mx conjc x)) : (kv).
rewrite trmx_mul map_mxM linearZ /= map_mxZ map_trmx.
move/(congr1 (fun x => (k *: v) *m x)).
rewrite -{1}kv -mulmxA (mulmxA (map_mx _ M)) (_ : map_mx _ M *m _ = 1%:M); last first.
  rewrite (_ : map_mx conjc _ = map_mx (fun x => x%:C%C) M^T); last first.
    apply/matrixP => i j; by rewrite !mxE conjc_real.
  rewrite orthogonalE in MSO.
  by rewrite -map_mxM mulmxE (eqP MSO) map_mx1.
rewrite mul1mx -scalemxAr /= -scalemxAl scalerA => /eqP.
rewrite -subr_eq0 -{1}(scale1r (v *m _)) -scalerBl scaler_eq0 => /orP [].
  by rewrite subr_eq0 mulrC -sqr_normc -{1}(expr1n _ 2) eqr_expn2 // ?ler01 // => /eqP.
by rewrite dotmul_conjc_eq0 (negbTE v0).
Qed.

Lemma norm_row_of_O (T : rcfType) n M : M \is 'O[T]_n.+1 -> forall i, norm (row i M) = 1.
Proof.
move=> MSO i.
apply/eqP; rewrite -(@eqr_expn2 _ 2) // ?norm_ge0 // expr1n; apply/eqP.
rewrite -dotmulvv; move/orthogonalP : MSO => /(_ i i) ->; by rewrite eqxx.
Qed.

Lemma dot_row_of_O (T : ringType) n M : M \is 'O[T]_n.+1 -> forall i j,
  row i M *d row j M = (i == j)%:R.
Proof. by move/orthogonalP. Qed.

Lemma norm_col_of_O (T : rcfType) n M : M \is 'O[T]_n.+1 -> forall i, norm (col i M)^T = 1.
Proof.
move=> MSO i.
apply/eqP.
rewrite -(@eqr_expn2 _ 2) // ?norm_ge0 // expr1n -dotmulvv tr_col dotmulvv.
by rewrite norm_row_of_O ?expr1n // orthogonalV.
Qed.

Lemma orth_preserves_sqr_norm (T : comRingType) n M : M \is 'O[T]_n.+1 ->
  {mono (fun u => u *m M) : x / x *d x}.
Proof.
move=> HM u; rewrite dotmul_trmx -mulmxA (_ : M *m _ = 1%:M) ?mulmx1 //.
by move: HM; rewrite orthogonalE => /eqP.
Qed.

Lemma orth_preserves_dotmul {T : numDomainType} n (f : 'M[T]_n.+1) :
  {mono (fun u => u *m f) : x y / x *d y} <-> f \is 'O[T]_n.+1.
Proof.
split => H.
  apply/orthogonalP => i j.
  by rewrite 2!rowE H dotmul_delta_mx mxE eqxx /= eq_sym.
move=> u v.
have := orth_preserves_sqr_norm H (u + v).
rewrite mulmxDl dotmulD.
rewrite dotmulD.
rewrite orth_preserves_sqr_norm // (orth_preserves_sqr_norm H v) //.
move/(congr1 (fun x => x - v *d v)).
rewrite -!addrA subrr 2!addr0.
move/(congr1 (fun x => - (u *d u) + x)).
rewrite !addrA (addrC (- (u *d u))) subrr 2!add0r.
rewrite -2!mulr2n => /eqP.
by rewrite eqr_pmuln2r // => /eqP.
Qed.

Lemma orth_preserves_norm (T : rcfType) n M : M \is 'O[T]_n.+1 ->
  {mono (fun u => u *m M) : x / norm x }.
Proof. move=> HM v; by rewrite /norm (proj2 (orth_preserves_dotmul M) HM). Qed.

Lemma Oij_ub (T : rcfType) n (M : 'M[T]_n.+1) : M \is 'O[T]_n.+1 -> forall i j, `| M i j | <= 1.
Proof.
move=> /norm_row_of_O MO i j; rewrite lerNgt; apply/negP => abs.
move: (MO i) => /(congr1 (fun x => x ^+ 2)); apply/eqP.
rewrite gtr_eqF // sqr_norm (bigD1 j) //= !mxE -(addr0 (1 ^+ 2)) ltr_le_add //.
by rewrite -(sqr_normr (M _ _)) ltr_expn2r.
rewrite sumr_ge0 // => k ij; by rewrite sqr_ge0.
Qed.

Lemma O_tr_idmx (T : rcfType) n (M : 'M[T]_n.+1) : M \is 'O[T]_n.+1 -> \tr M = n.+1%:R -> M = 1.
Proof.
move=> MO; move: (MO) => /norm_row_of_O MO' tr3.
have Mdiag : forall i, M i i = 1.
  move=> i; apply/eqP/negPn/negP => Mii; move: tr3; apply/eqP.
  rewrite ltr_eqF // /mxtrace.
  rewrite (bigD1 i) //=.
  rewrite (eq_bigr (fun i : 'I_n.+1 => M (inord i) (inord i))); last first.
    by move=> j _; congr (M _ _); apply val_inj => /=; rewrite inordK.
  rewrite -(big_mkord [pred x : nat | x != i] (fun i => M (inord i) (inord i))).
  rewrite -[in n.+1%:R](card_ord n.+1) -sum1_card (bigD1 i) //= natrD.
  rewrite ltr_le_add //; first by rewrite ltr_neqAle Mii /= ler_norml1 // Oij_ub.
  rewrite [in X in _ <= X](@big_morph _ _ _ 0 (fun x y => x + y)%R) //; last first.
    by move=> x y; rewrite natrD.
  rewrite -(big_mkord [pred x : nat | x != i] (fun i => 1)).
  apply ler_sum => j ji; by rewrite ler_norml1 // Oij_ub.
apply/matrixP => i j; rewrite !mxE.
case/boolP : (i == j) => [/eqP ->|ij]; first by move : Mdiag => /(_ j).
move: (MO' i) => /(congr1 (fun x => x ^+ 2)).
rewrite expr1n sqr_norm (bigD1 i) //= mxE.
move: Mdiag => /(_ i) -> /eqP.
rewrite expr1n addrC eq_sym -subr_eq subrr eq_sym psumr_eq0 /=; last first.
  by move=> *; rewrite sqr_ge0.
by move/allP => /(_ j (mem_index_enum _)); rewrite eq_sym ij implyTb mxE sqrf_eq0 => /eqP.
Qed.

Section orthogonal_crossmul.

(* "From the geometrical definition, the cross product is invariant under
   proper rotations about the axis defined by a × b"
   https://en.wikipedia.org/wiki/Cross_product *)
Lemma mulmxr_crossmulr (T : realDomainType) r u v : r \is 'O[T]_3 ->
  (u *v v) *m r = \det r *: ((u *m r) *v (v *m r)).
Proof.
move=> rO; move: (rO).
rewrite orthogonalEinv => /andP[r1 /eqP rT].
rewrite -mulmx_crossmul //.
move/eqP: (orthogonal_det rO).
rewrite eqr_norml // => /andP[ /orP[/eqP-> |/eqP->] _];
  rewrite ?scale1r rT trmxK //.
by rewrite -scalemxAr scalerA mulrNN !mul1r scale1r.
Qed.

Lemma eigenspace_trmx (T : fieldType) r (Hr : r \is 'O[T]_3) (n : 'rV[T]_3) :
  (n <= eigenspace r 1 <-> n <= eigenspace r^T 1)%MS.
Proof.
move: (Hr); rewrite orthogonalE => /eqP Hr1.
move: Hr; rewrite orthogonalEC => /eqP Hr2.
split.
  move/eigenspaceP; rewrite scale1r => nrn.
  apply/eigenspaceP; rewrite scale1r.
  by rewrite -{1}nrn -mulmxA mulmxE Hr1 mulmx1.
move/eigenspaceP; rewrite scale1r => nrn.
apply/eigenspaceP; rewrite scale1r.
by rewrite -{1}nrn -mulmxA mulmxE Hr2 mulmx1.
Qed.

Lemma mulmxr_crossmulr_SO (T : realDomainType) r u v : r \is 'SO[T]_3 ->
  (u *v v) *m r = (u *m r) *v (v *m r).
Proof.
rewrite rotationE => /andP[rO /eqP detr1].
by rewrite mulmxr_crossmulr // detr1 scale1r.
Qed.

Lemma det_rotN1 (T : numDomainType) (M : 'M[T]_3) :
  M \is 'SO[T]_3 -> \det (M - 1) = 0.
Proof.
move=> MSO; apply/eqP; rewrite -[_ == 0](mulrn_eq0 _ 2) addr_eq0.
have {1}-> : M - 1 = - (M *m (M - 1)^T).
  rewrite raddfD /= raddfN /= trmx1 mulmxDr mulmxN mulmx1.
  by rewrite orthogonal_mul_tr ?rotation_sub // opprB.
rewrite -scaleN1r detZ -signr_odd detM det_tr.
by rewrite [\det M]rotation_det // mulN1r mul1r.
Qed.

Lemma rot_eigen1 (T : numFieldType) (M : 'M[T]_3) :
  M \is 'SO[T]_3 -> eigenspace M 1 != 0.
Proof.
by move=> MS0; rewrite kermx_eq0 row_free_unit unitmxE det_rotN1 ?unitr0.
Qed.

Lemma euler (T : numFieldType) (M : 'M[T]_3) : M \is 'SO[T]_3 ->
  {x : 'rV[T]_3 | (x != 0) && (x *m M == x)}.
Proof.
move=> MSO; apply: sigW; have /rot_eigen1 /rowV0Pn [v v_eigen v_neq0] := MSO.
by exists v; rewrite v_neq0 (eigenspaceP v_eigen) scale1r eqxx.
Qed.

Definition vaxis_euler (T : numFieldType) M :=
  match eqVneq (M \is 'SO[T]_3) true with
  | left MSO => sval (euler MSO)
  | right _ => 0
  end.

Lemma vaxis_euler_neq0 (T : numFieldType) M :
  M \is 'SO[T]_3 -> vaxis_euler M != 0.
Proof.
move=> MSO; rewrite /vaxis_euler; case: eqVneq; last by rewrite MSO.
move=> {MSO}MSO; by case: euler => v /= /andP[].
Qed.

Lemma vaxis_eulerP (T : numFieldType) M :
  M \is 'SO[T]_3 -> vaxis_euler M *m M = vaxis_euler M.
Proof.
move=> MSO; rewrite /vaxis_euler; case: eqVneq; last by rewrite MSO.
move=> {MSO}MSO; by case: euler => v /= /andP[_ /eqP].
Qed.

End orthogonal_crossmul.

Section norm3.

Variable T : rcfType.
Implicit Types u : 'rV[T]_3.

Lemma norm_crossmul' u v :
  (norm (u *v v)) ^+ 2 = (norm u * norm v) ^+ 2 - (u *d v) ^+ 2.
Proof.
rewrite sqr_norm sum3E crossmulE /SimplFunDelta /= !mxE /=.
transitivity (((u``_0)^+2 + (u``_1)^+2 + (u``_2%:R)^+2)
  * ((v``_0)^+2 + (v``_1)^+2 + (v``_2%:R)^+2)
  - (u``_0 * v``_0 + u``_1 * v``_1 + u``_2%:R * v``_2%:R)^+2).
  set u0 := u``_0. set v0 := v``_0.
  set u1 := u``_1. set v1 := v``_1.
  set u2 := u``_2%:R. set v2 := v``_2%:R.
  rewrite !sqrrB !mulrDr !mulrDl !sqrrD.
  set A := u1 * v2. set A' := u2 * v1.
  set B := u2 * v0. set B' := u0 * v2.
  set C := u0 * v1. set C' := u1 * v0.
  set U0 := u0 ^+ 2. set U1 := u1 ^+ 2. set U2 := u2 ^+ 2.
  set V0 := v0 ^+ 2. set V1 := v1 ^+ 2. set V2 := v2 ^+ 2.
  rewrite (_ : u0 * v0 * (u1 * v1) = C * C'); last first.
    rewrite /C /C' -2!mulrA; congr (_ * _).
    rewrite mulrA mulrC; congr (_ * _); by rewrite mulrC.
  rewrite mulrDl.
  rewrite (_ : u0 * v0 * (u2 * v2) = B * B'); last first.
    rewrite /B /B' [in RHS]mulrC -!mulrA; congr (_ * _).
    rewrite mulrA -(mulrC v2); congr (_ * _); by rewrite mulrC.
  rewrite (_ : u1 * v1 * (u2 * v2) = A * A'); last first.
    rewrite /A /A' -!mulrA; congr (_ * _).
    rewrite mulrA -(mulrC v2); congr (_ * _); by rewrite mulrC.
  rewrite (_ : (u0 * v0) ^+ 2 = U0 * V0); last by rewrite exprMn.
  rewrite (_ : (u1 * v1) ^+ 2 = U1 * V1); last by rewrite exprMn.
  rewrite (_ : (u2 * v2) ^+ 2 = U2 * V2); last by rewrite exprMn.
  rewrite 4![in RHS]opprD.
  (* U0 * V0 *)
  rewrite -3!(addrA (U0 * V0)) -3![in X in _ = _ + X](addrA (- (U0 * V0))).
  rewrite [in RHS](addrAC (U0 * V0)) [in RHS](addrA (U0 * V0)) subrr add0r.
  (* U1 * V1 *)
  rewrite -(addrC (- (U1 * V1))) -(addrC (U1 * V1)) (addrCA (U1 * V0 + _)).
  rewrite -3!(addrA (- (U1 * V1))) -![in X in _ = _ + X](addrA (U1 * V1)) addrCA.
  rewrite [in RHS](addrA (- (U1 * V1))) [in RHS](addrC (- (U1 * V1))) subrr add0r.
  (* U2 * V2 *)
  rewrite -(addrC (- (U2 * V2))) -(addrC (U2 * V2)) -(addrC (U2 * V2 + _)).
  rewrite [in RHS]addrAC 2!(addrA (- (U2 * V2))) -(addrC (U2 * V2)) subrr add0r.
  (* C * C' ^+ 2 *)
  rewrite (addrC (C ^+ 2 - _)) ![in LHS]addrA.
  rewrite (addrC (C * C' *- 2)) ![in RHS]addrA; congr (_ - _).
  rewrite (_ : U0 * V2 = B' ^+ 2); last by rewrite exprMn.
  rewrite (_ : U1 * V2 = A ^+ 2); last by rewrite exprMn.
  rewrite (_ : U0 * V1 = C ^+ 2); last by rewrite exprMn.
  rewrite (_ : U1 * V0 = C' ^+ 2); last by rewrite exprMn.
  rewrite (_ : U2 * V0 = B ^+ 2); last by rewrite exprMn.
  rewrite (_ : U2 * V1 = A' ^+ 2); last by rewrite exprMn.
  (* B' ^+ 2, A ^+ 2 *)
  rewrite -(addrC (B' ^+ 2)) -!addrA; congr (_ + (_ + _)).
  rewrite !addrA.
  (* B ^+ 2 *)
  rewrite -2!(addrC (B ^+ 2)) -!addrA; congr (_ + _).
  rewrite !addrA.
  (* C ^+ 2 *)
  rewrite -(addrC (C ^+ 2)) -!addrA; congr (_ + _).
  rewrite !addrA.
  (* C' ^+ 2 *)
  rewrite -(addrC (C' ^+ 2)) -!addrA; congr (_ + _).
  rewrite !addrA.
  (* A' ^+ 2 *)
  rewrite -(addrC (A' ^+ 2)) -!addrA; congr (_ + _).
  rewrite -!mulNrn !mulr2n !opprD.
  rewrite addrC -!addrA; congr (_ + _).
  rewrite addrA.
  rewrite addrC -!addrA; congr (_ + _).
  by rewrite addrC.
rewrite exprMn -(sum3E (fun i => u``_i ^+ 2)) -(sum3E (fun i => v``_i ^+ 2)) -2!sqr_norm; congr (_ - _ ^+ 2).
by rewrite dotmulE sum3E.
Qed.

Lemma orth_preserves_norm_crossmul M : M \is 'O[T]_3 ->
  {mono (fun u => u *m M) : x y / norm (x *v y)}.
Proof.
move=> MO u v.
by rewrite -[in RHS](orth_preserves_norm MO) mulmxr_crossmulr // normZ orthogonal_det // mul1r.
Qed.

Lemma norm_crossmul_normal u v : u *d v = 0 ->
  norm u = 1 -> norm v = 1 -> norm (u *v v) = 1.
Proof.
move=> uv0 u1 v1; apply/eqP.
rewrite -(@eqr_expn2 _ 2) // ?norm_ge0 //.
by rewrite norm_crossmul' u1 v1 uv0 expr0n /= subr0 mulr1 // norm_ge0.
Qed.

Lemma dotmul_eq0_crossmul_neq0 (u v : 'rV[T]_3) : u != 0 -> v != 0 -> u *d v == 0 -> u *v v != 0.
Proof.
move=> u0 v0 uv0.
rewrite -norm_eq0 -(@eqr_expn2 _ 2) // ?norm_ge0 // exprnP expr0n -exprnP.
rewrite norm_crossmul' (eqP uv0) expr0n subr0 -expr0n eqr_expn2 //.
by rewrite mulf_eq0 negb_or 2!norm_eq0 u0.
by rewrite mulr_ge0 // ?norm_ge0.
Qed.

End norm3.

Section properties_of_canonical_vectors.

Lemma normeE (T : rcfType) i : norm ('e_i : 'rV_3) = 1 :> T.
Proof. by rewrite norm_delta_mx. Qed.

Variable T : comUnitRingType.

Lemma vecij : 'e_0 *v 'e_1 = 'e_2%:R :> 'rV[T]__.
Proof. by rewrite vece2 odd_perm3 /= scale1r. Qed.

Lemma vecjk : 'e_1 *v 'e_2%:R = 'e_0%:R :> 'rV[T]__.
Proof. by rewrite vece2 odd_perm3 /= scale1r. Qed.

Lemma vecki : 'e_2%:R *v 'e_0 = 'e_1 :> 'rV[T]__.
Proof. by rewrite vece2 odd_perm3 /= scale1r. Qed.

Lemma vecji : 'e_1 *v 'e_0 = - 'e_2%:R :> 'rV[T]__.
Proof. by rewrite vece2 odd_perm3 /= scaleN1r. Qed.

Lemma veckj : 'e_2%:R *v 'e_1 = - 'e_0 :> 'rV[T]__.
Proof. by rewrite vece2 odd_perm3 /= scaleN1r. Qed.

Lemma vecik : 'e_0 *v 'e_2%:R = - 'e_1 :> 'rV[T]__.
Proof. by rewrite vece2 odd_perm3 /= scaleN1r. Qed.

End properties_of_canonical_vectors.

Lemma orthogonal3P (T : rcfType) (M : 'M[T]_3) :
  reflect (M \is 'O[T]_3)
  [&& norm (row 0 M) == 1, norm (row 1 M) == 1, norm (row 2%:R M) == 1,
      row 0 M *d row 1 M == 0, row 0 M *d row 2%:R M == 0 & row 1 M *d row 2%:R M == 0].
Proof.
apply (iffP idP).
- case/and6P => /eqP ni /eqP nj /eqP nk /eqP xy0 /eqP xz0 /eqP yz0 /=.
  apply/orthogonalP => i j; case/boolP : (i == 0) => [|/ifnot0P/orP[]]/eqP->.
  + case/boolP : (j == 0) => [|/ifnot0P/orP[]]/eqP->; by
      [rewrite dotmulvv ni expr1n | rewrite xy0 | rewrite xz0].
  + case/boolP : (j == 0) => [|/ifnot0P/orP[]]/eqP->; by
      [rewrite dotmulC xy0 | rewrite dotmulvv nj expr1n | rewrite yz0].
  + case/boolP : (j == 0) => [|/ifnot0P/orP[]]/eqP->; by
      [rewrite dotmulC xz0 | rewrite dotmulC yz0 | rewrite dotmulvv nk expr1n].
- move/orthogonalP => H; apply/and6P; split; first [
    by rewrite -(@eqr_expn2 _ 2) // ?norm_ge0 // expr1n -dotmulvv H |
    by rewrite H ].
Qed.

Lemma rotation3P (T : rcfType) (M : 'M[T]_3) :
  reflect (M \is 'SO[T]_3)
  [&& norm (row 0 M) == 1, norm (row 1 M) == 1,
      row 0 M *d row 1 M == 0 & row 2%:R M == row 0 M *v row 1 M].
Proof.
apply (iffP idP).
- case/and4P => /eqP ni /eqP nj /eqP xy0 /eqP zxy0 /=.
  rewrite rotationE; apply/andP; split.
    apply/orthogonal3P.
    rewrite ni nj /= zxy0 norm_crossmul_normal // xy0 !eqxx /= dot_crossmulC.
    by rewrite crossmulvv dotmul0v dot_crossmulCA crossmulvv dotmulv0 !eqxx.
  rewrite (col_mx3_rowE M) -crossmul_triple zxy0 double_crossmul dotmulvv nj expr1n.
  by rewrite scale1r (dotmulC (row 1 M)) xy0 scale0r subr0 dotmulvv ni expr1n.
- move=> MSO; move: (MSO).
  rewrite rotationE => /andP[/orthogonal3P/and6P[ni nj nk ij ik jk]].
  rewrite ni nj ij /= => _; by rewrite !rowE -mulmxr_crossmulr_SO // vecij.
Qed.

Lemma SO_icrossj (T : rcfType) (r : 'M[T]_3) : r \is 'SO[T]_3 ->
  row 0 r *v row 1 r = row 2%:R r.
Proof. by case/rotation3P/and4P => _ _ _ /eqP ->. Qed.

Lemma SO_icrossk (T : rcfType) (r : 'M[T]_3) : r \is 'SO[T]_3 ->
  row 0 r *v row 2%:R r = - row 1 r.
Proof.
case/rotation3P/and4P => /eqP H1 _ /eqP H3 /eqP ->.
by rewrite double_crossmul H3 scale0r add0r dotmulvv H1 expr1n scale1r.
Qed.

Lemma SO_jcrossk (T : rcfType) (r : 'M[T]_3) : r \is 'SO[T]_3 ->
  row 1 r *v row 2%:R r = row 0 r.
Proof.
case/rotation3P/and4P => _ /eqP H1 /eqP H3 /eqP ->.
by rewrite double_crossmul dotmulvv H1 expr1n scale1r dotmulC H3 scale0r subr0.
Qed.

Section normalize.

Variables (T : rcfType) (n : nat).
Implicit Type u v : 'rV[T]_3.

Definition normalize v := (norm v)^-1 *: v.

Lemma normalize0 : normalize 0 = 0.
Proof. by rewrite /normalize scaler0. Qed.

Lemma normalizeN u : normalize (- u) = - normalize u.
Proof. by rewrite /normalize normN scalerN. Qed.

Lemma normalizeI v : norm v = 1 -> normalize v = v.
Proof. by move=> v1; rewrite /normalize v1 invr1 scale1r. Qed.

Lemma norm_normalize v : v != 0 -> norm (normalize v) = 1.
Proof.
move=> v0; rewrite normZ ger0_norm; last by rewrite invr_ge0 // norm_ge0.
by rewrite mulVr // unitfE norm_eq0.
Qed.

Lemma normalize_eq0 v : (normalize v == 0) = (v == 0).
Proof.
apply/idP/idP => [|/eqP ->]; last by rewrite normalize0.
case/boolP : (v == 0) => [//| /norm_normalize].
rewrite -norm_eq0 => -> /negPn; by rewrite oner_neq0.
Qed.

Lemma norm_scale_normalize u : norm u *: normalize u = u.
Proof.
case/boolP : (u == 0) => [/eqP -> {u}|u0]; first by rewrite norm0 scale0r.
by rewrite /normalize scalerA divrr ?scale1r // unitfE norm_eq0.
Qed.

Lemma normalizeZ u (u0 : u != 0) k (k0 : 0 < k) : normalize (k *: u) = normalize u.
Proof.
rewrite {1}/normalize normZ gtr0_norm // invrM ?unitfE ?gtr_eqF // ?norm_gt0 //.
by rewrite scalerA -mulrA mulVr ?mulr1 ?unitfE ?gtr_eqF.
Qed.

(* NB: not used *)
Lemma dotmul_normalize_norm u : u *d normalize u = norm u.
Proof.
case/boolP : (u == 0) => [/eqP ->{u}|u0]; first by rewrite norm0 dotmul0v.
rewrite -{1}(norm_scale_normalize u) dotmulZv dotmulvv norm_normalize //.
by rewrite expr1n mulr1.
Qed.

Lemma dotmul_normalize u v : (normalize u *d v == 0) = (u *d v == 0).
Proof.
case/boolP : (u == 0) => [/eqP ->|u0]; first by rewrite normalize0.
apply/idP/idP.
  rewrite /normalize dotmulZv mulf_eq0 => /orP [|//].
  by rewrite invr_eq0 norm_eq0 (negbTE u0).
rewrite /normalize dotmulZv => /eqP ->; by rewrite mulr0.
Qed.

End normalize.

Section characteristic_polynomial_dim3.

Variable T : numFieldType.

(* Cyril: a shorter proof of this fact goes through the
trigonalisation of complex matrice. Indeed, M = PTP^-1 with P unit and
T triangular of diagonal x, y, z. Then
char_poly M = (X - x)(X - y)(X - z) =
X³ - (x + y + z)X² + (xy + yz + zx)X  - xyz.
But tr M = tr T = x + y + z and tr M² = tr T² = x² + y² + z²,
then (tr M)² = (x + y + z)² = tr M² + 2(xy + yz + zx)
thus: xy + yz + zx = 1/2 * ((tr M)² - tr M²) *)
Lemma char_poly3_coef1 (M : 'M[T]_3) :
  let Z := 1 / 2%:R * (\tr M ^+ 2 - \tr (M ^+ 2)) in
  (char_poly M)`_1 = Z.
Proof.
move=> Z.
rewrite /char_poly /char_poly_mx det_mx33 !mxE mulr1n mulr0n !add0r.
rewrite !mulNr !mulrN !opprK.
rewrite !coefD.
(* 1 *)
rewrite [X in X + _ + _](_ : _ = M 0 0 * (M 2%:R 2%:R + M 1 1) +
   (M 1 1 * M 2%:R 2%:R - M 2%:R 1 * M 1 2%:R)); last first.
  rewrite coefM sum2E coefD coefX add0r coefN coefC [- _]/=.
  rewrite subn0 coefD.
  rewrite coefM sum2E subn0 coefD coefX add0r coefN (_ : _`_0 = M 1 1); last by rewrite coefC.
  rewrite coefD coefX coefN coefC subr0 mulr1.
  rewrite coefD coefN coefX coefN coefC subr0 mul1r.
  rewrite subnn coefD coefX add0r coefN coefC [in X in - M 1 1 - X]/=.
  rewrite coefM sum2E coefC coefC mulr0 add0r coefC mul0r subr0.
  rewrite coefD coefX coefN coefC subr0 mul1r.
  rewrite coefD coefM sum1E coefD coefX add0r coefN coefC [in X in - X * _`_ _]/=.
  rewrite coefD coefX add0r coefN coefC mulrN !mulNr opprK.
  rewrite coefN coefM sum1E coefC coefC [in X in M 1 1 * _ - X]/=.
  by rewrite -opprB mulrN 2!opprK.
rewrite [X in _ + X + _](_ : _ = - M 0 1 * M 1 0); last first.
  rewrite coefN coefM sum2E coefC [in X in X * _]/= subnn.
  rewrite coefD subn0 coefM sum2E.
  rewrite subn0 subnn coefC coefC mulr0 add0r.
  rewrite coefC mul0r add0r.
  rewrite coefM sum2E subn0 subnn coefC coefD coefX coefN coefC subr0 mulr1.
  rewrite coefC mul0r addr0 coefC mul0r addr0.
  by rewrite mulNr.
rewrite [X in _ + _ + X](_ : _ = - M 0 2%:R * M 2%:R 0); last first.
  rewrite coefN coefM sum2E subn0 subnn coefC.
  rewrite [in X in X * _]/=.
  rewrite coefD coefM sum2E subn0 coefC coefC mulr0 add0r.
  rewrite coefC mul0r add0r coefM sum2E subn0 subnn coefC [in X in X * _`_1]/=.
  by rewrite coefD coefX coefN coefC subr0 mulr1 coefC mul0r addr0 coefC mul0r addr0 mulNr.
rewrite /Z.
apply/(@mulrI _ 2%:R); first exact: pnatf_unit.
rewrite mulrA div1r divrr ?pnatf_unit // mul1r.
rewrite sqr_mxtrace.
rewrite mxtrace_sqr.
rewrite -4![in RHS]addrA [in RHS]addrCA [in RHS]opprD [in RHS](addrA (\sum__ M _ _ ^+ 2)) subrr add0r.
rewrite -3!mulrnDl -mulrnBl -[in RHS](mulr_natr _ 2) [in RHS](mulrC _ 2%:R); congr (_ * _).
rewrite mulrDr.
rewrite (addrC _ (M 0 0 * _)); rewrite -!addrA; congr (_ + _).
rewrite !addrA -mulrDl -!addrA; congr (_ + _).
rewrite addrCA opprD mulNr; congr (_ + _).
rewrite opprD addrC mulNr; congr (_ + _).
by rewrite mulrC.
Qed.

Lemma char_poly3 (M : 'M[T]_3) :
  let Z := 1 / 2%:R * ((\tr M) ^+ 2 - \tr (M ^+ 2)) in
  char_poly M = 'X^3 - (\tr M) *: 'X^2 + Z *: 'X - (\det M)%:P.
Proof.
move=> Z.
rewrite -(coefK (char_poly M)) (size_char_poly M).
apply/polyP.
case. (* coef0 *)
  rewrite coef_poly char_poly_det !coef_add_poly !coef_opp_poly !coefZ.
  rewrite !coefX !coefXn add0r mulr0 oppr0 mulr0 add0r add0r coefC /=.
  by rewrite exprS sqrrN expr1n mulr1 mulN1r.
case; last first.
  case. (* coef2 *)
    rewrite coef_poly !coef_add_poly !coef_opp_poly !coefZ !coefX !coefXn.
    by rewrite add0r mulr0 mulr1 addr0 coefC subr0 char_poly_trace.
  case; last first. (* coef n >= 4 *)
    move=> n.
    rewrite coef_poly !coef_add_poly !coef_opp_poly !coefZ !coefX !coefXn.
    by rewrite add0r mulr0 mulr0 coefC subr0 addr0 oppr0.
  (* coef3 *)
  rewrite coef_poly !coef_add_poly !coef_opp_poly !coefZ !coefX !coefXn.
  rewrite mulr0 subr0 mulr0 addr0 coefC subr0; apply/eqP.
  rewrite (_ : _`_3 = lead_coef (char_poly M)); last first.
    by rewrite lead_coefE size_char_poly.
  by rewrite -monicE char_poly_monic.
(* coef1 *)
rewrite coef_poly !coef_add_poly !coef_opp_poly !coefZ !coefX !coefXn.
rewrite add0r mulr1 mulr0 oppr0 add0r coefC subr0.
suff : (char_poly M)`_1 = Z by move=> ->.
by rewrite char_poly3_coef1.
Qed.

End characteristic_polynomial_dim3.
