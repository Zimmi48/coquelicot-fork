(**
This file is part of the Coquelicot formalization of real
analysis in Coq: http://coquelicot.saclay.inria.fr/

Copyright (C) 2011-2013 Sylvie Boldo
#<br />#
Copyright (C) 2011-2013 Catherine Lelay
#<br />#
Copyright (C) 2011-2013 Guillaume Melquiond

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 3 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
COPYING file for more details.
*)

Require Import Reals ssreflect.
Require Import Rcomplements Rbar.
Open Scope R_scope.

(** * Filters *)

(** ** Definitions *) 

Class Filter {T : Type} (F : (T -> Prop) -> Prop) := {
  filter_true : F (fun _ => True) ;
  filter_and : forall P Q : T -> Prop, F P -> F Q -> F (fun x => P x /\ Q x) ;
  filter_imp : forall P Q : T -> Prop, (forall x, P x -> Q x) -> F P -> F Q
}.

Class ProperFilter {T : Type} (F : (T -> Prop) -> Prop) := {
  filter_ex : forall P, F P -> exists x, P x ;
  filter_filter :> Filter F
}.

Lemma filter_forall :
  forall {T : Type} {F} {FF: @Filter T F} (P : T -> Prop),
  (forall x, P x) -> F P.
Proof.
intros T F FF P H.
apply filter_imp with (fun _ => True).
easy.
apply filter_true.
Qed.

Lemma filter_const :
  forall {T : Type} {F} {FF: @ProperFilter T F} (P : Prop),
  F (fun _ => P) -> P.
Proof.
intros T F FF P H.
destruct (filter_ex (fun _ => P) H) as [_ H'].
exact H'.
Qed.

(** ** Limits expressed with filters *)

Definition filter_le {T : Type} (F G : (T -> Prop) -> Prop) :=
  forall P, G P -> F P.

Lemma filter_le_refl :
  forall T F, @filter_le T F F.
Proof.
now intros T F P.
Qed.

Lemma filter_le_trans :
  forall T F G H, @filter_le T F G -> filter_le G H -> filter_le F H.
Proof.
intros T F G H FG GH P K.
now apply FG, GH.
Qed.

Definition filtermap {T U : Type} (f : T -> U) (F : (T -> Prop) -> Prop) :=
  fun P => F (fun x => P (f x)).

Global Instance filtermap_filter :
  forall T U (f : T -> U) (F : (T -> Prop) -> Prop),
  Filter F -> Filter (filtermap f F).
Proof.
intros T U f F FF.
unfold filtermap.
constructor.
- apply filter_true.
- intros P Q HP HQ.
  now apply filter_and.
- intros P Q H HP.
  unfold filtermap.
  apply (filter_imp (fun x => P (f x))).
  intros x Hx.
  now apply H.
  exact HP.
Qed.

Global Instance filtermap_proper_filter :
  forall T U (f : T -> U) (F : (T -> Prop) -> Prop),
  ProperFilter F -> ProperFilter (filtermap f F).
Proof.
intros T U f F FF.
unfold filtermap.
split.
- intros P FP.
  destruct (filter_ex _ FP) as [x Hx].
  now exists (f x).
- apply filtermap_filter.
  apply filter_filter.
Qed.

Definition filterlim {T U : Type} (f : T -> U) F G :=
  filter_le (filtermap f F) G.

Lemma filterlim_id :
  forall T (F : (T -> Prop) -> Prop), filterlim (fun x => x) F F.
Proof.
now intros T F P HP.
Qed.

Lemma filterlim_compose :
  forall T U V (f : T -> U) (g : U -> V) F G H,
  filterlim f F G -> filterlim g G H ->
  filterlim (fun x => g (f x)) F H.
Proof.
intros T U V f g F G H FG GH P HP.
apply (FG (fun x => P (g x))).
now apply GH.
Qed.

Lemma filterlim_ext_loc :
  forall {T U F G} {FF : Filter F} (f g : T -> U),
  F (fun x => f x = g x) ->
  filterlim f F G ->
  filterlim g F G.
Proof.
intros T U F G FF f g Efg Lf P GP.
specialize (Lf P GP).
generalize (filter_and _ _ Efg Lf).
unfold filtermap.
apply filter_imp.
now intros x [-> H].
Qed.

Lemma filterlim_ext :
  forall {T U F G} {FF : Filter F} (f g : T -> U),
  (forall x, f x = g x) ->
  filterlim f F G ->
  filterlim g F G.
Proof.
intros T U F G FF f g Efg.
apply filterlim_ext_loc.
now apply filter_forall.
Qed.

Lemma filterlim_filter_le_1 :
  forall {T U F G H} (f : T -> U),
  filter_le G F ->
  filterlim f F H ->
  filterlim f G H.
Proof.
intros T U F G H f K Hf P HP.
apply K.
now apply Hf.
Qed.

Lemma filterlim_filter_le_2 :
  forall {T U F G H} (f : T -> U),
  filter_le G H ->
  filterlim f F G ->
  filterlim f F H.
Proof.
intros T U F G H f K Hf P HP.
apply Hf.
now apply K.
Qed.

(** ** Specific filters *)

(** Filters for pairs *)

Inductive filter_prod {T U : Type} (F G : _ -> Prop) (P : T * U -> Prop) : Prop :=
  Filter_prod (Q : T -> Prop) (R : U -> Prop) :
    F Q -> G R -> (forall x y, Q x -> R y -> P (x, y)) -> filter_prod F G P.

Global Instance filter_prod_filter :
  forall T U (F : (T -> Prop) -> Prop) (G : (U -> Prop) -> Prop),
  Filter F -> Filter G -> Filter (filter_prod F G).
Proof.
intros T U F G FF FG.
constructor.
- exists (fun _ => True) (fun _ => True).
  apply filter_true.
  apply filter_true.
  easy.
- intros P Q [AP BP P1 P2 P3] [AQ BQ Q1 Q2 Q3].
  exists (fun x => AP x /\ AQ x) (fun x => BP x /\ BQ x).
  now apply filter_and.
  now apply filter_and.
  intros x y [Px Qx] [Py Qy].
  split.
  now apply P3.
  now apply Q3.
- intros P Q HI [AP BP P1 P2 P3].
  exists AP BP ; try easy.
  intros x y Hx Hy.
  apply HI.
  now apply P3.
Qed.

Lemma filterlim_fst :
  forall {T U F G} {FG : Filter G},
  filterlim (@fst T U) (filter_prod F G) F.
Proof.
intros T U F G FG P HP.
exists P (fun _ => True) ; try easy.
apply filter_true.
Qed.

Lemma filterlim_snd :
  forall {T U F G} {FF : Filter F},
  filterlim (@snd T U) (filter_prod F G) G.
Proof.
intros T U F G FF P HP.
exists (fun _ => True) P ; try easy.
apply filter_true.
Qed.

Lemma filterlim_pair :
  forall {T U V F G H} {FF : Filter F},
  forall (f : T -> U) (g : T -> V),
  filterlim f F G ->
  filterlim g F H ->
  filterlim (fun x => (f x, g x)) F (filter_prod G H).
Proof.
intros T U V F G H FF f g Cf Cg P [A B GA HB HP].
unfold filtermap.
apply (filter_imp (fun x => A (f x) /\ B (g x))).
intros x [Af Bg].
now apply HP.
apply filter_and.
now apply Cf.
now apply Cg.
Qed.

Lemma filterlim_compose_2 :
  forall {T U V W F G H I} {FF : Filter F},
  forall (f : T -> U) (g : T -> V) (h : U -> V -> W),
  filterlim f F G ->
  filterlim g F H ->
  filterlim (fun x => h (fst x) (snd x)) (filter_prod G H) I ->
  filterlim (fun x => h (f x) (g x)) F I.
Proof.
intros T U V W F G H I FF f g h Cf Cg Ch.
change (fun x => h (f x) (g x)) with (fun x => h (fst (f x, g x)) (snd (f x, g x))).
apply: filterlim_compose Ch.
now apply filterlim_pair.
Qed.

(** Restriction of a filter to a domain *)

Definition within {T : Type} D (F : (T -> Prop) -> Prop) (P : T -> Prop) :=
  F (fun x => D x -> P x).

Global Instance within_filter :
  forall T D F, Filter F -> Filter (@within T D F).
Proof.
intros T D F FF.
unfold within.
constructor.
- now apply filter_forall.
- intros P Q WP WQ.
  apply filter_imp with (fun x => (D x -> P x) /\ (D x -> Q x)).
  intros x [HP HQ] HD.
  split.
  now apply HP.
  now apply HQ.
  now apply filter_and.
- intros P Q H FP.
  apply filter_imp with (fun x => (D x -> P x) /\ (P x -> Q x)).
  intros x [H1 H2] HD.
  apply H2, H1, HD.
  apply filter_and.
  exact FP.
  now apply filter_forall.
Qed.

Lemma filter_le_within :
  forall {T} {F : (T -> Prop) -> Prop} {FF : Filter F} D,
  filter_le (within D F) F.
Proof.
intros T F D P HP.
unfold within.
now apply filter_imp.
Qed.

Lemma filterlim_within_ext :
  forall {T U F G} {FF : Filter F} D (f g : T -> U),
  (forall x, D x -> f x = g x) ->
  filterlim f (within D F) G ->
  filterlim g (within D F) G.
Proof.
intros T U F G FF D f g Efg.
apply filterlim_ext_loc.
unfold within.
now apply filter_forall.
Qed.

Definition subset_filter {T} (F : (T -> Prop) -> Prop) (dom : T -> Prop) (P : {x|dom x} -> Prop) : Prop :=
  F (fun x => forall H : dom x, P (existT _ x H)).

Global Instance subset_filter_filter :
  forall T F (dom : T -> Prop),
  Filter F ->
  Filter (subset_filter F dom).
Proof.
intros T F dom FF.
constructor ; unfold subset_filter.
- now apply filter_imp with (2 := filter_true).
- intros P Q HP HQ.
  generalize (filter_and _ _ HP HQ).
  apply filter_imp.
  intros x [H1 H2] H.
  now split.
- intros P Q H.
  apply filter_imp.
  intros x H' H0.
  now apply H.
Qed.

Lemma subset_filter_proper :
  forall {T F} {FF : Filter F} (dom : T -> Prop),
  (forall P, F P -> exists x, dom x /\ P x) ->
  ProperFilter (subset_filter F dom).
Proof.
intros T F dom FF H.
constructor.
- unfold subset_filter.
  intros P HP.
  destruct (H _ HP) as [x [H1 H2]].
  exists (existT _ x H1).
  now apply H2.
- now apply subset_filter_filter.
Qed.

(** * Algebraic spaces *)
(** ** Abelian groups *)

Class AbelianGroup G := {
  plus : G -> G -> G ;
  opp : G -> G ;
  minus x y := plus x (opp y) ;
  zero : G ;
  plus_comm : forall x y, plus x y = plus y x ;
  plus_assoc : forall x y z, plus x (plus y z) = plus (plus x y) z ;
  plus_zero_r : forall x, plus x zero = x ;
  plus_opp_r : forall x, plus x (opp x) = zero
}.

(** Arithmetic operations *)

Section AbelianGroup.

Context {G} {GG : AbelianGroup G}.

Lemma plus_zero_l :
  forall x : G,
  plus zero x = x.
Proof.
intros x.
now rewrite plus_comm plus_zero_r.
Qed.

Lemma plus_opp_l :
  forall x : G,
  plus (opp x) x = zero.
Proof.
intros x.
rewrite plus_comm.
apply plus_opp_r.
Qed.

Lemma opp_zero :
  opp zero = zero.
Proof.
rewrite <- (plus_zero_r (opp zero)).
apply plus_opp_l.
Qed.

Lemma minus_zero_r :
  forall x : G,
  minus x zero = x.
Proof.
intros x.
unfold minus.
rewrite opp_zero.
apply plus_zero_r.
Qed.

Lemma plus_reg_r :
  forall x y z : G,
  plus x z = plus y z -> x = y.
Proof.
intros x y z H.
rewrite <- (plus_zero_r x), <- (plus_zero_r y).
rewrite <- (plus_opp_r z).
rewrite 2!plus_assoc.
now rewrite H.
Qed.

Lemma opp_plus :
  forall x y : G,
  opp (plus x y) = plus (opp x) (opp y).
Proof.
intros x y.
apply plus_reg_r with (plus x y).
rewrite plus_opp_l.
rewrite plus_assoc.
rewrite (plus_comm (opp x)).
rewrite <- (plus_assoc (opp y)).
rewrite plus_opp_l.
rewrite plus_zero_r.
apply sym_eq, plus_opp_l.
Qed.

Lemma opp_opp :
  forall x : G,
  opp (opp x) = x.
Proof.
intros x.
apply plus_reg_r with (opp x).
rewrite plus_opp_r.
apply plus_opp_l.
Qed.

Lemma plus_eq_compat_l :
  forall r x y : G,
  plus r x = plus r y -> x = y.
Proof.
intros r x y H.
rewrite -(plus_zero_l x) -(plus_opp_l r) -plus_assoc.
rewrite H.
now rewrite plus_assoc plus_opp_l plus_zero_l.
Qed.

(** Sum *)

Fixpoint sum_n (a:nat -> G) (N : nat) {struct N} : G :=
  match N with
   | 0%nat => a 0%nat
   | S i => plus (sum_n a i)  (a (S i))
  end.

Lemma sum_n_ext_aux :
  forall (a b : nat -> G) N,
  (forall n, (n < S N)%nat -> a n = b n) ->
  sum_n a N = sum_n b N.
Proof.
  intros a b N H; induction N; simpl.
  apply H.
  by apply le_refl.
  rewrite IHN.
  by rewrite H.
  move => n Hn.
  now apply H, le_trans with (1 := Hn), le_n_Sn.
Qed.

Lemma sum_n_ext :
  forall (a b : nat -> G) N,
  (forall n, a n = b n) ->
  sum_n a N = sum_n b N.
Proof.
  intros a b N H; induction N; simpl.
  apply H.
  now rewrite IHN; rewrite H.
Qed.

Lemma decomp_sum_n :
  forall (a : nat-> G) N,
  (0 < N)%nat ->
  sum_n a N = plus (a 0%nat) (sum_n (fun i : nat => a (S i)) (pred N)).
Proof.
  intros a N HN; destruct N; simpl.
  exfalso; omega.
  clear HN; induction N; simpl.
  easy.
  rewrite IHN.
  apply sym_eq, plus_assoc.
Qed.  

Lemma sum_n_plus :
  forall (u v : nat -> G) (n : nat),
  sum_n (fun k => plus (u k) (v k)) n = plus (sum_n u n) (sum_n v n).
Proof.
  intros u v.
  induction n ; simpl.
  by [].
  rewrite IHn ; clear IHn.
  rewrite -?plus_assoc.
  apply f_equal.
  rewrite ?plus_assoc.
  apply f_equal2.
  by apply plus_comm.
  by [].
Qed.

Lemma sum_n_switch :
  forall (u : nat -> nat -> G) (m n : nat),
  sum_n (fun i => sum_n (u i) n) m = sum_n (fun j => sum_n (fun i => u i j) m) n.
Proof.
  intros u.
  induction m ; simpl ; intros n.
  by [].
  rewrite IHm ; clear IHm.
  by rewrite -sum_n_plus.
Qed.

End AbelianGroup.

(** ** Noncommutative rings *)

Class Ring_mixin (K : Type) (KA : AbelianGroup K) := {
  mult : K -> K -> K ;
  one : K ;
  mult_assoc : forall x y z, mult x (mult y z) = mult (mult x y) z ;
  mult_one_r : forall x, mult x one = x ;
  mult_one_l : forall x, mult one x = x ;
  mult_distr_r : forall x y z, mult (plus x y) z = plus (mult x z) (mult y z) ;
  mult_distr_l : forall x y z, mult x (plus y z) = plus (mult x y) (mult x z)
}.
Class Ring K := {
  ring_group :> AbelianGroup K ;
  ring_mixin :> Ring_mixin K ring_group
}.

(** Arithmetic operations *)

Section Ring.

Context {K} {RK : Ring K}.

Lemma mult_zero_r :
  forall x : K,
  mult x zero = zero.
Proof.
intros x.
apply plus_reg_r with (mult x zero).
rewrite <- mult_distr_l.
rewrite plus_zero_r.
now rewrite plus_zero_l.
Qed.

Lemma mult_zero_l :
  forall x : K,
  mult zero x = zero.
Proof.
intros x.
apply plus_reg_r with (mult zero x).
rewrite <- mult_distr_r.
rewrite plus_zero_r.
now rewrite plus_zero_l.
Qed.

Lemma opp_mult_r :
  forall x y : K,
  opp (mult x y) = mult x (opp y).
Proof.
intros x y.
apply plus_eq_compat_l with (mult x y).
rewrite plus_opp_r -mult_distr_l.
now rewrite plus_opp_r mult_zero_r.
Qed.

Lemma opp_mult_l :
  forall x y : K,
  opp (mult x y) = mult (opp x) y.
Proof.
intros x y.
apply plus_eq_compat_l with (mult x y).
rewrite plus_opp_r -mult_distr_r.
now rewrite plus_opp_r mult_zero_l.
Qed.

Lemma opp_mult_m1 :
  forall x : K,
  opp x = mult (opp one) x.
Proof.
  intros x.
  rewrite -opp_mult_l opp_mult_r.
  by rewrite mult_one_l.
Qed.

Lemma sum_n_mult_r :
 forall (a : K) (u : nat -> K) (n : nat),
  sum_n (fun k => mult (u k) a) n = mult (sum_n u n) a.
Proof.
  intros a u n.
  induction n ; simpl.
  by [].
  rewrite IHn.
  apply eq_sym.
  by apply mult_distr_r.
Qed.

Lemma sum_n_mult_l :
 forall (a : K) (u : nat -> K) (n : nat),
  sum_n (fun k => mult a (u k)) n = mult a (sum_n u n).
Proof.
  intros a u n.
  induction n ; simpl.
  by [].
  rewrite IHn.
  apply eq_sym.
  by apply mult_distr_l.
Qed.

End Ring.

(** ** Rings with absolute value *)

Class AbsRing_mixin K (RK : Ring K) := {
  abs : K -> R ;
  abs_zero : abs zero = 0 ;
  abs_opp_one : abs (opp one) = 1 ;
  abs_triangle : forall x y, abs (plus x y) <= abs x + abs y ;
  abs_mult : forall x y, abs (mult x y) <= abs x * abs y
}.

Class AbsRing K := {
  absring_group :> AbelianGroup K ;
  absring_ring' :> Ring_mixin K absring_group ;
  absring_ring := Build_Ring _ _ absring_ring' ;
  absring_mixin :> AbsRing_mixin K absring_ring
}.

Global Existing Instance absring_ring.

(** Usual properties *)

Section AbsRing.

Context {K} {AK : AbsRing K}.

Lemma abs_opp :
  forall x, abs (opp x) = abs x.
Proof.
intros x.
apply Rle_antisym.
- rewrite (opp_mult_m1 (RK := absring_ring)).
  rewrite -(Rmult_1_l (abs x)) -abs_opp_one.
  apply abs_mult.
- rewrite -{1}[x]opp_opp.
  rewrite (opp_mult_m1 (RK := absring_ring)).
  rewrite -(Rmult_1_l (abs (opp x))) -abs_opp_one.
  apply abs_mult.
Qed.

Lemma abs_minus :
  forall x y : K, abs (minus x y) = abs (minus y x).
Proof.
intros x y.
by rewrite /minus -abs_opp opp_plus opp_opp plus_comm.
Qed.

Lemma abs_one :
  abs one = 1.
Proof.
rewrite -abs_opp.
exact abs_opp_one.
Qed.

Lemma abs_ge_0 :
  forall x, 0 <= abs x.
Proof.
  intros x.
  apply Rmult_le_reg_l with 2.
  by apply Rlt_0_2.
  rewrite Rmult_0_r -abs_zero -(plus_opp_l x).
  apply Rle_trans with (1 := abs_triangle _ _).
  rewrite abs_opp.
  apply Req_le ; ring.
Qed.

End AbsRing.

(** * Metric spaces defined using balls *)

Class MetricBall M := {
  ball : M -> R -> M -> Prop ;
  ball_center : forall x (e : posreal), ball x e x ;
  ball_sym : forall x y e, ball x e y -> ball y e x ;
  ball_triangle : forall x y z e1 e2, ball x e1 y -> ball y e2 z -> ball x (e1 + e2) z ;
  ball_le : forall x e1 e2, e1 <= e2 -> forall y, ball x e1 y -> ball x e2 y
}.

(** ** Specific metric spaces *)

(** Rings with absolute value *)

Lemma MetricBall_AbsRing_triangle :
  forall {K} {AK : AbsRing K} (x y z : K) (e1 e2 : R),
  abs (minus y x) < e1 -> abs (minus z y) < e2 -> abs (minus z x) < e1 + e2.
Proof.
intros K AK x y z e1 e2 H1 H2.
replace (minus z x) with (plus (minus y x) (minus z y)).
apply: Rle_lt_trans (abs_triangle _ _) _.
now apply Rplus_lt_compat.
rewrite plus_comm /minus plus_assoc.
apply (f_equal (fun y => plus y _)).
rewrite <- plus_assoc.
now rewrite plus_opp_l plus_zero_r.
Qed.

Global Instance MetricBall_AbsRing {K} :
  AbsRing K -> MetricBall K.
Proof.
intros AK.
apply Build_MetricBall with (fun x eps y => abs (minus y x) < eps).
- intros x e.
  rewrite /minus plus_opp_r abs_zero.
  apply cond_pos.
- intros x y e.
  now rewrite abs_minus.
- apply MetricBall_AbsRing_triangle.
- intros x e1 e2 H y H'.
  apply: Rlt_le_trans H' H.
Defined.

(** Functional metric spaces *)

Global Instance MetricBall_fct {T M} :
  MetricBall M -> MetricBall (T -> M).
Proof.
  intros MM.
  exists (fun f eps g => forall t, ball (f t) eps (g t)).
  + intros x e t.
    exact: ball_center.
  + intros x y e H t.
    by apply ball_sym.
  + intros x y z e1 e2 H1 H2 t.
    now apply ball_triangle with (y t).
  + intros x e1 e2 He y H t.
    now apply ball_le with e1.
Defined.

(** ** Local predicates *)
(** locally_dist *)

Definition locally_dist {T : Type} (d : T -> R) (P : T -> Prop) :=
  exists delta : posreal, forall y, d y < delta -> P y.

Global Instance locally_dist_filter :
  forall T (d : T -> R), Filter (locally_dist d).
Proof.
intros T d.
constructor.
- now exists (mkposreal _ Rlt_0_1).
- intros P Q [dP HP] [dQ HQ].
  exists (mkposreal _ (Rmin_stable_in_posreal dP dQ)).
  simpl.
  intros y Hy.
  split.
  apply HP.
  apply Rlt_le_trans with (1 := Hy).
  apply Rmin_l.
  apply HQ.
  apply Rlt_le_trans with (1 := Hy).
  apply Rmin_r.
- intros P Q H [dP HP].
  exists dP.
  intros y Hy.
  apply H.
  now apply HP.
Qed.

(** locally *)

Section Locally.

Context {T} {MT : MetricBall T}.

Definition locally (x : T) (P : T -> Prop) :=
  exists eps : posreal, forall y, ball x eps y -> P y.

Global Instance locally_filter :
  forall x : T, ProperFilter (locally x).
Proof.
intros x.
constructor ; [idtac|constructor].
- intros P [eps H].
  exists x.
  apply H.
  apply ball_center.
- now exists (mkposreal _ Rlt_0_1).
- intros P Q [dP HP] [dQ HQ].
  exists (mkposreal _ (Rmin_stable_in_posreal dP dQ)).
  simpl.
  intros y Hy.
  split.
  apply HP.
  apply ball_le with (2 := Hy).
  apply Rmin_l.
  apply HQ.
  apply ball_le with (2 := Hy).
  apply Rmin_r.
- intros P Q H [dP HP].
  exists dP.
  intros y Hy.
  apply H.
  now apply HP.
Qed.

Lemma locally_locally :
  forall (x : T) (P : T -> Prop),
  locally x P -> locally x (fun y => locally y P).
Proof.
intros x P [dp Hp].
exists (pos_div_2 dp).
intros y Hy.
exists (pos_div_2 dp) => /= z Hz.
apply Hp.
rewrite (double_var dp).
now apply ball_triangle with y.
Qed.

Lemma locally_singleton :
  forall (x : T) (P : T -> Prop),
  locally x P -> P x.
Proof.
intros x P [dp H].
apply H.
by apply ball_center.
Qed.

Lemma locally_ball :
  forall (x : T) (eps : posreal), locally x (ball x eps).
Proof.
  intros x eps.
  now exists eps.
Qed.

Lemma locally_ex_dec :
  forall (x : T) (P : T -> Prop),
  (forall x, P x \/ ~P x) ->
  locally x P ->
  {d : posreal | forall y, ball x d y -> P y}.
Proof.
intros x P P_dec H.
set (Q := fun z => z <= 1 /\ forall y, ball x z y -> P y).
assert (He : exists e : posreal, Q e).
  destruct H as [eps Heps].
  exists (mkposreal _ (Rmin_stable_in_posreal eps (mkposreal _ Rlt_0_1))).
  split.
  apply Rmin_r.
  intros y Hy.
  apply Heps.
  apply ball_le with (2 := Hy).
  apply Rmin_l.
destruct (completeness Q) as [d [H1 H2]].
- exists 1.
  now intros y [Hy _].
- destruct He as [eps Heps].
  now exists eps.
assert (Zd : 0 < d).
  destruct He as [eps Heps].
  apply Rlt_le_trans with (1 := cond_pos eps).
  now apply H1.
exists (mkposreal _ (is_pos_div_2 (mkposreal _ Zd))).
simpl Rdiv.
intros y Hy.
destruct (P_dec y) as [HP|HP].
exact HP.
exfalso.
apply (Rlt_not_le _ _ (Rlt_eps2_eps _ Zd)).
apply H2.
intros z Hz.
apply Rnot_lt_le.
contradict HP.
apply Hz.
apply ball_le with (2 := Hy).
now apply Rlt_le.
Qed.

Definition is_filter_lim (F : (T -> Prop) -> Prop) (x : T) :=
  forall P, locally x P -> F P.

Lemma is_filter_lim_filter_le :
  forall {F G} (x : T),
  filter_le G F ->
  is_filter_lim F x -> is_filter_lim G x.
Proof.
intros F G x L Fx P HP.
apply L.
now apply Fx.
Qed.

End Locally.

Lemma filterlim_locally :
  forall {T U} {MU : MetricBall U} {F} {FF : Filter F} (f : T -> U) y,
  filterlim f F (locally y) <->
  forall eps : posreal, F (fun x => ball y eps (f x)).
Proof.
intros T U MU F FF f y.
split.
- intros Cf eps.
  apply (Cf (fun x => ball y eps x)).
  now exists eps.
- intros Cf P [eps He].
  apply: filter_imp (Cf eps).
  intros t.
  apply He.
Qed.

Lemma filterlim_locally_unique: forall {T U} {MU : MetricBall U} {F} {FF: ProperFilter F}
  (f:T -> U) l l', filterlim f F (locally l) ->  filterlim f F (locally l') ->
    (forall eps : posreal, ball l eps l').
Proof.
intros T U MU F FF f l l' Hl Hl' eps.
assert (locally l (ball l (pos_div_2 eps))).
  by apply locally_ball.
specialize (Hl (ball l (pos_div_2 eps)) H).
assert (locally l' (ball l' (pos_div_2 eps))).
  by apply locally_ball.
specialize (Hl' (ball l' (pos_div_2 eps)) H0).
unfold filtermap in Hl, Hl'.
generalize (filter_and _ _ Hl Hl') => {H H0} H.
apply filter_ex in H.
case: H => x H.
rewrite (double_var eps).
apply ball_triangle with (f x).
by apply H.
by apply ball_sym, H.
Qed.

(** locally' *)

Definition locally' {T} {MT : MetricBall T} (x : T) :=
  within (fun y => y <> x) (locally x).

Global Instance locally'_filter :
  forall {T} {MT : MetricBall T} (x : T), Filter (locally' x).
Proof.
intros T MT x.
apply within_filter.
apply locally_filter.
Qed.

(** ** Open sets in metric spaces *)

Section Open.

Context {T} {MT : MetricBall T}.

Definition open (D : T -> Prop) :=
  forall x, D x -> locally x D.

Lemma open_ext :
  forall D E : T -> Prop,
  (forall x, D x <-> E x) ->
  open D -> open E.
Proof.
intros D E H OD x Ex.
generalize (OD x (proj2 (H x) Ex)).
apply filter_imp.
intros y.
apply H.
Qed.

Lemma open_and :
  forall D E : T -> Prop,
  open D -> open E ->
  open (fun x => D x /\ E x).
Proof.
intros D E OD OE x [Dx Ex].
apply filter_and.
now apply OD.
now apply OE.
Qed.

Lemma open_or :
  forall D E : T -> Prop,
  open D -> open E ->
  open (fun x => D x \/ E x).
Proof.
intros D E OD OE x [Dx|Ex].
generalize (OD x Dx).
apply filter_imp.
intros y Dy.
now left.
generalize (OE x Ex).
apply filter_imp.
intros y Ey.
now right.
Qed.

Lemma open_true :
  open (fun x : T => True).
Proof.
intros x _.
apply filter_true.
Qed.

Lemma open_false :
  open (fun x : T => False).
Proof.
now intros x Hx.
Qed.

End Open.

(** ** Complete metric spaces *)

Class CompleteSpace_mixin T (MT : MetricBall T) := {
  cauchy := fun (F : (T -> Prop) -> Prop) => forall eps : posreal, exists x, F (ball x eps) ;
  complete_cauchy : forall F, ProperFilter F -> cauchy F -> {x : T | forall eps : posreal, F (ball x eps)}
}.

Class CompleteSpace T := {
  complete_metric :> MetricBall T ;
  complete_mixin :> CompleteSpace_mixin T complete_metric
}.

Lemma cauchy_distance :
  forall {T} {MT : MetricBall T} {F} {FF : ProperFilter F},
  (forall eps : posreal, exists x, F (ball x eps)) <->
  (forall eps : posreal, exists P, F P /\ forall u v : T, P u -> P v -> ball u eps v).
Proof.
  intros T MT F FF.
  split.

  intros H eps.
  case: (H (pos_div_2 eps)) => {H} x Hx.
  exists (ball x (pos_div_2 eps)).
  split.
  by [].
  move => u v Hu Hv.
  rewrite (double_var eps).
  apply ball_triangle with x.
  by apply ball_sym.
  exact Hv.

  intros H eps.
  case: (H eps) => {H} P [HP H].
  destruct (filter_ex P HP) as [x Hx].
  exists x.
  move: (fun v => H x v Hx) => {H} H.
  apply filter_imp with (1 := H).
  by [].
Qed.

Lemma filterlim_locally_cauchy :
  forall {T U} {CU : CompleteSpace U} {F} {FF : ProperFilter F} (f : T -> U),
  (forall eps : posreal, exists P, F P /\ forall u v : T, P u -> P v -> ball (f u) eps (f v)) <->
  exists y, filterlim f F (locally y).
Proof.
intros T U CU F FF f.
split.
- intros H.
  destruct (complete_cauchy (filtermap f F)) as [y Hy].
  + now apply filtermap_proper_filter.
  + intros eps.
    destruct (H eps) as [P [FP H']].
    destruct (filter_ex _ FP) as [x Hx].
    exists (f x).
    unfold filtermap.
    generalize FP.
    apply filter_imp.
    intros x' Hx'.
    now apply H'.
  + exists y.
    intros P [eps HP].
    refine (_ (Hy eps)).
    unfold filtermap.
    apply filter_imp.
    intros x Hx.
    now apply HP.
- intros [y Hy] eps.
  exists (fun x => ball y (pos_div_2 eps) (f x)).
  split.
  apply Hy.
  now exists (pos_div_2 eps).
  intros u v Hu Hv.
  rewrite (double_var eps).
  apply ball_triangle with y.
  apply ball_sym.
  exact Hu.
  exact Hv.
Qed.

Lemma complete_cauchy_fct {T U} {CMS : CompleteSpace U} : 
  forall F : ((T -> U) -> Prop) -> Prop,
  ProperFilter F ->
    (forall eps : posreal, exists f : T -> U, F (ball f eps)) ->
    {f : T -> U | forall eps : posreal, F (ball f eps)}.
Proof.
  move => F FF HFc.
  
  set Fr := fun (t : T) (P : U -> Prop) => F (fun g => P (g t)).
  have FFr : forall t, ProperFilter (Fr t).
    case: FF => HF FF t.
    split.
    - move => P Hp.
      case: (HF _ Hp) => f Hf.
      by exists (f t).
    - split.
      + by apply FF.
      + move => P P' Hp Hp'.
      by apply FF.
      + move => P P' Hpp'.
      apply FF.
      move => f ; by apply Hpp'.
  assert (HFrc : forall t, forall eps : posreal, exists x : U, Fr t (ball x eps)).
    move => t eps.
    case: (HFc eps) => f Hf.
    exists (f t).
    move: Hf ; apply FF => g.
    by [].
  assert (Hex : forall t, {x | forall eps : posreal, Fr t (ball x eps)}).
    move => t.
    by apply complete_cauchy.
  set f := fun t => projT1 (Hex t) ; exists f.

  move => eps.

  assert (forall t (eps : posreal), (Fr t) (fun x => ball (f t) eps x)).
    move => t.
    apply (projT2 (Hex t)).

  generalize (proj1 cauchy_distance HFc) => {HFc} HFc.

  case: (HFc (pos_div_2 eps)) => {HFc} P ; simpl ; case => HP H0.
  apply filter_imp with (2 := HP).
  move => g Hg t.
  move: (fun h => H0 g h Hg) => {H0} H0.
  move: (H t (pos_div_2 eps)) ; simpl => {H} H.
  unfold Fr in H ; generalize (filter_and _ _ H HP) => {H} H.
  apply filter_ex in H ; case: H => h H.
  rewrite (double_var eps).
  apply ball_triangle with (h t).
  by apply H.
  apply ball_sym, H0.
  by apply H.
Qed.

Global Instance CompleteSpace_fct {T U} : 
  CompleteSpace U -> CompleteSpace (T -> U).
Proof.
  intros.
  apply Build_CompleteSpace with (@MetricBall_fct T _ complete_metric).
  constructor.
  apply complete_cauchy_fct.
Defined.

(** * Vector Spaces *)

Class VectorSpace_mixin V K {RK : Ring K} (AV : AbelianGroup V) := {
  scal : K -> V -> V ;
  scal_assoc : forall x y u, scal x (scal y u) = scal (mult x y) u ;
  scal_one : forall u, scal one u = u ;
  scal_distr_l : forall x u v, scal x (plus u v) = plus (scal x u) (scal x v) ;
  scal_distr_r : forall x y u, scal (plus x y) u = plus (scal x u) (scal y u)
}.

Class VectorSpace V K {RK : Ring K} := {
  vspace_group :> AbelianGroup V ;
  vspace_mixin :> VectorSpace_mixin V K vspace_group
}.

Global Instance VectorSpace_mixin_Ring :
  forall K (RK : Ring K), VectorSpace_mixin K K ring_group.
Proof.
  intros K RK.
  apply Build_VectorSpace_mixin with mult.
  exact mult_assoc.
  exact mult_one_l.
  exact mult_distr_l.
  exact mult_distr_r.
Defined.

Global Instance VectorSpace_Ring :
  forall K (RK : Ring K), VectorSpace K K.
Proof.
  intros K RK.
  eapply Build_VectorSpace.
  apply VectorSpace_mixin_Ring.
Defined.

Global Instance VectorSpace_mixin_AbsRing :
  forall K (AK : AbsRing K), VectorSpace_mixin K K absring_group.
Proof.
  intros K AK.
  apply VectorSpace_mixin_Ring.
Defined.

Global Instance VectorSpace_AbsRing :
  forall K (AK : AbsRing K), VectorSpace K K.
Proof.
  intros K AK.
  eapply Build_VectorSpace.
  apply VectorSpace_mixin_AbsRing.
Defined.

(** Operations *)

Section VectorSpace.

Context {V K} {FK : Ring K} {VV : VectorSpace V K}.

Lemma scal_zero_r :
  forall x : K,
  scal x (@zero V _) = zero.
Proof.
intros x.
apply plus_reg_r with (scal x zero).
rewrite <- scal_distr_l.
rewrite plus_zero_r.
now rewrite plus_zero_l.
Qed.

Lemma scal_zero_l :
  forall u : V,
  scal zero u = zero.
Proof.
intros u.
apply plus_reg_r with (z := scal zero u).
rewrite plus_zero_l.
rewrite <- scal_distr_r.
now rewrite plus_zero_r.
Qed.

Lemma scal_opp_l :
  forall (x : K) (u : V),
  scal (opp x) u = opp (scal x u).
Proof.
intros x u.
apply plus_reg_r with (z := (scal x u)).
rewrite plus_opp_l.
rewrite <- scal_distr_r.
rewrite plus_opp_l.
apply scal_zero_l.
Qed.

Lemma scal_opp_r :
  forall (x : K) (u : V),
  scal x (opp u) = opp (scal x u).
Proof.
intros x u.
apply plus_reg_r with (z := (scal x u)).
rewrite plus_opp_l.
rewrite <- scal_distr_l.
rewrite plus_opp_l.
apply scal_zero_r.
Qed.

Lemma scal_opp_one :
  forall u : V,
  scal (opp one) u = opp u.
Proof.
intros u.
rewrite scal_opp_l.
now rewrite scal_one.
Qed.

Lemma sum_n_scal_l :
  forall (a : K) (u : nat -> V) (n : nat),
  sum_n (fun k => scal a (u k)) n = scal a (sum_n u n).
Proof.
  intros a u n.
  induction n ; simpl.
  by [].
  rewrite IHn.
  apply eq_sym.
  by apply scal_distr_l.
Qed.

End VectorSpace.

(** ** Normed Vector Space *)

Class NormedVectorSpace_mixin V K {FK : AbsRing K} (VS : VectorSpace V K) (MV : MetricBall V) := {
  norm : V -> R ;
  norm_triangle : forall (x y : V), norm (plus x y) <= norm x + norm y ;
  norm_scal : forall (l : K) (x : V), norm (scal l x) <= abs l * norm x ;
  norm_compat1 : forall (x y : V) (eps : R), norm (minus y x) < eps -> ball x eps y ;
  norm_compat2 : { M : posreal | forall (x y : V) (eps : posreal), ball x eps y -> norm (minus y x) < M * eps }
}.

Class NormedVectorSpace V K {FK : AbsRing K} := {
  nvspace_group :> AbelianGroup V ;
  nvspace_vector' :> VectorSpace_mixin V K nvspace_group ;
  nvspace_metric :> MetricBall V ;
  nvspace_vector := Build_VectorSpace V K _ _ nvspace_vector' ;
  nvspace_mixin :> NormedVectorSpace_mixin V K nvspace_vector nvspace_metric
}.

Global Existing Instance nvspace_vector.

(** Operations *)

Section NormedVectorSpace.

Context {V K} {FK : AbsRing K} {NVS : NormedVectorSpace V K}.

Lemma norm_zero :
  norm (@zero V _) = 0.
Proof.
apply Rle_antisym.
- rewrite -(scal_zero_l (VV := nvspace_vector) zero).
  rewrite -(Rmult_0_l (norm zero)).
  rewrite -abs_zero.
  apply norm_scal.
- apply Rplus_le_reg_r with (norm zero).
  rewrite Rplus_0_l.
  rewrite -{1}[zero]plus_zero_r.
  exact (norm_triangle zero zero).
Qed.

Lemma norm_opp :
  forall x : V,
  norm (opp x) = norm x.
Proof.
intros x.
apply Rle_antisym.
- rewrite -(scal_opp_one (VV := nvspace_vector)).
  rewrite -(Rmult_1_l (norm x)) -abs_opp_one.
  apply norm_scal.
- rewrite -{1}[x]opp_opp -(scal_opp_one (VV := nvspace_vector)).
  rewrite -(Rmult_1_l (norm (opp x))) -abs_opp_one.
  apply norm_scal.
Qed.

Lemma norm_ge_0 :
  forall x : V,
  0 <= norm x.
Proof.
  intros x.
  apply Rmult_le_reg_l with 2.
  by apply Rlt_0_2.
  rewrite Rmult_0_r -norm_zero -(plus_opp_r x).
  apply Rle_trans with (norm x + norm (opp x)).
  by apply (@norm_triangle V K).
  apply Req_le ; rewrite norm_opp.
  ring.
Qed.

Lemma norm_triangle_inv : forall (x y : V),
  Rabs (norm x - norm y) <= norm (minus x y).
Proof.
  intros x y.
  apply Rabs_le_between' ; split.
  rewrite -(norm_opp (minus _ _)).
  apply Rle_minus_l ; eapply Rle_trans.
  2 : apply norm_triangle.
  apply Req_le, f_equal.
  by rewrite /minus opp_plus plus_assoc plus_opp_r plus_zero_l opp_opp.
  eapply Rle_trans.
  2 : apply norm_triangle.
  apply Req_le, f_equal.
  by rewrite /minus plus_comm -plus_assoc plus_opp_l plus_zero_r.
Qed.

Definition ball_norm (x : V) (eps : R) (y : V) := norm (minus y x) < eps.

Definition locally_norm (x : V) (P : V -> Prop) :=
  exists eps : posreal, forall y, ball_norm x eps y -> P y.

Lemma locally_le_locally_norm :
  forall x, filter_le (locally x) (locally_norm x).
Proof.
destruct norm_compat2 as [M HM].
intros x P [eps H].
assert (He : 0 < / M * eps).
  apply Rmult_lt_0_compat.
  apply Rinv_0_lt_compat.
  apply cond_pos.
  apply cond_pos.
exists (mkposreal _ He).
intros y By.
apply H.
unfold ball_norm.
rewrite -(Rmult_1_l eps) -(Rinv_r M).
rewrite Rmult_assoc.
now apply (HM x y (mkposreal _ He)).
apply Rgt_not_eq.
apply cond_pos.
Qed.

Lemma locally_norm_le_locally :
  forall x, filter_le (locally_norm x) (locally x).
Proof.
intros x P [eps H].
exists eps.
intros y By.
apply H.
now apply norm_compat1.
Qed.

Lemma locally_norm_ball_norm :
  forall (x : V) (eps : posreal),
  locally_norm x (ball_norm x eps).
Proof.
intros x eps.
now exists eps.
Qed.

Lemma locally_norm_ball :
  forall (x : V) (eps : posreal),
  locally_norm x (ball x eps).
Proof.
intros x eps.
apply locally_norm_le_locally.
apply locally_ball.
Qed.

Lemma locally_ball_norm :
  forall (x : V) (eps : posreal),
  @locally V nvspace_metric x (ball_norm x eps).
Proof.
intros x eps.
apply locally_le_locally_norm.
apply locally_norm_ball_norm.
Qed.

End NormedVectorSpace.

(** Normed vector spaces have some continuous functions *)

Section NVS_continuity.

Context {V K} {FK : AbsRing K} {VV : NormedVectorSpace V K}.

Lemma filterlim_plus :
  forall x y : V,
  filterlim (fun z : V * V => plus (fst z) (snd z)) (filter_prod (locally x) (locally y)) (locally (plus x y)).
Proof.
intros x y.
apply (filterlim_filter_le_1 (F := filter_prod (locally_norm x) (locally_norm y))).
  intros P [Q R LQ LR H].
  exists Q R.
  now apply locally_le_locally_norm.
  now apply locally_le_locally_norm.
  exact H.
apply (filterlim_filter_le_2 (G := locally_norm (plus x y))).
  apply locally_norm_le_locally.
intros P [eps HP].
exists (ball_norm x (pos_div_2 eps)) (ball_norm y (pos_div_2 eps)).
by apply locally_norm_ball_norm.
by apply locally_norm_ball_norm.
intros u v Hu Hv.
apply HP.
rewrite /ball_norm /= (double_var eps).
apply Rle_lt_trans with (2 := Rplus_lt_compat _ _ _ _ Hu Hv).
apply Rle_trans with (2 := norm_triangle _ _).
apply Req_le, f_equal.
rewrite /minus /= opp_plus -2!plus_assoc.
apply f_equal.
rewrite 2!plus_assoc.
apply f_equal2.
by apply plus_comm.
by [].
Qed.

Lemma filterlim_scal :
  forall (k : K) (x : V),
  filterlim (fun z : V => scal k z) (locally x) (locally (scal k x)).
Proof.
intros k x.
apply (filterlim_filter_le_1 (F := locally_norm x)).
  apply locally_le_locally_norm.
apply (filterlim_filter_le_2 (G := locally_norm (scal k x))).
  apply locally_norm_le_locally.
intros P [eps HP].
assert (He : 0 < eps / (Rmax 1 (abs k))).
  apply Rdiv_lt_0_compat.
  by apply eps.
  apply Rlt_le_trans with (2 := Rmax_l _ _).
  by apply Rlt_0_1.
exists (mkposreal _ He) => /= y Hy.
apply HP.
unfold ball_norm.
replace (minus (scal k y) (scal k x)) with (scal k (minus y x)).
apply: Rle_lt_trans (norm_scal _ _) _.
apply Rle_lt_trans with (Rmax 1 (abs k) * norm (minus y x)).
apply Rmult_le_compat_r.
by apply norm_ge_0.
by apply Rmax_r.
rewrite Rmult_comm.
apply Rlt_div_r.
apply Rlt_le_trans with (2 := Rmax_l _ _).
by apply Rlt_0_1.
by [].
rewrite /minus scal_distr_l ;
by generalize (scal_opp_r k x) => <-.
Qed.

Lemma filterlim_opp :
  forall x : V,
  filterlim opp (locally x) (locally (opp x)).
Proof.
intros x.
rewrite -(scal_opp_one (VV := nvspace_vector)).
apply filterlim_ext with (2 := filterlim_scal _ _).
intros; apply (scal_opp_one (VV := nvspace_vector)).
Qed.

End NVS_continuity.

Lemma filterlim_locally_ball_norm :
  forall {K} {RK : AbsRing K} {T U} {VU : NormedVectorSpace U K} {F : (T -> Prop) -> Prop} {FF : Filter F} (f : T -> U) (y : U),
  filterlim f F (locally y) <-> forall eps : posreal, F (fun x => ball_norm y eps (f x)).
Proof.
intros K RK T U VU F FF f y.
split.
- intros Cf eps.
  apply (Cf (fun x => ball_norm y eps x)).
  apply locally_le_locally_norm.
  apply locally_norm_ball_norm.
- intros Cf.
  apply (filterlim_filter_le_2 _ (locally_norm_le_locally y)).
  intros P [eps He].
  apply: filter_imp (Cf eps).
  intros t.
  apply He.
Qed.

(** Rings with absolute values are normed vector spaces *)

Section NormedVectorSpace_AbsRing.

Context {K} {RK : AbsRing K}.

Global Instance NormedVectorSpace_mixin_AbsRing :
  NormedVectorSpace_mixin K K _ _.
Proof.
apply Build_NormedVectorSpace_mixin with abs.
- exact abs_triangle.
- exact abs_mult.
- now intros x P.
- exists (mkposreal _ Rlt_0_1).
  intros x y eps H.
  now rewrite Rmult_1_l.
Defined.

Global Instance NormedVectorSpace_AbsRing :
  NormedVectorSpace K K.
Proof.
  eapply Build_NormedVectorSpace.
  exact NormedVectorSpace_mixin_AbsRing.
Defined.

End NormedVectorSpace_AbsRing.

(** ** Complete Normed Vector Space *)

Class CompleteNormedVectorSpace V K {FK : AbsRing K} := {
  cnvspace_group :> AbelianGroup V ;
  cnvspace_vector' :> VectorSpace_mixin V K cnvspace_group ;
  cnvspace_vector := Build_VectorSpace _ _ _ _ cnvspace_vector' ;
  cnvspace_metric :> MetricBall V ;
  cnvspace_normed' :> NormedVectorSpace_mixin V K cnvspace_vector cnvspace_metric ;
  cnvspace_normed := Build_NormedVectorSpace _ _ _ _ cnvspace_vector' cnvspace_metric ;
  cnvspace_complete :> CompleteSpace_mixin V _
}.

Global Existing Instance cnvspace_vector.

Global Existing Instance cnvspace_normed.

(** * Extended Types *)

(** ** Pairs *)

Global Instance AbelianGroup_prod :
  forall {U V},
  AbelianGroup U -> AbelianGroup V
    -> AbelianGroup (U * V).
Proof.
intros U V GU GV.
apply (@Build_AbelianGroup _
  (fun x y : U * V => (plus (fst x) (fst y), plus (snd x) (snd y)))
  (fun x : U * V => (opp (fst x), opp (snd x)))
  (zero, zero)).
intros x y.
apply f_equal2 ; apply plus_comm.
intros x y z.
apply f_equal2 ; apply plus_assoc.
intros (x1,x2).
apply f_equal2 ; apply plus_zero_r.
intros x.
apply f_equal2 ; apply plus_opp_r.
Defined.

Global Instance MetricBall_prod :
  forall {T U}, MetricBall T -> MetricBall U -> MetricBall (T * U).
Proof.
intros T U MT MU.
apply (Build_MetricBall _ (fun x eps y => ball (fst x) eps (fst y) /\ ball (snd x) eps (snd y))).
- intros x eps ; split ; by apply ball_center.
- intros x y eps [H0 H1] ; split ; by apply ball_sym.
- intros x y z e1 e2 [H0 H1] [H2 H3] ; split ; eapply ball_triangle.
  by apply H0.
  by apply H2.
  by apply H1.
  by apply H3.
- intros x e1 e2 He y [H0 H1] ; split ; by apply ball_le with e1.
Defined.

Global Instance VectorSpace_mixin_prod :
  forall {U V K} {FK : Ring K} {GU GV}
    (VU : VectorSpace_mixin U K GU) (VV : VectorSpace_mixin V K GV),
      VectorSpace_mixin (U * V) K (AbelianGroup_prod GU GV).
Proof.
intros U V K FK GU GV VU VV.
apply (@Build_VectorSpace_mixin _ K FK (AbelianGroup_prod _ _)
  (fun (x : K) (uv : U * V) => (scal x (fst uv), scal x (snd uv)))).
intros x y u.
apply f_equal2 ; apply scal_assoc.
intros (u,v).
apply f_equal2 ; apply scal_one.
intros x u v.
simpl.
apply f_equal2 ; apply scal_distr_l.
intros x y u.
simpl.
apply f_equal2 ; apply scal_distr_r.
Defined.

Global Instance VectorSpace_prod :
  forall {U V K} {FK : Ring K} (VU : VectorSpace U K) (VV : VectorSpace V K),
  VectorSpace (U * V) K.
Proof.
intros U V K FK VU VV.
apply Build_VectorSpace with (AbelianGroup_prod _ _).
apply VectorSpace_mixin_prod.
by apply VU.
by apply VV.
Defined.

Lemma sqrt_plus_sqr :
  forall x y : R, Rmax (Rabs x) (Rabs y) <= sqrt (x ^ 2 + y ^ 2) <= sqrt 2 * Rmax (Rabs x) (Rabs y).
Proof.
intros x y.
split.
- rewrite -!sqrt_Rsqr_abs.
  apply Rmax_case ; apply sqrt_le_1_alt, Rminus_le_0 ;
  rewrite /Rsqr /= ; ring_simplify ; by apply pow2_ge_0.
- apply Rmax_case_strong ; intros H0 ;
  rewrite -!sqrt_Rsqr_abs ;
  rewrite -?sqrt_mult ;
  try (by apply Rle_0_sqr) ;
  try (by apply Rlt_le, Rlt_0_2) ;
  apply sqrt_le_1_alt ; simpl ; [ rewrite Rplus_comm | ] ;
  rewrite /Rsqr ; apply Rle_minus_r ; ring_simplify ;
  apply Rsqr_le_abs_1 in H0 ; by rewrite /pow !Rmult_1_r.
Qed.

Lemma NormedVectorSpace_mixin_prod_norm_triangle :
  forall {U V K} {FK : AbsRing K} (NU : NormedVectorSpace U K) (NV : NormedVectorSpace V K),
  forall x y : U * V,
  sqrt (norm (fst (plus x y)) ^ 2 + norm (snd (plus x y)) ^ 2) <=
    sqrt (norm (fst x) ^ 2 + norm (snd x) ^ 2) + sqrt (norm (fst y) ^ 2 + norm (snd y) ^ 2).
Proof.
intros U V K FK NU NV [xu xv] [yu yv].
simpl.
rewrite !Rmult_1_r.
apply Rle_trans with (sqrt (Rsqr (norm xu + norm yu) + Rsqr (norm xv + norm yv))).
- apply sqrt_le_1_alt.
  apply Rplus_le_compat.
  apply Rsqr_le_abs_1.
  rewrite -> 2!Rabs_pos_eq.
  apply: norm_triangle.
  apply Rplus_le_le_0_compat ; apply norm_ge_0.
  apply norm_ge_0.
  apply Rsqr_le_abs_1.
  rewrite -> 2!Rabs_pos_eq.
  apply: norm_triangle.
  apply Rplus_le_le_0_compat ; apply norm_ge_0.
  apply norm_ge_0.
- apply Rsqr_incr_0_var.
  apply Rminus_le_0.
  unfold Rsqr ; simpl ; ring_simplify.
  rewrite /pow ?Rmult_1_r.
  rewrite ?sqrt_sqrt ; ring_simplify.
  replace (-2 * norm xu * norm yu - 2 * norm xv * norm yv)
    with (-(2 * (norm xu * norm yu + norm xv * norm yv))) by ring.
  rewrite Rmult_assoc -sqrt_mult.
  rewrite Rplus_comm.
  apply -> Rminus_le_0.
  apply Rmult_le_compat_l.
  apply Rlt_le, Rlt_0_2.
  apply Rsqr_incr_0_var.
  apply Rminus_le_0.
  rewrite /Rsqr ?sqrt_sqrt ; ring_simplify.
  replace (norm xu ^ 2 * norm yv ^ 2 - 2 * norm xu * norm xv * norm yu * norm yv + norm xv ^ 2 * norm yu ^ 2)
    with ((norm xu * norm yv - norm xv * norm yu) ^ 2) by ring.
  apply pow2_ge_0.
  repeat apply Rplus_le_le_0_compat ; apply Rmult_le_pos ; apply pow2_ge_0.
  apply sqrt_pos.
  apply Rplus_le_le_0_compat ; apply Rle_0_sqr.
  apply Rplus_le_le_0_compat ; apply Rle_0_sqr.
  replace (norm xu ^ 2 + 2 * norm xu * norm yu + norm yu ^ 2 + norm xv ^ 2 + 2 * norm xv * norm yv + norm yv ^ 2)
    with ((norm xu + norm yu) ^ 2 + (norm xv + norm yv) ^ 2) by ring.
  apply Rplus_le_le_0_compat ; apply pow2_ge_0.
  apply Rplus_le_le_0_compat ; apply pow2_ge_0.
  apply Rplus_le_le_0_compat ; apply pow2_ge_0.
  apply Rplus_le_le_0_compat ; apply sqrt_pos.
Qed.

Lemma NormedVectorSpace_mixin_prod_norm_scal :
  forall {U V K} {FK : AbsRing K} (NU : NormedVectorSpace U K) (NV : NormedVectorSpace V K),
  forall (l : K) (x : U * V),
  sqrt (norm (fst (scal l x)) ^ 2 + norm (snd (scal l x)) ^ 2) <=
    abs l * sqrt (norm (fst x) ^ 2 + norm (snd x) ^ 2).
Proof.
intros U V K FK NU NV l [xu xv].
simpl.
rewrite -(sqrt_Rsqr (abs l)).
2: apply abs_ge_0.
rewrite !Rmult_1_r.
rewrite -sqrt_mult.
2: apply Rle_0_sqr.
apply sqrt_le_1_alt.
rewrite Rmult_plus_distr_l.
unfold Rsqr.
apply Rplus_le_compat.
replace (abs l * abs l * (norm xu * norm xu)) with ((abs l * norm xu) * (abs l * norm xu)) by ring.
apply Rmult_le_compat.
apply norm_ge_0.
apply norm_ge_0.
exact (norm_scal l xu).
exact (norm_scal l xu).
replace (abs l * abs l * (norm xv * norm xv)) with ((abs l * norm xv) * (abs l * norm xv)) by ring.
apply Rmult_le_compat.
apply norm_ge_0.
apply norm_ge_0.
exact (norm_scal l xv).
exact (norm_scal l xv).
apply Rplus_le_le_0_compat ; apply Rle_0_sqr.
Qed.

Lemma NormedVectorSpace_mixin_prod_norm_compat1 :
  forall {U V K} {FK : AbsRing K} (NU : NormedVectorSpace U K) (NV : NormedVectorSpace V K),
  forall (x y : U * V) (eps : R),
  sqrt (norm (fst (minus y x)) ^ 2 + norm (snd (minus y x)) ^ 2) < eps -> ball x eps y.
Proof.
intros U V K FK NU NV [xu xv] [yu yv] eps H.
generalize (Rle_lt_trans _ _ _ (proj1 (sqrt_plus_sqr _ _)) H).
rewrite -> !Rabs_pos_eq by apply norm_ge_0.
intros H'.
split ;
  apply norm_compat1 ;
  apply Rle_lt_trans with (2 := H').
apply Rmax_l.
apply Rmax_r.
Qed.

Lemma NormedVectorSpace_mixin_prod_norm_compat2 :
  forall {U V K} {FK : AbsRing K} (NU : NormedVectorSpace U K) (NV : NormedVectorSpace V K),
  { M : posreal | forall (x y : U * V) (eps : posreal),
    ball x eps y -> sqrt (norm (fst (minus y x)) ^ 2 + norm (snd (minus y x)) ^ 2) < M * eps }.
Proof.
intros U V K FK NU NV.
destruct (@norm_compat2 U K _ _ _ _) as [Mu Hu].
destruct (@norm_compat2 V K _ _ _ _) as [Mv Hv].
assert (H : 0 < sqrt 2 * Rmax Mu Mv).
  apply Rmult_lt_0_compat.
  apply sqrt_lt_R0.
  apply Rlt_0_2.
  apply Rmax_case ; apply cond_pos.
exists (mkposreal _ H).
intros [xu xv] [yu yv] eps [Bu Bv].
apply Rle_lt_trans with (1 := proj2 (sqrt_plus_sqr _ _)).
simpl.
rewrite Rmult_assoc.
apply Rmult_lt_compat_l.
apply sqrt_lt_R0.
apply Rlt_0_2.
rewrite -> !Rabs_pos_eq by apply norm_ge_0.
rewrite Rmax_mult.
apply Rmax_case.
apply Rlt_le_trans with (2 := Rmax_l _ _).
now apply Hu.
apply Rlt_le_trans with (2 := Rmax_r _ _).
now apply Hv.
apply Rlt_le.
apply cond_pos.
Qed.

Global Instance NormedVectorSpace_mixin_prod :
  forall {U V K} {FK : AbsRing K} (NU : NormedVectorSpace U K) (NV : NormedVectorSpace V K),
  NormedVectorSpace_mixin (U * V) K (VectorSpace_prod _ _) (MetricBall_prod _ _).
Proof.
intros U V K FK NU NV.
apply Build_NormedVectorSpace_mixin with (fun x => sqrt ((norm (fst x))^2 + (norm (snd x))^2)).
apply NormedVectorSpace_mixin_prod_norm_triangle.
apply NormedVectorSpace_mixin_prod_norm_scal.
apply NormedVectorSpace_mixin_prod_norm_compat1.
apply NormedVectorSpace_mixin_prod_norm_compat2.
Defined.

Global Instance NormedVectorSpace_prod :
  forall {U V K} {FK : AbsRing K} , 
  NormedVectorSpace U K -> NormedVectorSpace V K ->
  NormedVectorSpace (U * V) K.
Proof.
  intros U V K FK VU VV.
  eapply Build_NormedVectorSpace.
  apply NormedVectorSpace_mixin_prod.
Defined.

(** ** Iterated Products *)

Fixpoint Tn (n : nat) (T : Type) : Type :=
  match n with
  | O => unit
  | S n => prod T (Tn n T)
  end.

Fixpoint mk_Tn {T} (n : nat) (u : nat -> T) : Tn n T :=
  match n with
    | O => (tt : Tn O T)
    | S n => (u O, mk_Tn n (fun n => u (S n)))
  end.
Definition coeff_Tn {T} {n : nat} (x0 : T) (v : Tn n T) : nat -> T.
Proof.
  induction n ; simpl in v => i.
  apply x0.
  destruct i.
  apply (fst v).
  apply (IHn (snd v) i).
Defined.
Lemma mk_Tn_bij {T} {n : nat} (x0 : T) (v : Tn n T) :
  mk_Tn n (coeff_Tn x0 v) = v.
Proof.
  induction n ; simpl.
  now apply unit_ind.
  rewrite IHn ; by destruct v.
Qed.
Lemma coeff_Tn_bij {T} {n : nat} (x0 : T) (u : nat -> T) :
  forall i, (i < n)%nat -> coeff_Tn x0 (mk_Tn n u) i = u i.
Proof.
  revert u ; induction n => /= u i Hi.
  by apply lt_n_O in Hi.
  destruct i.
  by [].
  now apply (IHn (fun n => u (S n))), lt_S_n.
Qed.
Lemma coeff_Tn_ext {T} {n : nat} (x1 x2 : T) (v1 v2 : Tn n T) :
  v1 = v2 <-> forall i, (i < n)%nat -> coeff_Tn x1 v1 i = coeff_Tn x2 v2 i.
Proof.
  split.
  + move => -> {v1}.
    induction n => i Hi.
    by apply lt_n_O in Hi.
    destruct i ; simpl.
    by [].
    by apply IHn, lt_S_n.
  + induction n => H.
    apply unit_ind ; move: (v1) ; now apply unit_ind.
    apply injective_projections.
    by apply (H O), lt_O_Sn.
    apply IHn => i Hi.
    by apply (H (S i)), lt_n_S.
Qed.
Lemma mk_Tn_ext {T} (n : nat) (u1 u2 : nat -> T) :
  (forall i, (i < n)%nat -> (u1 i) = (u2 i))
    <-> (mk_Tn n u1) = (mk_Tn n u2).
Proof.
  move: u1 u2 ; induction n ; simpl ; split ; intros.
  by [].
  by apply lt_n_O in H0.
  apply f_equal2.
  by apply H, lt_O_Sn.
  apply IHn => i Hi.
  by apply H, lt_n_S.
  destruct i.
  by apply (f_equal (@fst _ _)) in H.
  move: i {H0} (lt_S_n _ _ H0).
  apply IHn.
  by apply (f_equal (@snd _ _)) in H.
Qed.

Global Instance AbelianGroup_Tn {T} :
  AbelianGroup T -> forall n, AbelianGroup (Tn n T) | 10.
Proof.
  intro GT.
  elim => /= [ | n IH].
  - apply Build_AbelianGroup with (fun _ _ => tt) (fun _ => tt) tt ; auto.
    by apply unit_ind.
  - by apply AbelianGroup_prod.
Defined.

Global Instance MetricBall_Tn :
  forall T, MetricBall T -> forall n, MetricBall (Tn n T) | 10.
Proof.
intros T MT n.
elim: n => [ | n MTn].
by apply Build_MetricBall with (fun _ _ _ => True).
by apply MetricBall_prod.
Defined.

Global Instance VectorSpace_mixin_Tn {T} {K} {FK : Ring K} :
  forall GT : AbelianGroup T,
  VectorSpace_mixin T K GT ->
  forall n, VectorSpace_mixin (Tn n T) K (AbelianGroup_Tn GT n) | 10.
Proof.
  intros GT VV.
  elim => [ | n VVn].
  apply Build_VectorSpace_mixin with (fun _ _ => tt) ; by apply unit_ind.
  by apply VectorSpace_mixin_prod.
Defined.

Global Instance VectorSpace_Tn {T} {K} {FK : Ring K} :
  VectorSpace T K -> forall n, VectorSpace (Tn n T) K | 10.
Proof.
  intros VV n.
  apply Build_VectorSpace with (AbelianGroup_Tn _ n).
  now apply VectorSpace_mixin_Tn, VV.
Defined.

Global Instance NormedVectorSpace_Tn {T} {K} {FK : AbsRing K} :
  NormedVectorSpace T K ->
  forall n, NormedVectorSpace (Tn n T) K | 10.
Proof.
  move => VT.
  elim => [ | n NVTn].
  - econstructor.
    apply Build_NormedVectorSpace_mixin with (fun _ => 0).
    move => _ _.
    rewrite Rplus_0_l ; by apply Rle_refl.
    move => l _ ; rewrite Rmult_0_r ; by apply Rle_refl.
    easy.
    exists (mkposreal _ Rlt_0_1).
    intros x y eps _.
    rewrite Rmult_1_l.
    apply cond_pos.
  - by apply NormedVectorSpace_prod.
Defined.

(** *)

Fixpoint Fn (n : nat) (T U : Type) : Type :=
  match n with
  | O => U
  | S n => T -> Fn n T U
  end.

Global Instance MetricBall_Fn {T M} (n : nat) :
  MetricBall M -> MetricBall (Fn n T M) | 10.
Proof.
  intros MM.
  elim: n => /= [ | n IHn].
  exact MM.
  exact (MetricBall_fct IHn).
Defined.

(** ** Matrices *)

Section Matrices.

Context {T : Type}.

Definition matrix (m n : nat) := Tn m (Tn n T).

Definition coeff_mat {m n : nat} (x0 : T) (A : matrix m n) (i j : nat) :=
  coeff_Tn x0 (coeff_Tn (mk_Tn _ (fun _ => x0)) A i) j.

Definition mk_matrix (m n : nat) (U : nat -> nat -> T) : matrix m n :=
  mk_Tn m (fun i => (mk_Tn n (U i))).

Lemma mk_matrix_bij {m n : nat} (x0 : T) (A : matrix m n) :
  mk_matrix m n (coeff_mat x0 A) = A.
Proof.
  unfold mk_matrix, coeff_mat.
  unfold matrix in A.
  rewrite -{2}(mk_Tn_bij (mk_Tn _ (fun _ => x0)) A).
  apply mk_Tn_ext.
  intros i Hi.
  by rewrite mk_Tn_bij.
Qed.

Lemma coeff_mat_bij {m n : nat} (x0 : T) (u : nat -> nat -> T) :
  forall i j, (i < m)%nat -> (j < n)%nat -> coeff_mat x0 (mk_matrix m n u) i j = u i j.
Proof.
  intros i j Hi Hj.
  unfold mk_matrix, coeff_mat.
  by rewrite 2?coeff_Tn_bij .
Qed.

Lemma coeff_mat_ext_aux {m n : nat} (x1 x2 : T) (v1 v2 : matrix m n) :
  v1 = v2 <-> forall i j, (i < m)%nat -> (j < n)%nat -> (coeff_mat x1 v1 i j) = (coeff_mat x2 v2 i j).
Proof.
  split => Hv.
  + move => i j Hi Hj.
    by repeat apply coeff_Tn_ext.
  + unfold matrix in v1, v2.
    rewrite -(mk_matrix_bij x1 v1) -(mk_matrix_bij x2 v2).
    unfold mk_matrix.
    apply mk_Tn_ext => i Hi.
    apply mk_Tn_ext => j Hj.
    by apply Hv.
Qed.

Lemma coeff_mat_ext {m n : nat} (x0 : T) (v1 v2 : matrix m n) :
  v1 = v2 <-> forall i j, (coeff_mat x0 v1 i j) = (coeff_mat x0 v2 i j).
Proof.
  split.
  by move => ->.
  intro H.
  now apply (coeff_mat_ext_aux x0 x0 v1 v2).
Qed.

Lemma mk_matrix_ext (m n : nat) (u1 u2 : nat -> nat -> T) :
  (forall i j, (i < m)%nat -> (j < n)%nat -> (u1 i j) = (u2 i j))
    <-> (mk_matrix m n u1) = (mk_matrix m n u2).
Proof.
  split => H.
  + apply (mk_Tn_ext m) => i Hi.
    apply (mk_Tn_ext n) => j Hj.
    by apply H.
  + intros i j Hi Hj.
    apply (mk_Tn_ext n).
    apply (mk_Tn_ext m (fun i => mk_Tn n (u1 i)) (fun i => mk_Tn n (u2 i))).
    apply H.
    by [].
    by [].
Qed.

Section MatrixGroup.

Context {GT : AbelianGroup T}.

Definition Mzero {m n} := mk_matrix m n (fun i j => @zero T GT).

Definition Mplus {m n} (A B : matrix m n) :=
  mk_matrix m n (fun i j => plus (coeff_mat zero A i j) (coeff_mat zero B i j)).

Definition Mopp {m n} (A : matrix m n) :=
  mk_matrix m n (fun i j => opp (coeff_mat zero A i j)).

End MatrixGroup.

Global Instance AbelianGroup_matrix :
  AbelianGroup T -> forall m n, AbelianGroup (matrix m n).
Proof.
  intros GT m n.
  apply Build_AbelianGroup with Mplus Mopp Mzero.
  + move => A B.
    apply mk_matrix_ext => i j Hi Hj.
    by apply plus_comm.
  + move => A B C.
    apply mk_matrix_ext => /= i j Hi Hj.
    rewrite ?coeff_mat_bij => //.
    by apply plus_assoc.
  + move => A.
    apply (coeff_mat_ext_aux zero zero) => i j Hi Hj.
    rewrite ?coeff_mat_bij => //=.
    by apply plus_zero_r.
  + move => A.
    apply (coeff_mat_ext_aux zero zero) => i j Hi Hj.
    rewrite ?coeff_mat_bij => //=.
    by apply plus_opp_r.
Defined.

Section MatrixRing.

Context {RT : Ring T}.

Fixpoint Mone_seq i j : T :=
  match i,j with
    | O, O => one
    | O, S _ | S _, O => zero
    | S i, S j => Mone_seq i j end.

Definition Mone {n} : matrix n n :=
  mk_matrix n n Mone_seq.

Definition Mmult {n m k} (A : matrix n m) (B : matrix m k) :=
  mk_matrix n k (fun i j => sum_n (fun l => mult (coeff_mat zero A i l) (coeff_mat zero B l j)) (pred m)).

Lemma Mmult_assoc {n m k l} :
  forall (A : matrix n m) (B : matrix m k) (C : matrix k l),
  Mmult A (Mmult B C) = Mmult (Mmult A B) C.
Proof.
  intros A B C.
  apply mk_matrix_ext => n' l' Hn' Hl'.
  unfold Mmult at 1.
  - transitivity (sum_n (fun l0 : nat => mult (coeff_mat zero A n' l0)
      (sum_n (fun l1 : nat => mult (coeff_mat zero B l0 l1) (coeff_mat zero C l1 l')) (pred k))) (pred m)).
    destruct m ; simpl.
    unfold coeff_mat ; simpl.
    by rewrite 2!mult_zero_l.
    apply sum_n_ext_aux ; simpl => m' Hm'.
    apply f_equal.
    by rewrite coeff_mat_bij.
  - transitivity (sum_n (fun l0 : nat => sum_n
      (fun l1 : nat => mult (coeff_mat zero A n' l0) (mult (coeff_mat zero B l0 l1) (coeff_mat zero C l1 l'))) (pred k)) (pred m)).
    destruct m ; simpl.
    unfold coeff_mat ; simpl.
    rewrite mult_zero_l.
    rewrite sum_n_mult_l.
    by rewrite mult_zero_l.
    apply sum_n_ext_aux ; simpl => m' Hm'.
    apply sym_eq, sum_n_mult_l.
  rewrite sum_n_switch.
  destruct k ; simpl.
  unfold coeff_mat ; simpl.
  rewrite mult_zero_l.
  rewrite sum_n_mult_r.
  by rewrite mult_zero_r.
  apply sum_n_ext_aux => k' Hk'.
  transitivity (mult (sum_n (fun l1 : nat => mult (coeff_mat zero A n' l1) (coeff_mat zero B l1 k')) (pred m))
    (coeff_mat zero C k' l')).
  rewrite -sum_n_mult_r.
  apply sum_n_ext_aux => m' Hm'.
  apply mult_assoc.
  apply f_equal2.
  now unfold Mmult ; rewrite coeff_mat_bij.
  by [].
Qed.

Lemma Mmult_one_r {m n} :
  forall x : matrix m n, Mmult x Mone = x.
Proof.
  intros A.
  rewrite -{2}(mk_matrix_bij zero A).
  apply mk_matrix_ext => /= i j Hi Hj.
  destruct n ; simpl.
  by apply lt_n_O in Hj.
  move: (coeff_mat zero A) => {A} A.
  unfold Mone ; simpl.
  transitivity (sum_n (fun k : nat => mult (A i k)
    (Mone_seq k j)) n).
  apply sum_n_ext_aux => /= k Hk.
  now rewrite coeff_mat_bij.
  - elim: n Hj => [ | n IH] Hj ; rewrite /sum_n -/sum_n.
    apply lt_n_Sm_le, le_n_0_eq in Hj.
    rewrite -Hj => {j Hj} /=.
    by apply mult_one_r.
  - apply le_lt_eq_dec in Hj ; case: Hj => Hj.
    replace (Mone_seq (S n) j : T) with (zero : T).
    rewrite mult_zero_r plus_zero_r.
    apply lt_n_Sm_le in Hj.
    by apply IH.
    apply lt_S_n in Hj.
    clear -Hj ;
    elim: n j Hj => [ | n IH] ;
    case => [ | j] //= Hj.
    by apply lt_S_n, lt_n_O in Hj.
    by apply IH, lt_S_n.
  - apply eq_add_S in Hj.
    rewrite Hj => /= {j Hj IH}.
    replace (Mone_seq n n : T) with (one : T).
    rewrite mult_one_r.
    apply plus_reg_r with (opp (A i (S n))).
    rewrite -plus_assoc plus_opp_r plus_zero_r.
  - elim: n (S n) (lt_n_Sn n) => {m Hi} [ | n IH] m Hm ;
    rewrite /sum_n -/sum_n.
    destruct m.
    by apply lt_n_O in Hm.
    by apply mult_zero_r.
    replace (Mone_seq (S n) m : T) with (zero : T).
    rewrite mult_zero_r plus_zero_r.
    apply IH.
    by apply lt_trans with (1 := lt_n_Sn _).
    clear -Hm ; destruct m.
    by [].
    apply lt_S_n in Hm.
    elim: n m Hm => [ | n IH] ;
    case => [ | m] Hm //=.
    by apply lt_n_O in Hm.
    apply IH.
    by apply lt_S_n.
    by elim: n.
Qed.
Lemma Mmult_one_l {m n} :
  forall x : matrix m n, Mmult Mone x = x.
Proof.
  intros A.
  rewrite -{2}(mk_matrix_bij zero A).
  apply mk_matrix_ext => /= i j Hi Hj.
  destruct m ; simpl.
  by apply lt_n_O in Hi.
  move: (coeff_mat zero A) => {A} A.
  unfold Mone ; simpl.
  transitivity (sum_n (fun k : nat => mult
    (Mone_seq i k) (A k j)) m).
  apply sum_n_ext_aux => /= k Hk.
  now rewrite coeff_mat_bij.
  - elim: m Hi => [ | m IH] Hi ; rewrite /sum_n -/sum_n.
    apply lt_n_Sm_le, le_n_0_eq in Hi.
    rewrite -Hi => {i Hi} /=.
    by apply mult_one_l.
  - apply le_lt_eq_dec in Hi ; case: Hi => Hi.
    replace (Mone_seq i (S m) : T) with (zero : T).
    rewrite mult_zero_l plus_zero_r.
    apply lt_n_Sm_le in Hi.
    by apply IH.
    apply lt_S_n in Hi.
    clear -Hi ;
    elim: (S m) i Hi => {m} [ | m IH] ;
    case => [ | i] //= Hi.
    by apply lt_n_O in Hi.
    by apply IH, lt_S_n.
  - apply eq_add_S in Hi.
    rewrite Hi => /= {i Hi IH}.
    replace (Mone_seq m m : T) with (one : T).
    rewrite mult_one_l.
    apply plus_reg_r with (opp (A (S m) j)).
    rewrite -plus_assoc plus_opp_r plus_zero_r.
  - elim: m {2 3}(m) (le_refl m) => {n Hj} [ | n IH] m Hm ;
    rewrite /sum_n -/sum_n.
    by apply mult_zero_l.
    replace (Mone_seq m n : T) with (zero : T).
    rewrite mult_zero_l plus_zero_r.
    apply IH.
    by apply le_trans with (1 := le_n_Sn _).
    clear -Hm ; destruct m.
    by apply le_Sn_O in Hm.
    apply le_S_n in Hm.
    elim: n m Hm => [ | n IH] ;
    case => [ | m] Hm //=.
    by apply le_Sn_O in Hm.
    apply IH.
    by apply le_S_n.
    by elim: m.
Qed.

Lemma Mmult_distr_r {m n k} :
  forall (A B : matrix m n) (C : matrix n k),
  Mmult (plus A B) C = plus (Mmult A C) (Mmult B C).
Proof.
  intros A B C.
  unfold Mmult, plus ; simpl ; unfold Mplus.
  apply mk_matrix_ext => i j Hi Hj.
  rewrite ?coeff_mat_bij => //=.
  rewrite -sum_n_plus.
  destruct n ; simpl.
  unfold coeff_mat ; simpl.
  by rewrite ?mult_zero_l plus_zero_l.
  apply sum_n_ext_aux => l Hl.
  rewrite ?coeff_mat_bij => //=.
  by apply mult_distr_r.
Qed.

Lemma Mmult_distr_l {m n k} :
  forall (A : matrix m n) (B C : matrix n k),
  Mmult A (plus B C) = plus (Mmult A B) (Mmult A C).
Proof.
  intros A B C.
  unfold Mmult, plus ; simpl ; unfold Mplus.
  apply mk_matrix_ext => i j Hi Hj.
  rewrite ?coeff_mat_bij => //=.
  rewrite -sum_n_plus.
  destruct n ; simpl.
  unfold coeff_mat ; simpl.
  by rewrite ?mult_zero_l plus_zero_l.
  apply sum_n_ext_aux => l Hl.
  rewrite ?coeff_mat_bij => //=.
  by apply mult_distr_l.
Qed.

End MatrixRing.

Global Instance Ring_matrix {n} :
  Ring T -> Ring (matrix n n) | 10.
Proof.
  intros RT.
  apply Build_Ring with (AbelianGroup_matrix _ _ _).
  apply Build_Ring_mixin with Mmult Mone.
  + by apply Mmult_assoc.
  + by apply Mmult_one_r.
  + by apply Mmult_one_l.
  + by apply Mmult_distr_r.
  + by apply Mmult_distr_l.
Defined.

Global Instance ModuleSpace_matrix {m n} :
  forall RT : Ring T, VectorSpace (matrix m n) (matrix m m).
Proof.
  intros RT.
  apply Build_VectorSpace with (AbelianGroup_matrix _ _ _).
  apply Build_VectorSpace_mixin with Mmult.
  + by apply Mmult_assoc.
  + by apply Mmult_one_l.
  + by apply Mmult_distr_l.
  + by apply Mmult_distr_r.
Defined.

End Matrices.

(** * The topology on natural numbers *)

Definition eventually (P : nat -> Prop) :=
  exists N : nat, forall n, (N <= n)%nat -> P n.

Global Instance eventually_filter : ProperFilter eventually.
Proof.
constructor.
  intros P [N H].
  exists N.
  apply H.
  apply le_refl.
constructor.
- now exists 0%nat.
- intros P Q [NP HP] [NQ HQ].
  exists (max NP NQ).
  intros n Hn.
  split.
  apply HP.
  apply le_trans with (2 := Hn).
  apply Max.le_max_l.
  apply HQ.
  apply le_trans with (2 := Hn).
  apply Max.le_max_r.
- intros P Q H [NP HP].
  exists NP.
  intros n Hn.
  apply H.
  now apply HP.
Qed.

(** * The topology on real numbers *)

Global Instance R_abelian_group : AbelianGroup R.
Proof.
apply (@Build_AbelianGroup R Rplus Ropp R0).
apply Rplus_comm.
intros x y z.
apply sym_eq, Rplus_assoc.
apply Rplus_0_r.
apply Rplus_opp_r.
Defined.

Global Instance R_ring_mixin : Ring_mixin R R_abelian_group.
Proof.
  econstructor => /=.
  move => x y z ; apply eq_sym, Rmult_assoc.
  exact Rmult_1_r.
  exact Rmult_1_l.
  exact Rmult_plus_distr_r.
  exact Rmult_plus_distr_l.
Defined.

Global Instance R_absring_mixin : AbsRing_mixin R (Build_Ring _ R_abelian_group R_ring_mixin).
Proof.
  apply Build_AbsRing_mixin with Rabs ; simpl.
  exact Rabs_R0.
  rewrite Rabs_Ropp ; exact Rabs_R1.
  exact Rabs_triang.
  intros x y.
  apply Req_le.
  apply Rabs_mult.
Defined.

Global Instance R_absring : AbsRing R.
Proof.
  apply Build_AbsRing with R_abelian_group R_ring_mixin.
  exact R_absring_mixin.
Defined.

Lemma R_complete :
  forall F : (R -> Prop) -> Prop,
  ProperFilter F ->
  (forall eps : posreal, exists x : R, F (ball x eps)) ->
  {x : R | forall eps :posreal, F (ball x eps)}.
Proof.
intros F FF HF.
set (E := fun x : R => F (ball x (mkposreal _ Rlt_0_1))).
destruct (completeness E) as [x [Hx1 Hx2]].
  destruct (HF (mkposreal _ Rlt_0_1)) as [y Fy].
  exists (y + 2).
  intros x Fx.
  apply filter_const.
  generalize (filter_and _ _ Fy Fx).
  apply filter_imp.
  intros z [Hz1 Hz2].
  apply Rplus_le_reg_r with (-y).
  replace (y + 2 + -y) with 2 by ring.
  apply Rabs_le_between.
  apply Rlt_le.
  generalize (ball_triangle y z x 1 1) => /= H.
  apply H.
  apply Hz1.
  apply ball_sym in Hz2.
  apply Hz2.
  destruct (HF (mkposreal _ Rlt_0_1)) as [y Fy].
  now exists y.
exists (x - 1).
intros eps.
set (eps' := pos_div_2 (mkposreal _ (Rmin_case _ _ _ Rlt_R0_R2 (cond_pos eps)))).
destruct (HF eps') as [z Hz].
assert (H1 : z - Rmin 2 eps / 2 + 1 <= x).
  apply Hx1.
  revert Hz.
  unfold E.
  apply filter_imp.
  simpl ; intros u Bu.
  apply (Rabs_lt_between' u z) in Bu.
  apply Rabs_lt_between'.
  clear -Bu.
  destruct Bu as [Bu1 Bu2].
  assert (H := Rmin_l 2 eps).
  split ; Fourier.fourier.
assert (H2 : x <= z + Rmin 2 eps / 2 + 1).
  apply Hx2.
  intros v Hv.
  apply filter_const.
  generalize (filter_and _ _ Hz Hv).
  apply filter_imp.
  simpl ; intros w [Hw1 Hw2].
  apply (Rabs_lt_between' w z) in Hw1.
  destruct Hw1 as [_ Hw1].
  apply (Rabs_lt_between' w v) in Hw2.
  destruct Hw2 as [Hw2 _].
  clear -Hw1 Hw2.
  simpl in Hw1, Hw2.
  Fourier.fourier.
revert Hz.
apply filter_imp.
simpl ; intros u Hu.
apply (Rabs_lt_between' u z) in Hu.
apply Rabs_lt_between'.
assert (H3 := Rmin_l 2 eps).
assert (H4 := Rmin_r 2 eps).
clear -H1 H2 Hu H3 H4.
destruct Hu.
split ; Fourier.fourier.
Qed.

Global Instance R_complete_metric : CompleteSpace R.
Proof.
apply (Build_CompleteSpace R _).
constructor.
apply R_complete.
Defined.

Notation at_left x := (within (fun u : R => Rlt u x) (locally (x)%R)).
Notation at_right x := (within (fun u : R => Rlt x u) (locally (x)%R)).

(** Continuity of norm *)

Lemma filterlim_norm {V K} {FK : AbsRing K} {VV : NormedVectorSpace V K} :
  forall (x : V), filterlim norm (locally x) (locally (norm x)).
Proof.
  intros x.
  apply (filterlim_filter_le_1 _ (locally_le_locally_norm x)).
  apply filterlim_locally => eps /=.
  exists eps ; move => /= y Hy.
  apply Rle_lt_trans with (2 := Hy).
  apply norm_triangle_inv.
Qed.

(** Some open sets of [R] *)

Lemma open_lt :
  forall y : R, open (fun u : R => u < y).
Proof.
intros y x Hxy.
apply Rminus_lt_0 in Hxy.
exists (mkposreal _ Hxy).
intros z Bz.
replace y with (x + (y - x)) by ring.
apply Rabs_lt_between'.
apply Bz.
Qed.

Lemma open_gt :
  forall y : R, open (fun u : R => y < u).
Proof.
intros y x Hxy.
apply Rminus_lt_0 in Hxy.
exists (mkposreal _ Hxy).
intros z Bz.
replace y with (x - (x - y)) by ring.
apply Rabs_lt_between'.
apply Bz.
Qed.

Lemma open_neq :
  forall y : R, open (fun u : R => u <> y).
Proof.
intros y.
apply (open_ext (fun u => u < y \/ y < u)).
intros u.
split.
apply Rlt_dichotomy_converse.
apply Rdichotomy.
apply open_or.
apply open_lt.
apply open_gt.
Qed.

(** Local properties in [R] *)

Lemma locally_interval (P : R -> Prop) (x : R) (a b : Rbar) :
  Rbar_lt a x -> Rbar_lt x b ->
  (forall (y : R), Rbar_lt a y -> Rbar_lt y b -> P y) ->
  locally x P.
Proof.
  move => Hax Hxb Hp.
  case: (Rbar_lt_locally _ _ _ Hax Hxb) => d Hd.
  exists d => y Hy.
  now apply Hp ; apply Hd.
Qed.

(** * Topology on [R]² *)

Definition locally_2d (P : R -> R -> Prop) x y :=
  exists delta : posreal, forall u v, Rabs (u - x) < delta -> Rabs (v - y) < delta -> P u v.

Lemma locally_2d_locally :
  forall P x y,
  locally_2d P x y <-> locally (x,y) (fun z => P (fst z) (snd z)).
Proof.
intros P x y.
split ; intros [d H] ; exists d.
- simpl.
  intros [u v] H'.
  now apply H ; apply H'.
- intros u v Hu Hv.
  apply (H (u,v)).
  by split.
Qed.

Lemma locally_2d_locally' :
  forall P x y,
  locally_2d P x y <-> locally ((x,(y,tt)) : Tn 2 R) (fun z : Tn 2 R => P (fst z) (fst (snd z))).
Proof.
intros P x y.
split ; intros [d H] ; exists d.
- move => [u [v _]] /= [H1 [H2 _]].
  now apply H.
- intros u v Hu Hv.
  now apply (H (u,(v,tt))) ; repeat split.
Qed.

Lemma locally_2d_impl_strong :
  forall (P Q : R -> R -> Prop) x y, locally_2d (fun u v => locally_2d P u v -> Q u v) x y ->
  locally_2d P x y -> locally_2d Q x y.
Proof.
intros P Q x y Li LP.
apply locally_2d_locally in Li.
apply locally_2d_locally in LP.
apply locally_locally in LP.
apply locally_2d_locally.
generalize (filter_and _ _ Li LP).
apply filter_imp.
intros [u v] [H1 H2].
apply H1.
now apply locally_2d_locally.
Qed.

Lemma locally_2d_singleton :
  forall (P : R -> R -> Prop) x y, locally_2d P x y -> P x y.
Proof.
intros P x y LP.
apply locally_2d_locally in LP.
apply locally_singleton with (1 := LP).
Qed.

Lemma locally_2d_impl :
  forall (P Q : R -> R -> Prop) x y, locally_2d (fun u v => P u v -> Q u v) x y ->
  locally_2d P x y -> locally_2d Q x y.
Proof.
intros P Q x y (d,H).
apply locally_2d_impl_strong.
exists d => u v Hu Hv Hp.
apply H => //.
now apply locally_2d_singleton.
Qed.

Lemma locally_2d_forall :
  forall (P : R -> R -> Prop) x y, (forall u v, P u v) -> locally_2d P x y.
Proof.
intros P x y Hp.
now exists (mkposreal _ Rlt_0_1) => u v _ _.
Qed.

Lemma locally_2d_and :
  forall (P Q : R -> R -> Prop) x y, locally_2d P x y -> locally_2d Q x y ->
  locally_2d (fun u v => P u v /\ Q u v) x y.
Proof.
intros P Q x y H.
apply: locally_2d_impl.
apply: locally_2d_impl H.
apply locally_2d_forall.
now split.
Qed.

Lemma locally_2d_align :
  forall (P Q : R -> R -> Prop) x y,
  ( forall eps : posreal, (forall u v, Rabs (u - x) < eps -> Rabs (v - y) < eps -> P u v) ->
    forall u v, Rabs (u - x) < eps -> Rabs (v - y) < eps -> Q u v ) ->
  locally_2d P x y -> locally_2d Q x y.
Proof.
intros P Q x y K (d,H).
exists d => u v Hu Hv.
now apply (K d).
Qed.

Lemma locally_2d_1d_const_x :
  forall (P : R -> R -> Prop) x y,
  locally_2d P x y ->
  locally y (fun t => P x t).
Proof.
intros P x y (d,Hd).
exists d; intros z Hz.
apply Hd.
rewrite Rminus_eq_0 Rabs_R0; apply cond_pos.
exact Hz.
Qed.

Lemma locally_2d_1d_const_y :
  forall (P : R -> R -> Prop) x y,
  locally_2d P x y ->
  locally x (fun t => P t y).
Proof.
intros P x y (d,Hd).
exists d; intros z Hz.
apply Hd.
exact Hz.
rewrite Rminus_eq_0 Rabs_R0; apply cond_pos.
Qed.

Lemma locally_2d_1d_strong :
  forall (P : R -> R -> Prop) x y,
  locally_2d P x y ->
  locally_2d (fun u v => forall t, 0 <= t <= 1 ->
    locally t (fun z => locally_2d P (x + z * (u - x)) (y + z * (v - y)))) x y.
Proof.
intros P x y.
apply locally_2d_align => eps HP u v Hu Hv t Ht.
assert (Zm: 0 <= Rmax (Rabs (u - x)) (Rabs (v - y))).
apply Rmax_case ; apply Rabs_pos.
destruct Zm as [Zm|Zm].
(* *)
assert (H1: Rmax (Rabs (u - x)) (Rabs (v - y)) < eps).
now apply Rmax_case.
set (d1 := mkposreal _ (Rlt_Rminus _ _ H1)).
assert (H2: 0 < pos_div_2 d1 / Rmax (Rabs (u - x)) (Rabs (v - y))).
apply Rmult_lt_0_compat.
apply cond_pos.
now apply Rinv_0_lt_compat.
set (d2 := mkposreal _ H2).
exists d2 => z Hz.
exists (pos_div_2 d1) => p q Hp Hq.
apply HP.
(* . *)
replace (p - x) with (p - (x + z * (u - x)) + (z - t + t) * (u - x)) by ring.
apply Rle_lt_trans with (1 := Rabs_triang _ _).
replace (pos eps) with (pos_div_2 d1 + (eps - pos_div_2 d1)) by ring.
apply Rplus_lt_le_compat with (1 := Hp).
rewrite Rabs_mult.
apply Rle_trans with ((d2 + 1) * Rmax (Rabs (u - x)) (Rabs (v - y))).
apply Rmult_le_compat.
apply Rabs_pos.
apply Rabs_pos.
apply Rle_trans with (1 := Rabs_triang _ _).
apply Rplus_le_compat.
now apply Rlt_le.
now rewrite Rabs_pos_eq.
apply Rmax_l.
rewrite /d2 /d1 /=.
field_simplify.
apply Rle_refl.
now apply Rgt_not_eq.
(* . *)
replace (q - y) with (q - (y + z * (v - y)) + (z - t + t) * (v - y)) by ring.
apply Rle_lt_trans with (1 := Rabs_triang _ _).
replace (pos eps) with (pos_div_2 d1 + (eps - pos_div_2 d1)) by ring.
apply Rplus_lt_le_compat with (1 := Hq).
rewrite Rabs_mult.
apply Rle_trans with ((d2 + 1) * Rmax (Rabs (u - x)) (Rabs (v - y))).
apply Rmult_le_compat.
apply Rabs_pos.
apply Rabs_pos.
apply Rle_trans with (1 := Rabs_triang _ _).
apply Rplus_le_compat.
now apply Rlt_le.
now rewrite Rabs_pos_eq.
apply Rmax_r.
rewrite /d2 /d1 /=.
field_simplify.
apply Rle_refl.
now apply Rgt_not_eq.
(* *)
apply filter_forall => z.
exists eps => p q.
replace (u - x) with 0.
replace (v - y) with 0.
rewrite Rmult_0_r 2!Rplus_0_r.
apply HP.
apply sym_eq.
apply Rabs_eq_0.
apply Rle_antisym.
rewrite Zm.
apply Rmax_r.
apply Rabs_pos.
apply sym_eq.
apply Rabs_eq_0.
apply Rle_antisym.
rewrite Zm.
apply Rmax_l.
apply Rabs_pos.
Qed.

Lemma locally_2d_1d :
  forall (P : R -> R -> Prop) x y,
  locally_2d P x y ->
  locally_2d (fun u v => forall t, 0 <= t <= 1 -> locally_2d P (x + t * (u - x)) (y + t * (v - y))) x y.
Proof.
intros P x y H.
apply locally_2d_1d_strong in H.
apply: locally_2d_impl H.
apply locally_2d_forall => u v H t Ht.
specialize (H t Ht).
apply locally_singleton with (1 := H).
Qed.

Lemma locally_2d_ex_dec :
  forall P x y,
  (forall x y, P x y \/ ~P x y) ->
  locally_2d P x y ->
  {d : posreal | forall u v, Rabs (u-x) < d -> Rabs (v-y) < d -> P u v}.
Proof.
intros P x y P_dec H.
destruct (locally_ex_dec (x, y) (fun z => P (fst z) (snd z))) as [d Hd].
- now intros [u v].
- destruct H as [e H].
  exists e.
  intros [u v] Huv.
  apply H.
  apply Huv.
  apply Huv.
exists d.
intros u v Hu Hv.
apply (Hd (u, v)).
simpl.
now split.
Qed.

(** * Some Topology on [Rbar] *)

Definition Rbar_locally' (a : Rbar) (P : R -> Prop) :=
  match a with
    | Finite a => locally' a P
    | p_infty => exists M : R, forall x, M < x -> P x
    | m_infty => exists M : R, forall x, x < M -> P x
  end.
Definition Rbar_locally (a : Rbar) (P : R -> Prop) :=
  match a with
    | Finite a => locally a P
    | p_infty => exists M : R, forall x, M < x -> P x
    | m_infty => exists M : R, forall x, x < M -> P x
  end.

Global Instance Rbar_locally'_filter :
  forall x, ProperFilter (Rbar_locally' x).
Proof.
intros [x| |] ; (constructor ; [idtac | constructor]).
- intros P [eps HP].
  exists (x + eps / 2).
  apply HP.
  unfold ball ; simpl.
  ring_simplify (x + eps / 2 + - x).
  rewrite Rabs_pos_eq.
  apply Rminus_lt_0.
  replace (eps - eps / 2) with (eps / 2) by field.
  apply is_pos_div_2.
  apply Rlt_le, is_pos_div_2.
  apply Rgt_not_eq, Rminus_lt_0 ; ring_simplify.
  apply is_pos_div_2.
- now exists (mkposreal _ Rlt_0_1).
- intros P Q [dP HP] [dQ HQ].
  exists (mkposreal _ (Rmin_stable_in_posreal dP dQ)).
  simpl.
  intros y Hy H.
  split.
  apply HP with (2 := H).
  apply Rlt_le_trans with (1 := Hy).
  apply Rmin_l.
  apply HQ with (2 := H).
  apply Rlt_le_trans with (1 := Hy).
  apply Rmin_r.
- intros P Q H [dP HP].
  exists dP.
  intros y Hy H'.
  apply H.
  now apply HP.
- intros P [N HP].
  exists (N + 1).
  apply HP.
  apply Rlt_plus_1.
- now exists 0.
- intros P Q [MP HP] [MQ HQ].
  exists (Rmax MP MQ).
  intros y Hy.
  split.
  apply HP.
  apply Rle_lt_trans with (2 := Hy).
  apply Rmax_l.
  apply HQ.
  apply Rle_lt_trans with (2 := Hy).
  apply Rmax_r.
- intros P Q H [dP HP].
  exists dP.
  intros y Hy.
  apply H.
  now apply HP.
- intros P [N HP].
  exists (N - 1).
  apply HP.
  apply Rlt_minus_l, Rlt_plus_1.
- now exists 0.
- intros P Q [MP HP] [MQ HQ].
  exists (Rmin MP MQ).
  intros y Hy.
  split.
  apply HP.
  apply Rlt_le_trans with (1 := Hy).
  apply Rmin_l.
  apply HQ.
  apply Rlt_le_trans with (1 := Hy).
  apply Rmin_r.
- intros P Q H [dP HP].
  exists dP.
  intros y Hy.
  apply H.
  now apply HP.
Qed.

Global Instance Rbar_locally_filter :
  forall x, ProperFilter (Rbar_locally x).
Proof.
intros [x| |].
- apply locally_filter.
- exact (Rbar_locally'_filter p_infty).
- exact (Rbar_locally'_filter m_infty).
Qed.

(** Open sets in [Rbar] *)

Lemma open_Rbar_lt :
  forall y, open (fun u : R => Rbar_lt u y).
Proof.
intros [y| |].
- apply open_lt.
- apply open_true.
- apply open_false.
Qed.

Lemma open_Rbar_gt :
  forall y, open (fun u : R => Rbar_lt y u).
Proof.
intros [y| |].
- apply open_gt.
- apply open_false.
- apply open_true.
Qed.

Lemma open_Rbar_lt' :
  forall x y, Rbar_lt x y -> Rbar_locally x (fun u => Rbar_lt u y).
Proof.
intros [x| |] y Hxy.
- now apply open_Rbar_lt.
- easy.
- destruct y as [y| |].
  now exists y.
  now apply filter_forall.
  easy.
Qed.

Lemma open_Rbar_gt' :
  forall x y, Rbar_lt y x -> Rbar_locally x (fun u => Rbar_lt y u).
Proof.
intros [x| |] y Hxy.
- now apply open_Rbar_gt.
- destruct y as [y| |].
  now exists y.
  easy.
  now apply filter_forall.
- now destruct y as [y| |].
Qed.

Lemma Rbar_locally'_le :
  forall x, filter_le (Rbar_locally' x) (Rbar_locally x).
Proof.
intros [x| |] P [eps HP] ; exists eps ; intros ; now apply HP.
Qed.

Lemma Rbar_locally'_le_finite :
  forall x : R, filter_le (Rbar_locally' x) (locally x).
Proof.
intros x P [eps HP] ; exists eps ; intros ; now apply HP.
Qed.

(** * Some limits on real functions *)

Definition Rbar_loc_seq (x : Rbar) (n : nat) := match x with
    | Finite x => x + / (INR n + 1)
    | p_infty => INR n
    | m_infty => - INR n
  end.

Lemma filterlim_Rbar_loc_seq :
  forall x, filterlim (Rbar_loc_seq x) eventually (Rbar_locally' x).
Proof.
  intros x P.
  unfold Rbar_loc_seq.
  case: x => /= [x | | ] [delta Hp].
(* x \in R *)
  case: (nfloor_ex (/delta)) => [ | N [_ HN]].
  by apply Rlt_le, Rinv_0_lt_compat, delta.
  exists N => n Hn.
  apply Hp ; simpl.
  ring_simplify (x + / (INR n + 1) + - x).
  rewrite Rabs_pos_eq.
  rewrite -(Rinv_involutive delta).
  apply Rinv_lt_contravar.
  apply Rmult_lt_0_compat.
  apply Rinv_0_lt_compat.
  by apply delta.
  exact: INRp1_pos.
  apply Rlt_le_trans with (1 := HN).
  by apply Rplus_le_compat_r, le_INR.
  by apply Rgt_not_eq, delta.
  by apply Rlt_le, RinvN_pos.
  apply Rgt_not_eq, Rminus_lt_0.
  ring_simplify.
  by apply RinvN_pos.
(* x = p_infty *)
  case: (nfloor_ex (Rmax 0 delta)) => [ | N [_ HN]].
  by apply Rmax_l.
  exists (S N) => n Hn.
  apply Hp.
  apply Rle_lt_trans with (1 := Rmax_r 0 _).
  apply Rlt_le_trans with (1 := HN).
  rewrite -S_INR ; by apply le_INR.
(* x = m_infty *)
  case: (nfloor_ex (Rmax 0 (-delta))) => [ | N [_ HN]].
  by apply Rmax_l.
  exists (S N) => n Hn.
  apply Hp.
  rewrite -(Ropp_involutive delta).
  apply Ropp_lt_contravar.
  apply Rle_lt_trans with (1 := Rmax_r 0 _).
  apply Rlt_le_trans with (1 := HN).
  rewrite -S_INR ; by apply le_INR.
Qed.

Lemma filterlim_const :
  forall {T U} {MU : MetricBall U} {F : (T -> Prop) -> Prop} {FF : Filter F},
  forall a : U, filterlim (fun _ => a) F (locally a).
Proof.
intros T U MU F FF a P [eps HP].
unfold filtermap.
apply filter_forall.
intros _.
apply HP.
apply ball_center.
Qed.

Lemma continuity_pt_locally :
  forall f x,
  continuity_pt f x <->
  forall eps : posreal, locally x (fun u => Rabs (f u - f x) < eps).
Proof.
intros f x.
split.
intros H eps.
move: (H eps (cond_pos eps)) => {H} [d [H1 H2]].
rewrite /= /R_dist /D_x /no_cond in H2.
exists (mkposreal d H1) => y H.
destruct (Req_dec x y) as [<-|Hxy].
rewrite /Rminus Rplus_opp_r Rabs_R0.
apply cond_pos.
by apply H2.
intros H eps He.
move: (H (mkposreal _ He)) => {H} [d H].
exists d.
split.
apply cond_pos.
intros h [Zh Hh].
exact: H.
Qed.

Lemma continuity_pt_locally' :
  forall f x,
  continuity_pt f x <->
  forall eps : posreal, locally' x (fun u => Rabs (f u - f x) < eps).
Proof.
intros f x.
split.
intros H eps.
move: (H eps (cond_pos eps)) => {H} [d [H1 H2]].
rewrite /= /R_dist /D_x /no_cond in H2.
exists (mkposreal d H1) => y H H'.
destruct (Req_dec x y) as [<-|Hxy].
rewrite /Rminus Rplus_opp_r Rabs_R0.
apply cond_pos.
by apply H2.
intros H eps He.
move: (H (mkposreal _ He)) => {H} [d H].
exists d.
split.
apply cond_pos.
intros h [Zh Hh].
apply H.
exact Hh.
apply proj2 in Zh.
now contradict Zh.
Qed.

Lemma continuity_pt_filterlim :
  forall (f : R -> R) (x : R),
  continuity_pt f x <->
  filterlim f (locally x) (locally (f x)).
Proof.
intros f x.
eapply iff_trans.
apply continuity_pt_locally.
apply iff_sym.
exact (filterlim_locally f (f x)).
Qed.

Lemma continuity_pt_filterlim' :
  forall f x,
  continuity_pt f x <->
  filterlim f (locally' x) (locally (f x)).
Proof.
intros f x.
eapply iff_trans.
apply continuity_pt_locally'.
apply iff_sym.
exact (filterlim_locally f (f x)).
Qed.

Lemma locally_pt_comp (P : R -> Prop) (f : R -> R) (x : R) :
  locally (f x) P -> continuity_pt f x ->
  locally x (fun x => P (f x)).
Proof.
intros Lf Cf.
apply continuity_pt_filterlim in Cf.
now apply Cf.
Qed.
