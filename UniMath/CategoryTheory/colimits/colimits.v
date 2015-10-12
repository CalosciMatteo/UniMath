(****************************************************
  Benedikt Ahrens and Anders Mörtberg, October 2015
*****************************************************)

Require Import UniMath.Foundations.Basics.All.
Require Import UniMath.Foundations.Propositions.
Require Import UniMath.Foundations.Sets.

Require Import UniMath.CategoryTheory.total2_paths.
Require Import UniMath.CategoryTheory.precategories.
Require Import UniMath.CategoryTheory.functor_categories.
Require Import UniMath.CategoryTheory.UnicodeNotations.

Local Notation "# F" := (functor_on_morphisms F)(at level 3).
(* Local Notation "F ⟶ G" := (nat_trans F G) (at level 39). *)
Local Notation "C ⟦ a , b ⟧" := (precategory_morphisms (C:=C) a b) (at level 50).

Section move_upstream.

Lemma path_to_ctr (A : UU) (B : A -> UU) (isc : iscontr (total2 (fun a => B a)))
           (a : A) (p : B a) : a = pr1 (pr1 isc).
Proof.
exact (maponpaths pr1 (pr2 isc (tpair _ a p))).
Defined.

Lemma uniqueExists (A : UU) (P : A -> UU)
  (Hexists : iscontr (total2 (fun a => P a)))
  (a b : A) (Ha : P a) (Hb : P b) : a = b.
Proof.
assert (H : tpair _ _ Ha = tpair _ _ Hb).
  now apply proofirrelevance, isapropifcontr.
exact (base_paths _ _ H).
Defined.

End move_upstream.

Section diagram_def.

Definition graph := Σ (D : UU) , D -> D -> UU.

Definition vertex : graph -> UU := pr1.
Definition edge {g : graph} : vertex g -> vertex g -> UU := pr2 g.

Definition diagram (g : graph) (C : precategory) : UU :=
  Σ (f : vertex g -> C), ∀ (a b : vertex g), edge a b -> C⟦f a, f b⟧.

Definition dob {g : graph} {C : precategory} (d : diagram g C) : vertex g -> C :=
  pr1 d.

Definition dmor {g : graph} {C : precategory} (d : diagram g C) :
  ∀ {a b}, edge a b -> C⟦dob d a,dob d b⟧ := pr2 d.

Section diagram_from_functor.

Variables (J C : precategory).
Variable (F : functor J C).

Definition graph_from_precategory : graph := pr1 (pr1 J).
Definition diagram_from_functor : diagram graph_from_precategory C :=
  tpair _ _ (pr2 (pr1 F)).

End diagram_from_functor.

End diagram_def.

Section colimit_def.

Variable C : precategory.
Variable (hsC : has_homsets C).
(* Variable g : graph. *)
(* Variable d : diagram g C. *)

(* TODO: Maybe package cocones again? *)
Definition isColimitCocone {g : graph} (d : diagram g C) (c0 : C)
  (f : ∀ (v : vertex g), C⟦dob d v,c0⟧)
  (H : ∀ (u v : vertex g) (e : edge u v), dmor d e ;; f v = f u) : UU :=
  ∀ (c : C) (fc : ∀ (v : vertex g), C⟦dob d v,c⟧)
    (Hc : ∀ (u v : vertex g) (e : edge u v), dmor d e ;; fc v = fc u),
  iscontr (Σ x : C⟦c0,c⟧, ∀ (v : vertex g), f v ;; x = fc v).

Definition ColimitCocone {g : graph} (d : diagram g C) : UU :=
  Σ (A : Σ c0f : (Σ c0 : C, ∀ (v : vertex g), C⟦dob d v,c0⟧),
   ∀ (u v : vertex g) (e : edge u v), dmor d e ;; (pr2 c0f) v = (pr2 c0f) u),
    isColimitCocone d (pr1 (pr1 A)) (pr2 (pr1 A)) (pr2 A).

Definition mk_ColimitCocone {g : graph} (d : diagram g C)
  (c : C) (f : ∀ (v : vertex g), C⟦dob d v,c⟧)
  (H : ∀ (u v : vertex g) (e : edge u v), dmor d e ;; f v = f u)
  (isCC : isColimitCocone d c f H) : ColimitCocone d.
Proof.
refine (tpair _ _ _).
+ refine (tpair _ _ _).
  - apply (tpair _ c f).
  - apply H.
+ apply isCC.
Defined.

Definition Colimits : UU := ∀ {g : graph} (d : diagram g C), ColimitCocone d.
Definition hasColimits : UU  :=
  ∀ {g : graph} (d : diagram g C), ishinh (ColimitCocone d).

Definition ColimitBottom {g : graph} {d : diagram g C}
  (CC : ColimitCocone d) : C := pr1 (pr1 (pr1 CC)).

Definition ColimitIn {g : graph} {d : diagram g C} (CC : ColimitCocone d) :
  ∀ (v : vertex g), C⟦dob d v,ColimitBottom CC⟧ :=
    pr2 (pr1 (pr1 CC)).

Definition ColimitInCommutes {g : graph} {d : diagram g C}
  (CC : ColimitCocone d) : ∀ (u v : vertex g) (e : edge u v),
   dmor d e ;; ColimitIn CC v = ColimitIn CC u :=
     pr2 (pr1 CC).

Definition isColimitCocone_ColimitCocone {g : graph} {d : diagram g C}
  (CC : ColimitCocone d) :
  isColimitCocone d (ColimitBottom CC) (ColimitIn CC) (ColimitInCommutes CC) :=
   pr2 CC.

Definition ColimitArrow {g : graph} {d : diagram g C} (CC : ColimitCocone d)
  (c : C) (fc : ∀ (v : vertex g), C⟦dob d v,c⟧)
  (Hc : ∀ (u v : vertex g) (e : edge u v), dmor d e ;; fc v = fc u) :
  C⟦ColimitBottom CC,c⟧.
Proof.
exact (pr1 (pr1 (isColimitCocone_ColimitCocone CC c fc Hc))).
Defined.

Lemma ColimitArrowCommutes {g : graph} {d : diagram g C} (CC : ColimitCocone d)
  (c : C) (fc : ∀ (v : vertex g), C⟦dob d v,c⟧)
  (Hc : ∀ (u v : vertex g) (e : edge u v), dmor d e ;; fc v = fc u)
  (u : vertex g) :
  ColimitIn CC u ;; ColimitArrow CC c fc Hc = fc u.
Proof.
exact ((pr2 (pr1 (isColimitCocone_ColimitCocone CC _ fc Hc))) u).
Qed.

Lemma ColimitArrowUnique {g : graph} {d : diagram g C} (CC : ColimitCocone d)
  (c : C) (fc : ∀ (v : vertex g), C⟦dob d v,c⟧)
  (Hc : ∀ (u v : vertex g) (e : edge u v), dmor d e ;; fc v = fc u)
  (k : C⟦ColimitBottom CC,c⟧)
  (Hk : ∀ (u : vertex g), ColimitIn CC u ;; k = fc u) :
  k = ColimitArrow CC c fc Hc.
Proof.
now apply path_to_ctr, Hk.
Qed.

Lemma Cocone_postcompose {g : graph} {d : diagram g C}
  (c : C) (fc : ∀ (v : vertex g), C⟦dob d v,c⟧)
  (Hc : ∀ (u v : vertex g) (e : edge u v), dmor d e ;; fc v = fc u)
  (x : C) (f : C⟦c,x⟧) : ∀ u v (e : edge u v), (dmor d e ;; (fc v ;; f) = fc u ;; f).
Proof.
intros u v e.
now rewrite assoc, Hc.
Qed.

Lemma ColimitArrowEta {g : graph} {d : diagram g C} (CC : ColimitCocone d)
  (c : C) (f : C⟦ColimitBottom CC,c⟧) :
    f = ColimitArrow CC c (λ u, ColimitIn CC u ;; f)
          (Cocone_postcompose _ _ (ColimitInCommutes CC) c f).
Proof.
apply ColimitArrowUnique.
now intro u; apply idpath.
Qed.

Definition ColimitOfArrows {g : graph} {d1 d2 : diagram g C}
  (CC1 : ColimitCocone d1) (CC2 : ColimitCocone d2)
  (f : ∀ (u : vertex g), C⟦dob d1 u,dob d2 u⟧)
  (fNat : ∀ u v (e : edge u v), dmor d1 e ;; f v = f u ;; dmor d2 e) :
  C⟦ColimitBottom CC1,ColimitBottom CC2⟧.
Proof.
refine (ColimitArrow _ _ _ _).
- now intro u; apply (f u ;; ColimitIn CC2 u).
- abstract (intros u v e; simpl;
            now rewrite assoc, fNat, <- assoc, ColimitInCommutes).
Defined.

Lemma ColimitOfArrowsIn {g : graph} (d1 d2 : diagram g C)
  (CC1 : ColimitCocone d1) (CC2 : ColimitCocone d2)
  (f : ∀ (u : vertex g), C⟦dob d1 u,dob d2 u⟧)
  (fNat : ∀ u v (e : edge u v), dmor d1 e ;; f v = f u ;; dmor d2 e) :
    ∀ u, ColimitIn CC1 u ;; ColimitOfArrows CC1 CC2 f fNat =
         f u ;; ColimitIn CC2 u.
Proof.
now unfold ColimitOfArrows; intro u; rewrite ColimitArrowCommutes.
Qed.

Lemma preCompWithColimitOfArrows_subproof {g : graph} {d1 d2 : diagram g C}
  (CC1 : ColimitCocone d1) (CC2 : ColimitCocone d2)
  (f : ∀ (u : vertex g), C⟦dob d1 u,dob d2 u⟧)
  (fNat : ∀ u v (e : edge u v), dmor d1 e ;; f v = f u ;; dmor d2 e)
  (x : C) (k : ∀ (u : vertex g), C⟦dob d2 u,x⟧)
  (Hx : ∀ (u v : vertex g) (e : edge u v), dmor d2 e ;; k v = k u) :
    ∀ (u v : vertex g) (e : edge u v),
      dmor d1 e;; (λ u0 : vertex g, f u0;; k u0) v =
      (λ u0 : vertex g, f u0;; k u0) u.
Proof.
intros u v e; simpl.
now rewrite <- (Hx u v e), !assoc, fNat.
Qed.

Lemma precompWithColimitOfArrows {g : graph} (d1 d2 : diagram g C)
  (CC1 : ColimitCocone d1) (CC2 : ColimitCocone d2)
  (f : ∀ (u : vertex g), C⟦dob d1 u,dob d2 u⟧)
  (fNat : ∀ u v (e : edge u v), dmor d1 e ;; f v = f u ;; dmor d2 e)
  (x : C) (k : ∀ (u : vertex g), C⟦dob d2 u,x⟧)
  (Hx : ∀ (u v : vertex g) (e : edge u v), dmor d2 e ;; k v = k u) :
  ColimitOfArrows CC1 CC2 f fNat ;; ColimitArrow CC2 x k Hx =
  ColimitArrow CC1 x (λ u, f u ;; k u)
     (preCompWithColimitOfArrows_subproof CC1 CC2 f fNat x k Hx).
Proof.
apply ColimitArrowUnique.
now intro u; rewrite assoc, ColimitOfArrowsIn, <- assoc, ColimitArrowCommutes.
Qed.

Lemma postcompWithColimitArrow {g : graph} (D : diagram g C)
 (CC : ColimitCocone D)
 (c : C) (fc : ∀ u, C⟦dob D u,c⟧)
 (Hc : ∀ (u v : vertex g) (e : edge u v), dmor D e ;; fc v = fc u)
 (d : C) (k : C⟦c,d⟧) :
   ColimitArrow CC c fc Hc ;; k =
   ColimitArrow CC d (λ u, fc u ;; k) (Cocone_postcompose c fc Hc d k).
Proof.
apply ColimitArrowUnique.
now intro u; rewrite assoc, ColimitArrowCommutes.
Qed.

Lemma Colimit_endo_is_identity {g : graph} (D : diagram g C)
  (CC : ColimitCocone D)
  (k : ColimitBottom CC ⇒ ColimitBottom CC)
  (H : ∀ u, ColimitIn CC u ;; k = ColimitIn CC u) :
  identity _ = k.
Proof.
unfold ColimitCocone in CC.
refine (uniqueExists _ _ ((pr2 CC) _ _ _) _ _ _ _).
- intros v.
  exact (pr2 (pr1 (pr1 CC)) v).
- intros u v e; simpl.
  now apply ColimitInCommutes.
- intros v; simpl.
  now apply id_right.
- intros v; simpl.
  now apply H.
Qed.

Definition Cocone_by_postcompose {g : graph} (D : diagram g C)
 (c : C) (fc : ∀ u, C⟦dob D u,c⟧)
 (Hc : ∀ (u v : vertex g) (e : edge u v), dmor D e ;; fc v = fc u) :
 ∀ (d : C) (k : C⟦c,d⟧),
 Σ (μ : ∀ (u : vertex g), C⟦dob D u,d⟧), ∀ (u v : vertex g) (e : edge u v), dmor D e ;; μ v = μ u.
Proof.
intros d k.
exists (λ u, fc u ;; k).
now apply Cocone_postcompose.
Defined.

Lemma test {g : graph} (D : diagram g C)
           (c : C) (fc : ∀ u, C⟦dob D u,c⟧)
           (Hc : ∀ (u v : vertex g) (e : edge u v), dmor D e ;; fc v = fc u)
           (d : C) (k : C⟦c,d⟧) :
           ∀ u, fc u ;; k = pr1 (Cocone_by_postcompose D c fc Hc d k) u.
Proof.
now intro u.
Qed.


Lemma isColimit_weq {g : graph} (D : diagram g C)
                    (c : C) (fc : ∀ u, C⟦dob D u,c⟧)
                    (Hc : ∀ (u v : vertex g) (e : edge u v), dmor D e ;; fc v = fc u) :
  isColimitCocone D c fc Hc <-> ∀ (d : C), isweq (Cocone_by_postcompose D c fc Hc d).
Proof.
split.
- intros H d.
  refine (gradth _ _ _ _).
  + intros k.
    exact (ColimitArrow (mk_ColimitCocone D c fc Hc H) _ (pr1 k) (pr2 k)).
  + intro k; simpl.
    now apply pathsinv0, (ColimitArrowEta (mk_ColimitCocone D c fc Hc H)).
  + simpl; intro k.
    apply total2_paths_second_isaprop.
    * now repeat (apply impred; intro); apply hsC.
    * destruct k as [k Hk]; simpl.
      apply funextsec; intro u.
      now apply (ColimitArrowCommutes (mk_ColimitCocone D c fc Hc H)).
- intros H d fd Hd.
  refine (tpair _ _ _).
  + set (p := invmap (weqpair _ (H d))).
    exists (p (tpair _ fd Hd)).
    intro u.
set (Y := test D c fc Hc d).
set (p' := p _).
set (X := Y p' u).
rewrite X.
unfold p', p.
set (asdf := tpair _ _ _).
set (@homotweqinvweq _ _ (weqpair _ (H d)) asdf).
simpl in p0.
now rewrite p0.
+
intro.
apply total2_paths_second_isaprop.
apply impred; intro.
apply hsC.
simpl.
destruct t as [t Ht]; simpl.
set (q := weqpair _ (H d)).
apply (invmaponpathsweq q).
simpl.
apply total2_paths_second_isaprop.
repeat (apply impred; intro); apply hsC.
simpl.
apply funextsec; intro u.
rewrite Ht.
apply pathsinv0.
set (p := invmap q).
set (Y := test D c fc Hc d).
set (p' := p _).
set (X := Y p' u).
rewrite X.
unfold p', p.
set (asdf := tpair _ _ _).
set (@homotweqinvweq _ _ (weqpair _ (H d)) asdf).
unfold q.
simpl in p0.
now rewrite p0.
Defined.


End colimit_def.

Section ColimitFunctor.

Variable A C : precategory.
Variable HC : Colimits C.
Variable hsC : has_homsets C.
Variable g : graph.
Variable D : diagram g [A, C, hsC].

Definition diagram_pointwise (a : A) : diagram g C.
Proof.
exists (fun v => pr1 (dob D v) a); intros u v e.
now apply (pr1 (dmor D e) a).
Defined.

Let HCg a := HC g (diagram_pointwise a).

Definition ColimitFunctor_ob (a : A) : C := ColimitBottom _ (HCg a).

Definition ColimitFunctor_mor (a a' : A) (f : A⟦a, a'⟧)
  : ColimitFunctor_ob a ⇒ ColimitFunctor_ob a'.
Proof.
refine (ColimitOfArrows _ _ _ _ _).
- now intro u; apply (# (pr1 (dob D u)) f).
- abstract (now intros u v e; simpl; apply pathsinv0, (nat_trans_ax (dmor D e))).
Defined.

Definition ColimitFunctor_data : functor_data A C :=
  tpair _ _ ColimitFunctor_mor.

Lemma is_functor_ColimitFunctor_data : is_functor ColimitFunctor_data.
Proof.
split.
- intro a; simpl.
  apply pathsinv0, Colimit_endo_is_identity; intro u.
  unfold ColimitFunctor_mor.
  now rewrite ColimitOfArrowsIn, (functor_id (dob D u)), id_left.
- intros a b c fab fbc; simpl; unfold ColimitFunctor_mor.
  apply pathsinv0.
  eapply pathscomp0; [now apply precompWithColimitOfArrows|].
  apply pathsinv0, ColimitArrowUnique; intro u.
  now rewrite ColimitOfArrowsIn, (functor_comp (dob D u)), assoc.
Qed.

Definition ColimitFunctor : functor A C :=
  tpair _ _ is_functor_ColimitFunctor_data.

Definition colimit_nat_trans_in_data v : [A, C, hsC] ⟦ dob D v, ColimitFunctor ⟧.
Proof.
refine (tpair _ _ _).
- intro a; exact (ColimitIn C (HCg a) v).
- intros a a' f.
  now apply pathsinv0, (ColimitOfArrowsIn _ _ _ (HCg a) (HCg a')).
Defined.

Lemma ColimitFunctor_unique (F : [A, C, hsC])
  (Fc : ∀ v : vertex g, [A, C, hsC] ⟦ dob D v, F ⟧)
  (Hc : ∀ (u v : vertex g) (e : edge u v), dmor D e ;; Fc v = Fc u) :
   iscontr (Σ x : [A, C, hsC] ⟦ ColimitFunctor, F ⟧,
            ∀ v : vertex g, colimit_nat_trans_in_data v ;; x = Fc v).
Proof.
refine (tpair _ _ _).
- refine (tpair _ _ _).
  + refine (tpair _ _ _).
    * intro a.
      apply (ColimitArrow _ (HCg a) _ (λ v, pr1 (Fc v) a)).
      intros u v e.
      now apply (nat_trans_eq_pointwise _ _ _ _ _ _ (Hc u v e)).
    * intros a a' f; simpl.
      eapply pathscomp0; [now apply precompWithColimitOfArrows|].
      apply pathsinv0.
      eapply pathscomp0; [now apply postcompWithColimitArrow|].
      apply ColimitArrowUnique.
      intro u.
      eapply pathscomp0; [now apply ColimitArrowCommutes|].
      now apply pathsinv0, nat_trans_ax.
  + intro u.
    apply (nat_trans_eq hsC); simpl; intro a.
    now apply (ColimitArrowCommutes _ (HCg a)).
- intro t; destruct t as [t1 t2].
  apply (total2_paths_second_isaprop); simpl.
  + apply impred; intro u.
    now apply functor_category_has_homsets.
  + apply (nat_trans_eq hsC); simpl; intro a.
    apply ColimitArrowUnique; intro u.
    now rewrite <- (t2 u).
Qed.

Lemma ColimitFunctorCocone : ColimitCocone [A,C,hsC] D.
Proof.
refine (tpair _ _ _).
- refine (tpair _ _ _).
  + exists ColimitFunctor.
    now apply colimit_nat_trans_in_data.
  + abstract (now intros u v e; apply (nat_trans_eq hsC);
                  intro a; apply (ColimitInCommutes C (HCg a))).
- now intros F Fc Hc; simpl; apply (ColimitFunctor_unique _ _ Hc).
Defined.

End ColimitFunctor.

Lemma ColimitsFunctorCategory (A C : precategory) (hsC : has_homsets C)
  (HC : Colimits C) : Colimits [A,C,hsC].
Proof.
now intros g d; apply ColimitFunctorCocone.
Qed.

(**** TODO: Adapt *)
(** * Proof that coproducts are unique when the precategory [C] is a category *)

(* Section coproduct_unique. *)

(* Hypothesis H : is_category C. *)

(* Variables a b : C. *)

(* Definition from_Coproduct_to_Coproduct (CC CC' : CoproductCocone a b)  *)
(*   : CoproductObject CC ⇒ CoproductObject CC'. *)
(* Proof. *)
(*   apply (CoproductArrow CC  (CoproductIn1 _ ) (CoproductIn2 _ )). *)
(* Defined.   *)


(* Lemma Coproduct_endo_is_identity (CC : CoproductCocone a b)  *)
(*   (k : CoproductObject CC ⇒ CoproductObject CC)  *)
(*   (H1 : CoproductIn1 CC ;; k = CoproductIn1 CC) *)
(*   (H2 : CoproductIn2 CC ;; k = CoproductIn2 CC)  *)
(*   : identity _ = k. *)
(* Proof. *)
(*   set (H' := pr2 CC _ (CoproductIn1 CC) (CoproductIn2 CC) ); simpl in *. *)
(*   set (X := (Σ fg : pr1 (pr1 CC) ⇒ CoproductObject CC, *)
(*           pr1 (pr2 (pr1 CC));; fg = CoproductIn1 CC *)
(*           × pr2 (pr2 (pr1 CC));; fg = CoproductIn2 CC)). *)
(*   set (t1 := tpair _ k (dirprodpair H1 H2) : X). *)
(*   set (t2 := tpair _ (identity _ ) (dirprodpair (id_right _ _ _ _ ) (id_right _ _ _ _ ) ) : X). *)
(*   assert (X' : t1 = t2). *)
(*   { apply proofirrelevance. *)
(*     apply isapropifcontr. *)
(*     apply H'. *)
(*   } *)
(*   apply pathsinv0. *)
(*   apply (base_paths _ _ X'). *)
(* Defined. *)


(* Lemma is_iso_from_Coproduct_to_Coproduct (CC CC' : CoproductCocone a b)  *)
(*   : is_iso (from_Coproduct_to_Coproduct CC CC'). *)
(* Proof. *)
(*   apply is_iso_from_is_z_iso. *)
(*   exists (from_Coproduct_to_Coproduct CC' CC). *)
(*   split; simpl. *)
(*   - apply pathsinv0.  *)
(*     apply Coproduct_endo_is_identity. *)
(*     + rewrite assoc. unfold from_Coproduct_to_Coproduct.  *)
(*       rewrite CoproductIn1Commutes. *)
(*       rewrite CoproductIn1Commutes. *)
(*       apply idpath. *)
(*     + rewrite assoc. unfold from_Coproduct_to_Coproduct.  *)
(*       rewrite CoproductIn2Commutes. *)
(*       rewrite CoproductIn2Commutes. *)
(*       apply idpath. *)
(*   - apply pathsinv0. *)
(*     apply Coproduct_endo_is_identity. *)
(*     + rewrite assoc; unfold from_Coproduct_to_Coproduct. *)
(*       repeat rewrite CoproductIn1Commutes; apply idpath. *)
(*     + rewrite assoc; unfold from_Coproduct_to_Coproduct. *)
(*       repeat rewrite CoproductIn2Commutes; apply idpath. *)
(* Defined. *)

(* Definition iso_from_Coproduct_to_Coproduct (CC CC' : CoproductCocone a b)  *)
(*   : iso (CoproductObject CC) (CoproductObject CC')  *)
(*   := isopair _ (is_iso_from_Coproduct_to_Coproduct CC CC'). *)

(* Lemma transportf_isotoid' (c d d': C) (p : iso d d') (f : c ⇒ d) :  *)
(*   transportf (λ a0 : C, c ⇒ a0) (isotoid C H p) f = f ;; p . *)
(* Proof. *)
(*   rewrite <- idtoiso_postcompose. *)
(*   rewrite idtoiso_isotoid. *)
(*   apply idpath. *)
(* Defined. *)

(* Lemma isaprop_CoproductCocone : isaprop (CoproductCocone a b). *)
(* Proof. *)
(*   apply invproofirrelevance. *)
(*   intros CC CC'. *)
(*   apply total2_paths_isaprop. *)
(*   + intros. *)
(*     do 3 (apply impred; intro); apply isapropiscontr. *)
(*   + apply (total2_paths (isotoid _ H (iso_from_Coproduct_to_Coproduct CC CC'))). *)
(*     rewrite transportf_dirprod.  *)
(*     rewrite transportf_isotoid'. simpl. *)
(*     rewrite transportf_isotoid'. *)
(*     destruct CC as [CC bla]. *)
(*     destruct CC' as [CC' bla']; simpl in *. *)
(*     destruct CC as [CC [CC1 CC2]]. *)
(*     destruct CC' as [CC' [CC1' CC2']]; simpl in *. *)
(*     unfold from_Coproduct_to_Coproduct. *)
(*     rewrite CoproductIn1Commutes. *)
(*     rewrite CoproductIn2Commutes. *)
(*     apply idpath. *)
(* Qed. *)

(* End coproduct_unique.   *)
(* End coproduct_def. *)
