(* In this file, we have formalized:
   1: The definition of a weak (dagger) equivalence between dagger categories
   2: We have shown that any weak dagger equivalence induces a unitary isomorphism, i.e. dagger isomorphism,
*)

Require Import UniMath.Foundations.All.
Require Import UniMath.MoreFoundations.All.

Require Import UniMath.CategoryTheory.Core.Categories.
Require Import UniMath.CategoryTheory.Core.Functors.
Require Import UniMath.CategoryTheory.Core.NaturalTransformations.
Require Import UniMath.CategoryTheory.whiskering.
Require Import UniMath.CategoryTheory.FunctorCategory.
Require Import UniMath.CategoryTheory.DaggerCategories.Categories.
Require Import UniMath.CategoryTheory.DaggerCategories.Functors.
Require Import UniMath.CategoryTheory.DaggerCategories.Transformations.
Require Import UniMath.CategoryTheory.DaggerCategories.Unitary.
Require Import UniMath.CategoryTheory.DaggerCategories.Univalence.
Require Import UniMath.CategoryTheory.DaggerCategories.FunctorCategory.

Local Open Scope cat.

Section WeakDaggerEquivalences.

  Definition is_unitarily_eso
             {C D : category} {dagC : dagger C} {dagD : dagger D}
             {F : functor C D}
             (dagF : is_dagger_functor dagC dagD F)
    : UU
    := ∏ d : D, ∃ c : C, unitary dagD (F c) d.

  Lemma isaprop_is_unitarily_eso
        {C D : category} {dagC : dagger C} {dagD : dagger D}
        {F : functor C D}
        (dagF : is_dagger_functor dagC dagD F)
    : isaprop (is_unitarily_eso dagF).
  Proof.
    apply impred_isaprop ; intro.
    apply isapropishinh.
  Qed.

  Definition is_weak_dagger_equiv
             {C D : category} {dagC : dagger C} {dagD : dagger D}
             {F : functor C D}
             (dagF : is_dagger_functor dagC dagD F)
    : UU
    := is_unitarily_eso dagF × fully_faithful F.

  Lemma isaprop_is_weak_dagger_equiv
        {C D : category} {dagC : dagger C} {dagD : dagger D}
        {F : functor C D}
        (dagF : is_dagger_functor dagC dagD F)
    : isaprop (is_weak_dagger_equiv dagF).
  Proof.
    apply isapropdirprod.
    - apply isaprop_is_unitarily_eso.
    - apply isaprop_fully_faithful.
  Qed.

End WeakDaggerEquivalences.

Section DaggerEquivalences.

  Definition is_unitarily_split_eso
             {C D : category} {dagC : dagger C} {dagD : dagger D}
             {F : functor C D}
             (dagF : is_dagger_functor dagC dagD F)
    : UU
    := ∏ d : D, ∑ c : C, unitary dagD (F c) d.

  Definition is_dagger_equiv
             {C D : category} {dagC : dagger C} {dagD : dagger D}
             {F : functor C D}
             (dagF : is_dagger_functor dagC dagD F)
    : UU
    := is_unitarily_split_eso dagF × fully_faithful F.

End DaggerEquivalences.
