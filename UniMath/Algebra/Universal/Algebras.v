(** * Algebra for a given signature. *)
(** Gianluca Amato,  Marco Maggesi, Cosimo Perini Brogi 2019-2023 *)

Require Import UniMath.Foundations.All.
Require Import UniMath.MoreFoundations.All.

Require Export UniMath.Algebra.Universal.SortedTypes.
Require Export UniMath.Algebra.Universal.Signatures.

Local Open Scope sorted.

(** ** Basic definitions. *)

Definition algebra (σ: signature): UU
  := ∑ A: sUU (sorts σ), ∏ nm: names σ, A⋆ (arity nm) → A (sort nm).

Definition support {σ: signature} (A: algebra σ): sUU (sorts σ) := pr1 A.

Coercion support: algebra >-> sUU.

Definition ops {σ: signature} (A: algebra σ) := pr2 A.

Definition make_algebra {σ: signature} (A : sUU (sorts σ)) (ops: ∏ nm: names σ, A⋆ (arity nm) → A (sort nm))
  : algebra σ := A ,, ops.

Definition dom {σ: signature} (A: algebra σ) (nm: names σ): UU := A⋆ (arity nm).

Definition rng {σ: signature} (A: algebra σ) (nm: names σ): UU := support A (sort nm).

Definition has_supportsets {σ: signature} (A: algebra σ): UU
  := ∏ s: sorts σ, isaset (support A s).

(** ** Helper for building an algebra starting from a simple signature.

A simple signature is either a [signature_simple_single_sorted] for the single-sorted case or
a [signature_single] for the multi-sorted case.
*)

Definition make_algebra_simple_single_sorted
    (σ : signature_simple_single_sorted)
    (A : UU)
    (ops : (λ n: nat, vec A n → A)⋆ σ)
  : algebra σ.
Proof.
  exists (λ _, A).
  unfold arity.
  revert σ ops.
  refine (list_ind _ _ _).
  - intros.
    cbn in nm.
    apply fromstn0.
    assumption.
  - intros x xs IHxs ops nm.
    simpl in ops.
    induction nm as [nm nmproof].
    induction nm.
    + unfold star.
      exact (pr1 ops ∘ h1lower).
    + exact (IHxs (pr2 ops) (nm ,, nmproof)).
Defined.

Definition make_algebra_simple
    (σ: signature_simple)
    (A: vec UU (pr1 σ))
    (ops: (λ a, (el A)⋆ (dirprod_pr1 a) → el A (dirprod_pr2 a))⋆ (pr2 σ))
  : algebra σ.
Proof.
  exists (el A).
  unfold arity.
  induction σ as [ns ar].
  simpl in A.
  revert ar ops.
  refine (list_ind _ _ _).
  - intros.
    cbn in nm.
    apply fromstn0.
    assumption.
  - simpl.
    intros x xs IHxs ops.
    induction ops as [op ops].
    intro.
    cbn in nm.
    induction nm as [nm nmproof].
    induction nm.
    + unfold star.
      exact op.
    + exact (IHxs ops (nm ,, nmproof)).
Defined.

(** ** Homomorphisms of algebras. *)

Definition ishom {σ: signature} {A1 A2: algebra σ} (h: A1 s→ A2) : UU
  := ∏ (nm: names σ) (x: dom A1 nm), h _ (ops A1 nm x) = ops A2 nm (h⋆⋆ _ x).

Definition hom {σ: signature} (A1 A2: algebra σ): UU := ∑ (h: A1 s→ A2), ishom h.

Declare Scope hom_scope.

Notation "a1 ↷ a2" := (hom a1 a2) (at level 80, right associativity): hom_scope.

Delimit Scope hom_scope with hom.

Bind Scope hom_scope with hom.

Local Open Scope hom.

Definition hom2fun {σ: signature} {A1 A2: algebra σ} (f: A1 ↷ A2)
  : sfun (support A1) (support A2) := pr1 f.

Coercion hom2fun: hom >-> sfun.

Definition hom2axiom {σ: signature} {A1 A2: algebra σ} (f: A1 ↷ A2) := pr2 f.

Definition make_hom {σ: signature} {A1 A2: algebra σ} {f: sfun A1 A2} (is: ishom f): A1 ↷ A2 := f ,, is.

Theorem isapropishom {σ: signature} {A1 A2: algebra σ} (f: sfun A1 A2)
   (setprop: has_supportsets A2): isaprop (ishom f).
Proof.
  red.
  apply impred_isaprop.
  intros.
  apply impred_isaprop.
  intros.
  apply setprop.
Defined.

Theorem isasethom {σ: signature} (A1 A2: algebra σ) (setprop: has_supportsets A2)
  : isaset (A1 ↷ A2).
Proof.
  red.
  apply isaset_total2.
  - apply impred_isaset.
    intros.
    apply impred_isaset.
    intros.
    apply setprop.
  - intros.
    apply isasetaprop.
    apply isapropishom.
    exact setprop.
Defined.

(** ** Identity and composition of homomorphisms. *)

Lemma ishomid {σ: signature} (A: algebra σ): ishom (idsfun A).
Proof.
  red.
  intros.
  rewrite staridfun.
  apply idpath.
Defined.

Definition homid {σ: signature} (A: algebra σ): A ↷ A := make_hom (ishomid A).

Lemma ishomcomp {σ: signature} {A1 A2 A3: algebra σ} (h1: A1 ↷ A2) (h2: A2 ↷ A3): ishom (h2 s∘ h1).
Proof.
  red.
  intros.
  induction h1 as [h1 ishomh1].
  induction h2 as [h2 ishomh2].
  cbn.
  rewrite starcomp.
  rewrite ishomh1.
  rewrite ishomh2.
  apply idpath.
Defined.

Definition homcomp {σ: signature} {a1 a2 a3: algebra σ} (h1: a1 ↷ a2) (h2: a2 ↷ a3) : a1 ↷ a3
  := make_hom (ishomcomp h1 h2).

(** ** The unit algebra and the proof it is final. *)

Definition unitalgebra (σ: signature): algebra σ
  := make_algebra (sunit (sorts σ)) tosunit.

Lemma ishomtounit {σ: signature} (A: algebra σ): @ishom σ A (unitalgebra σ) tosunit.
Proof.
  red.
  intros.
  apply iscontrunit.
Defined.

Definition unithom {σ: signature} (A : algebra σ): hom A (unitalgebra σ)
  := make_hom (ishomtounit A).

Theorem iscontrhomstounit {σ: signature} (A: algebra σ): iscontr (hom A (unitalgebra σ)).
Proof.
  exists (unithom A).
  intro.
  apply subtypePairEquality'.
  - apply proofirrelevancecontr.
    apply iscontr_sfuntosunit.
  - apply isapropishom.
    unfold has_supportsets.
    intros.
    apply isasetunit.
Defined.

(** ** Helpers for working with curried functions *)

Definition ops' {σ: signature} (A: algebra σ) (nm: names σ) := currify (ops A nm).

Definition make_algebra'
    {σ: signature}
    (A : sUU (sorts σ))
    (ops: ∏ nm: names σ, iterfun (vec_map A (arity nm)) (A (sort nm)))
  : algebra σ := A ,, λ nm, uncurrify (ops nm).

Definition make_algebra_simple_single_sorted'
    (σ : signature_simple_single_sorted)
    (A : hSet)
    (ops : (λ n: nat, iterfun (vec_fill (pr1hSet A) n) A)⋆ σ)
  : algebra σ.
Proof.
  refine (make_algebra_simple_single_sorted σ A _).
  refine (h1map _ ops).
  intro a.
  induction (@hvec_vec_fill A a).
  exact uncurrify.
Defined.

Definition make_algebra_simple'
    (σ: signature_simple)
    (A: vec UU (pr1 σ))
    (ops: (λ a, iterfun (vec_map (el A) (pr2 (dirprod_pr1 a))) (el A (dirprod_pr2 a)))⋆ (pr2 σ))
  : algebra σ := make_algebra_simple σ A (h1map (λ _, uncurrify) ops).

(** ** Algebras with hSets as carriers *)

Definition hSetalgebra (σ : signature) : UU
  := ∑ A: shSet (sorts σ), ∏ nm: names σ, A⋆ (arity nm) → A (sort nm).

Definition make_hSetalgebra {σ : signature} {A: algebra σ} (setproperty: has_supportsets A): hSetalgebra σ
:= ((λ s : sorts σ, make_hSet (support A s) (setproperty s)),, ops A).

Definition hSetalgebra_to_algebra {σ : signature} (A: hSetalgebra σ): algebra σ
:= ((λ s : sorts σ, pr1 (pr1 A s)),, pr2 A).

Coercion hSetalgebra_to_algebra : hSetalgebra >-> algebra.

Definition has_supportsets_hSetalgebra {σ : signature} (A: hSetalgebra σ): has_supportsets (hSetalgebra_to_algebra A)
:= λ s: sorts σ, setproperty (pr1 A s).

Lemma transportf_fun_op {σ : signature} {A B : sUU (sorts σ)}
  (p : A = B)
  (nm : names σ) (f : (A⋆ (arity nm) → A (sort nm)))
  : transportf (λ x : sUU (sorts σ), x⋆ (arity nm) → x (sort nm)) p f
  = (transportf (λ x : sUU (sorts σ), x (sort nm)) p) ∘ f ∘ (transportb (λ x : sUU (sorts σ), x⋆ (arity nm)) p).
Proof.
  induction p.
  apply idpath.
Defined.

Lemma transportf_fun_op2 {σ : signature} {A : sUU (sorts σ)}
  (D D' : ∏ s : sorts σ, A s → UU)
  (p : D = D')
  (nm : names σ)
  (base_xs : hvec (vec_map A (arity nm)))
  (opsAnm : (A⋆ (arity nm) → A (sort nm)))
  (f : hvec (h1lower (h1map D base_xs)) → D (sort nm) (opsAnm base_xs))
  : transportf
    (λ x : ∏ s : sorts σ, A s → UU,
      hvec (h1lower (h1map x base_xs)) → x (sort nm) (opsAnm base_xs))
    p f
  = (transportf
    (λ D0 : ∏ s : sorts σ, A s → UU , D0 (sort nm) (opsAnm base_xs)) p) ∘ f ∘
    (transportb (λ D0, hvec (h1lower (h1map D0 base_xs))) p).
  Proof.
    induction p.
    apply idpath.
  Defined.

(*The proof is the same of [transportf_funextsec], but this statement is not captured by it*)
  Lemma transportf_funextsec_op
    {S : UU} {A : sUU S}
    {l : list S}
    (D D' : ∏ s : S, A s → UU)
    (H : ∏ (s: S), D s = D' s)
    (s : S)
    (a : A s)
    (d : D s a)

  : transportf (λ D0 : ∏ s : S, A s → UU, D0 s a) (funextsec _ _ _ H) d =
  transportf (λ Ds0 : A s -> UU, Ds0 a) (H s) d.
  Proof.
    use (toforallpaths_induction' S (λ s, A s → UU) D D'
      (λ H',  transportf
        (λ D0 : ∏ s : S, A s → UU, D0 s a)
        (funextsec (λ s : S, A s → UU) D D' H') d
        = transportf
        (λ Ds0 : A s → UU, Ds0 a)
        (H' s) d ) _ H).
    intro e.
    clear H.
    simpl.

    set (XR := homotinvweqweq (weqtoforallpaths _ D D') e).
    set (H := funextsec (λ s, A s → UU) D D' (toforallpaths _ D D' e)).
    set (P' := (λ D0 : ∏ s : S, A s → UU, D0 s a)).
    use pathscomp0.
    - exact (transportf P' e d).
    - use (transportf_paths _ XR).
    - induction e. apply idpath.
  Defined.

  Lemma transportb_funextsec_op
    {S : UU} {A : sUU S}
    {l : list S}
    (D D' : ∏ s : S, A s → UU)
    (H : ∏ (s: S), D s = D' s)
    (s : S)
    (a : A s)
    (d : D' s a)

  : transportb (λ D0 : ∏ s : S, A s → UU, D0 s a) (funextsec _ _ _ H) d =
  transportb (λ Ds0 : A s -> UU, Ds0 a) (H s) d.
  Proof.
    use (toforallpaths_induction' S (λ s, A s → UU) D D'
      (λ H',  transportb
        (λ D0 : ∏ s : S, A s → UU, D0 s a)
        (funextsec (λ s : S, A s → UU) D D' H') d
        = transportb
        (λ Ds0 : A s → UU, Ds0 a)
        (H' s) d ) _ H).
    intro e.
    clear H.
    simpl.

    set (XR := homotinvweqweq (weqtoforallpaths _ D D') e).
    set (H := funextsec (λ s, A s → UU) D D' (toforallpaths _ D D' e)).
    set (P' := (λ D0 : ∏ s : S, A s → UU, D0 s a)).
    use pathscomp0.
    - exact (transportb P' e d).
    - use (transportf_paths _ _).
      use invrot.
      eapply pathscomp0.
      { use pathsinv0inv0. }
      exact XR.
    - induction e. apply idpath.
  Defined.

  Lemma transportf_funextsec_op'
  {σ : signature} {A : algebra σ}
  (D D' : ∏ s : sorts σ, A s → UU)
  (H : ∏ (s: sorts σ), D s = D' s)
  (nm : names σ)
  (base_xs : hvec (vec_map A (arity nm)))
  (opsAnm : (A⋆ (arity nm) → A (sort nm)))
  (f : D (sort nm) (ops A nm base_xs))

  : transportf (λ D0 : ∏ s : sorts σ, A s → UU, D0 (sort nm) (ops A nm base_xs)) (funextsec _ _ _ H) f =
  transportf (λ Ds0 : A (sort nm) -> UU, Ds0 (ops A nm base_xs)) (H (sort nm)) f.
  Proof.
    use transportf_funextsec_op.
    exact (arity nm).
  Defined.