(** * IndProp: Inductively Defined Propositions *)

Require Export Logic.

Require Coq.omega.Omega.

(* ################################################################# *)
(** * Inductively Defined Propositions *)

(** In the [Logic] chapter, we looked at several ways of writing
    propositions, including conjunction, disjunction, and quantifiers.
    In this chapter, we bring a new tool into the mix: _inductive
    definitions_. *)

(** Recall that we have seen two ways of stating that a number [n] is
    even: We can say (1) [evenb n = true], or (2) [exists k, n =
    double k].  Yet another possibility is to say that [n] is even if
    we can establish its evenness from the following rules:

       - Rule [ev_0]:  The number [0] is even.
       - Rule [ev_SS]: If [n] is even, then [S (S n)] is even. *)

(** To illustrate how this definition of evenness works, let's
    imagine using it to show that [4] is even. By rule [ev_SS], it
    suffices to show that [2] is even. This, in turn, is again
    guaranteed by rule [ev_SS], as long as we can show that [0] is
    even. But this last fact follows directly from the [ev_0] rule. *)

(** We will see many definitions like this one during the rest
    of the course.  For purposes of informal discussions, it is
    helpful to have a lightweight notation that makes them easy to
    read and write.  _Inference rules_ are one such notation: *)
(**

                              ------------                        (ev_0)
                                 ev 0

                                  ev n
                             --------------                      (ev_SS)
                              ev (S (S n))
*)

(** Each of the textual rules above is reformatted here as an
    inference rule; the intended reading is that, if the _premises_
    above the line all hold, then the _conclusion_ below the line
    follows.  For example, the rule [ev_SS] says that, if [n]
    satisfies [ev], then [S (S n)] also does.  If a rule has no
    premises above the line, then its conclusion holds
    unconditionally.

    We can represent a proof using these rules by combining rule
    applications into a _proof tree_. Here's how we might transcribe
    the above proof that [4] is even: *)
(**

                             ------  (ev_0)
                              ev 0
                             ------ (ev_SS)
                              ev 2
                             ------ (ev_SS)
                              ev 4
*)

(** Why call this a "tree" (rather than a "stack", for example)?
    Because, in general, inference rules can have multiple premises.
    We will see examples of this below. *)

(** Putting all of this together, we can translate the definition of
    evenness into a formal Coq definition using an [Inductive]
    declaration, where each constructor corresponds to an inference
    rule: *)

Inductive ev : nat -> Prop :=
| ev_0 : ev 0
| ev_SS : forall n : nat, ev n -> ev (S (S n)).

(** This definition is different in one crucial respect from
    previous uses of [Inductive]: its result is not a [Type], but
    rather a function from [nat] to [Prop] -- that is, a property of
    numbers.  Note that we've already seen other inductive definitions
    that result in functions, such as [list], whose type is [Type ->
    Type].  What is new here is that, because the [nat] argument of
    [ev] appears _unnamed_, to the _right_ of the colon, it is allowed
    to take different values in the types of different constructors:
    [0] in the type of [ev_0] and [S (S n)] in the type of [ev_SS].

    In contrast, the definition of [list] names the [X] parameter
    _globally_, to the _left_ of the colon, forcing the result of
    [nil] and [cons] to be the same ([list X]).  Had we tried to bring
    [nat] to the left in defining [ev], we would have seen an error: *)

Fail Inductive wrong_ev (n : nat) : Prop :=
| wrong_ev_0 : wrong_ev 0
| wrong_ev_SS : forall n, wrong_ev n -> wrong_ev (S (S n)).
(* ===> Error: A parameter of an inductive type n is not
        allowed to be used as a bound variable in the type
        of its constructor. *)

(** ("Parameter" here is Coq jargon for an argument on the left of the
    colon in an [Inductive] definition; "index" is used to refer to
    arguments on the right of the colon.) *)

(** We can think of the definition of [ev] as defining a Coq property
    [ev : nat -> Prop], together with primitive theorems [ev_0 : ev 0] and
    [ev_SS : forall n, ev n -> ev (S (S n))]. *)

(** Such "constructor theorems" have the same status as proven
    theorems.  In particular, we can use Coq's [apply] tactic with the
    rule names to prove [ev] for particular numbers... *)

Theorem ev_4 : ev 4.
Proof. apply ev_SS. apply ev_SS. apply ev_0. Qed.

(** ... or we can use function application syntax: *)

Theorem ev_4' : ev 4.
Proof. apply (ev_SS 2 (ev_SS 0 ev_0)). Qed.

(** We can also prove theorems that have hypotheses involving [ev]. *)

Theorem ev_plus4 : forall n, ev n -> ev (4 + n).
Proof.
  intros n. simpl. intros Hn.
  apply ev_SS. apply ev_SS. apply Hn.
Qed.

(** More generally, we can show that any number multiplied by 2 is even: *)

(** **** Exercise: 1 star (ev_double)  *)
Theorem ev_double : forall n,
  ev (double n).
Proof. induction n as [|n IH]. apply ev_0.
  apply ev_SS. apply IH. Qed.

(** [] *)

(* ################################################################# *)
(** * Using Evidence in Proofs *)

(** Besides _constructing_ evidence that numbers are even, we can also
    _reason about_ such evidence.

    Introducing [ev] with an [Inductive] declaration tells Coq not
    only that the constructors [ev_0] and [ev_SS] are valid ways to
    build evidence that some number is even, but also that these two
    constructors are the _only_ ways to build evidence that numbers
    are even (in the sense of [ev]). *)

(** In other words, if someone gives us evidence [E] for the assertion
    [ev n], then we know that [E] must have one of two shapes:

      - [E] is [ev_0] (and [n] is [O]), or
      - [E] is [ev_SS n' E'] (and [n] is [S (S n')], where [E'] is
        evidence for [ev n']). *)

(** This suggests that it should be possible to analyze a hypothesis
    of the form [ev n] much as we do inductively defined data
    structures; in particular, it should be possible to argue by
    _induction_ and _case analysis_ on such evidence.  Let's look at a
    few examples to see what this means in practice. *)

(* ================================================================= *)
(** ** Inversion on Evidence *)

(** Suppose we are proving some fact involving a number [n], and we
    are given [ev n] as a hypothesis.  We already know how to perform
    case analysis on [n] using the [inversion] tactic, generating
    separate subgoals for the case where [n = O] and the case where [n
    = S n'] for some [n'].  But for some proofs we may instead want to
    analyze the evidence that [ev n] _directly_.

    By the definition of [ev], there are two cases to consider:

    - If the evidence is of the form [ev_0], we know that [n = 0].

    - Otherwise, the evidence must have the form [ev_SS n' E'], where
      [n = S (S n')] and [E'] is evidence for [ev n']. *)

(** We can perform this kind of reasoning in Coq, again using
    the [inversion] tactic.  Besides allowing us to reason about
    equalities involving constructors, [inversion] provides a
    case-analysis principle for inductively defined propositions.
    When used in this way, its syntax is similar to [destruct]: We
    pass it a list of identifiers separated by [|] characters to name
    the arguments to each of the possible constructors.  *)

Theorem ev_minus2 : forall n,
  ev n -> ev (pred (pred n)).
Proof.
  intros n E.
  inversion E as [| n' E'].
  - (* E = ev_0 *) simpl. apply ev_0.
  - (* E = ev_SS n' E' *) simpl. apply E'.  Qed.

(** In words, here is how the inversion reasoning works in this proof:

    - If the evidence is of the form [ev_0], we know that [n = 0].
      Therefore, it suffices to show that [ev (pred (pred 0))] holds.
      By the definition of [pred], this is equivalent to showing that
      [ev 0] holds, which directly follows from [ev_0].

    - Otherwise, the evidence must have the form [ev_SS n' E'], where
      [n = S (S n')] and [E'] is evidence for [ev n'].  We must then
      show that [ev (pred (pred (S (S n'))))] holds, which, after
      simplification, follows directly from [E']. *)

(** This particular proof also works if we replace [inversion] by
    [destruct]: *)

Theorem ev_minus2' : forall n,
  ev n -> ev (pred (pred n)).
Proof.
  intros n E.
  destruct E as [| n' E'].
  - (* E = ev_0 *) simpl. apply ev_0.
  - (* E = ev_SS n' E' *) simpl. apply E'.  Qed.

(** The difference between the two forms is that [inversion] is more
    convenient when used on a hypothesis that consists of an inductive
    property applied to a complex expression (as opposed to a single
    variable).  Here's is a concrete example.  Suppose that we wanted
    to prove the following variation of [ev_minus2]: *)

Theorem evSS_ev : forall n,
  ev (S (S n)) -> ev n.

(** Intuitively, we know that evidence for the hypothesis cannot
    consist just of the [ev_0] constructor, since [O] and [S] are
    different constructors of the type [nat]; hence, [ev_SS] is the
    only case that applies.  Unfortunately, [destruct] is not smart
    enough to realize this, and it still generates two subgoals.  Even
    worse, in doing so, it keeps the final goal unchanged, failing to
    provide any useful information for completing the proof.  *)

Proof.
  intros n E.
  destruct E as [| n' E'].
  - (* E = ev_0. *)
    (* We must prove that [n] is even from no assumptions! *)
Abort.

(** What happened, exactly?  Calling [destruct] has the effect of
    replacing all occurrences of the property argument by the values
    that correspond to each constructor.  This is enough in the case
    of [ev_minus2'] because that argument, [n], is mentioned directly
    in the final goal. However, it doesn't help in the case of
    [evSS_ev] since the term that gets replaced ([S (S n)]) is not
    mentioned anywhere. *)

(** The [inversion] tactic, on the other hand, can detect (1) that the
    first case does not apply, and (2) that the [n'] that appears on
    the [ev_SS] case must be the same as [n].  This allows us to
    complete the proof: *)

Theorem evSS_ev : forall n,
  ev (S (S n)) -> ev n.
Proof.
  intros n E.
  inversion E as [| n' E'].
  (* We are in the [E = ev_SS n' E'] case now. *)
  apply E'.
Qed.

(** By using [inversion], we can also apply the principle of explosion
    to "obviously contradictory" hypotheses involving inductive
    properties. For example: *)

Theorem one_not_even : ~ ev 1.
Proof.
  intros H. inversion H. Qed.

(** **** Exercise: 1 star (SSSSev__even)  *)
(** Prove the following result using [inversion]. *)

Theorem SSSSev__even : forall n,
  ev (S (S (S (S n)))) -> ev n.
Proof. intros n H. inversion H as [|n' E'].
  inversion E' as [|n'' E'']. apply E''. Qed.

(** [] *)

(** **** Exercise: 1 star (even5_nonsense)  *)
(** Prove the following result using [inversion]. *)

Theorem even5_nonsense :
  ev 5 -> 2 + 2 = 9.
Proof. intros H. inversion H as [|n E].
 inversion E as [|n' E']. inversion E'. Qed.
   
(** [] *)

(** The way we've used [inversion] here may seem a bit
    mysterious at first.  Until now, we've only used [inversion] on
    equality propositions, to utilize injectivity of constructors or
    to discriminate between different constructors.  But we see here
    that [inversion] can also be applied to analyzing evidence for
    inductively defined propositions.

    Here's how [inversion] works in general.  Suppose the name [I]
    refers to an assumption [P] in the current context, where [P] has
    been defined by an [Inductive] declaration.  Then, for each of the
    constructors of [P], [inversion I] generates a subgoal in which
    [I] has been replaced by the exact, specific conditions under
    which this constructor could have been used to prove [P].  Some of
    these subgoals will be self-contradictory; [inversion] throws
    these away.  The ones that are left represent the cases that must
    be proved to establish the original goal.  For those, [inversion]
    adds all equations into the proof context that must hold of the
    arguments given to [P] (e.g., [S (S n') = n] in the proof of
    [evSS_ev]). *)

(** The [ev_double] exercise above shows that our new notion of
    evenness is implied by the two earlier ones (since, by
    [even_bool_prop] in chapter [Logic], we already know that
    those are equivalent to each other). To show that all three
    coincide, we just need the following lemma: *)

Lemma ev_even_firsttry : forall n,
  ev n -> exists k, n = double k.
Proof.


(** We could try to proceed by case analysis or induction on [n].  But
    since [ev] is mentioned in a premise, this strategy would probably
    lead to a dead end, as in the previous section.  Thus, it seems
    better to first try inversion on the evidence for [ev].  Indeed,
    the first case can be solved trivially. *)

  intros n E. inversion E as [| n' E'].
  - (* E = ev_0 *)
    exists 0. reflexivity.
  - (* E = ev_SS n' E' *) simpl.

(** Unfortunately, the second case is harder.  We need to show [exists
    k, S (S n') = double k], but the only available assumption is
    [E'], which states that [ev n'] holds.  Since this isn't directly
    useful, it seems that we are stuck and that performing case
    analysis on [E] was a waste of time.

    If we look more closely at our second goal, however, we can see
    that something interesting happened: By performing case analysis
    on [E], we were able to reduce the original result to an similar
    one that involves a _different_ piece of evidence for [ev]: [E'].
    More formally, we can finish our proof by showing that

        exists k', n' = double k',

    which is the same as the original statement, but with [n'] instead
    of [n].  Indeed, it is not difficult to convince Coq that this
    intermediate result suffices. *)

    assert (I : (exists k', n' = double k') ->
                (exists k, S (S n') = double k)).
    { intros [k' Hk']. rewrite Hk'. exists (S k'). reflexivity. }
    apply I. (* reduce the original goal to the new one *)

Admitted.

(* ================================================================= *)
(** ** Induction on Evidence *)

(** If this looks familiar, it is no coincidence: We've encountered
    similar problems in the [Induction] chapter, when trying to use
    case analysis to prove results that required induction.  And once
    again the solution is... induction!

    The behavior of [induction] on evidence is the same as its
    behavior on data: It causes Coq to generate one subgoal for each
    constructor that could have used to build that evidence, while
    providing an induction hypotheses for each recursive occurrence of
    the property in question. *)

(** Let's try our current lemma again: *)

Lemma ev_even : forall n,
  ev n -> exists k, n = double k.
Proof.
  intros n E.
  induction E as [|n' E' IH].
  - (* E = ev_0 *)
    exists 0. reflexivity.
  - (* E = ev_SS n' E'
       with IH : exists k', n' = double k' *)
    destruct IH as [k' Hk'].
    rewrite Hk'. exists (S k'). reflexivity.
Qed.

(** Here, we can see that Coq produced an [IH] that corresponds to
    [E'], the single recursive occurrence of [ev] in its own
    definition.  Since [E'] mentions [n'], the induction hypothesis
    talks about [n'], as opposed to [n] or some other number. *)

(** The equivalence between the second and third definitions of
    evenness now follows. *)

Theorem ev_even_iff : forall n,
  ev n <-> exists k, n = double k.
Proof.
  intros n. split.
  - (* -> *) apply ev_even.
  - (* <- *) intros [k Hk]. rewrite Hk. apply ev_double.
Qed.

(** As we will see in later chapters, induction on evidence is a
    recurring technique across many areas, and in particular when
    formalizing the semantics of programming languages, where many
    properties of interest are defined inductively. *)

(** The following exercises provide simple examples of this
    technique, to help you familiarize yourself with it. *)

(** **** Exercise: 2 stars (ev_sum)  *)
Theorem ev_sum : forall n m, ev n -> ev m -> ev (n + m).
Proof. intros n m Hn Hm. induction Hn as [|n' E IH].
  apply Hm.
  apply ev_SS. apply IH. Qed.
  
(** [] *)

(** **** Exercise: 4 stars, advanced, optional (ev'_ev)  *)
(** In general, there may be multiple ways of defining a
    property inductively.  For example, here's a (slightly contrived)
    alternative definition for [ev]: *)

Inductive ev' : nat -> Prop :=
| ev'_0 : ev' 0
| ev'_2 : ev' 2
| ev'_sum : forall n m, ev' n -> ev' m -> ev' (n + m).

(** Prove that this definition is logically equivalent to the old
    one.  (You may want to look at the previous theorem when you get
    to the induction step.) *)

Theorem ev'_ev : forall n, ev' n <-> ev n.
Proof. intros n. split. 
  - intros ev_nm. induction ev_nm.
    apply ev_0. 
    apply ev_SS. apply ev_0.
    apply ev_sum. apply IHev_nm1. apply IHev_nm2.
  - intros ev_n. induction ev_n.
    apply ev'_0.
    apply (ev'_sum 2 n). apply ev'_2. apply IHev_n. Qed.

(** [] *)

(** **** Exercise: 3 stars, advanced, recommended (ev_ev__ev)  *)
(** Finding the appropriate thing to do induction on is a
    bit tricky here: *)

Theorem ev_ev__ev : forall n m,
  ev (n+m) -> ev n -> ev m.
Proof. intros n m ev_nm ev_n. induction ev_n. 
  - apply ev_nm.
  - apply IHev_n. inversion ev_nm. apply H0. Qed.

(** [] *)

(** **** Exercise: 3 stars, optional (ev_plus_plus)  *)
(** This exercise just requires applying existing lemmas.  No
    induction or even case analysis is needed, though some of the
    rewriting may be tedious. *)

Theorem ev_plus_plus : forall n m p,
  ev (n+m) -> ev (n+p) -> ev (m+p).
Proof. intros n m p ev_nm ev_np. apply (ev_ev__ev (double n) (m+p)).
  rewrite double_plus. rewrite <- plus_assoc. rewrite (plus_swap n m p).
  rewrite plus_assoc. apply ev'_ev. apply ev'_sum.
    apply ev'_ev. apply ev_nm.
    apply ev'_ev. apply ev_np. 
  apply ev_double. Qed.

(** [] *)

(* ################################################################# *)
(** * Inductive Relations *)

(** A proposition parameterized by a number (such as [ev])
    can be thought of as a _property_ -- i.e., it defines
    a subset of [nat], namely those numbers for which the proposition
    is provable.  In the same way, a two-argument proposition can be
    thought of as a _relation_ -- i.e., it defines a set of pairs for
    which the proposition is provable. *)

Module Playground.

(** One useful example is the "less than or equal to" relation on
    numbers. *)

(** The following definition should be fairly intuitive.  It
    says that there are two ways to give evidence that one number is
    less than or equal to another: either observe that they are the
    same number, or give evidence that the first is less than or equal
    to the predecessor of the second. *)

Inductive le : nat -> nat -> Prop :=
  | le_n : forall n, le n n
  | le_S : forall n m, (le n m) -> (le n (S m)).

Notation "m <= n" := (le m n).

(** Proofs of facts about [<=] using the constructors [le_n] and
    [le_S] follow the same patterns as proofs about properties, like
    [ev] above. We can [apply] the constructors to prove [<=]
    goals (e.g., to show that [3<=3] or [3<=6]), and we can use
    tactics like [inversion] to extract information from [<=]
    hypotheses in the context (e.g., to prove that [(2 <= 1) ->
    2+2=5].) *)

(** Here are some sanity checks on the definition.  (Notice that,
    although these are the same kind of simple "unit tests" as we gave
    for the testing functions we wrote in the first few lectures, we
    must construct their proofs explicitly -- [simpl] and
    [reflexivity] don't do the job, because the proofs aren't just a
    matter of simplifying computations.) *)

Theorem test_le1 :
  3 <= 3.
Proof.
  (* WORKED IN CLASS *)
  apply le_n.  Qed.

Theorem test_le2 :
  3 <= 6.
Proof.
  (* WORKED IN CLASS *)
  apply le_S. apply le_S. apply le_S. apply le_n.  Qed.

Theorem test_le3 :
  (2 <= 1) -> 2 + 2 = 5.
Proof.
  (* WORKED IN CLASS *)
  intros H. inversion H. inversion H2.  Qed.

(** The "strictly less than" relation [n < m] can now be defined
    in terms of [le]. *)

End Playground.

Definition lt (n m:nat) := le (S n) m.

Notation "m < n" := (lt m n).

(** Here are a few more simple relations on numbers: *)

Inductive square_of : nat -> nat -> Prop :=
  | sq : forall n:nat, square_of n (n * n).

Inductive next_nat : nat -> nat -> Prop :=
  | nn : forall n:nat, next_nat n (S n).

Inductive next_even : nat -> nat -> Prop :=
  | ne_1 : forall n, ev (S n) -> next_even n (S n)
  | ne_2 : forall n, ev (S (S n)) -> next_even n (S (S n)).

(** **** Exercise: 2 stars, optional (total_relation)  *)
(** Define an inductive binary relation [total_relation] that holds
    between every pair of natural numbers. *)

Inductive total_relation : nat -> nat -> Prop :=
  | te : forall n m, total_relation n m.

(** [] *)

(** **** Exercise: 2 stars, optional (empty_relation)  *)
(** Define an inductive binary relation [empty_relation] (on numbers)
    that never holds. *)

Inductive empty_relation : nat -> nat -> Prop :=.


(** [] *)

(** **** Exercise: 3 stars, optional (le_exercises)  *)
(** Here are a number of facts about the [<=] and [<] relations that
    we are going to need later in the course.  The proofs make good
    practice exercises. *)

Lemma le_trans : forall m n o, m <= n -> n <= o -> m <= o.
Proof. intros m n o le_mn le_no. induction le_no as [|o']. 
  - apply le_mn.
  - apply le_S. apply IHle_no.
Qed.

Theorem O_le_n : forall n,
  0 <= n.
Proof. induction n. apply le_n. apply le_S. apply IHn. Qed.

Theorem n_le_m__Sn_le_Sm : forall n m,
  n <= m -> S n <= S m.
Proof. intros n m le. induction le.
  apply le_n. apply le_S. apply IHle. Qed.

Theorem Sn_le_Sm__n_le_m : forall n m,
  S n <= S m -> n <= m.
Proof. intros n m le. inversion le.
  apply le_n. apply le_trans with (n:=(S n)). 
  apply le_S. apply le_n. apply H0. Qed.

Theorem le_plus_l : forall a b,
  a <= a + b.
Proof. intros a b. induction a as [|a IH].
  - apply O_le_n. 
  - apply n_le_m__Sn_le_Sm. apply IH. Qed.

Theorem plus_lt : forall n1 n2 m,
  n1 + n2 < m ->
  n1 < m /\ n2 < m.
Proof. 
  unfold lt. intros n1 n2 m H. split.
  - apply le_trans with (n:= S (n1) + n2).
    apply le_plus_l. apply H.
  - apply le_trans with (n:= S (n2) + n1).
    apply le_plus_l. rewrite plus_comm in H. apply H. Qed.

Theorem lt_S : forall n m,
  n < m ->
  n < S m.
Proof. intros n m H. apply le_S. apply H. Qed.

Theorem leb_complete : forall n m,
  leb n m = true -> n <= m.
Proof. induction n as [|n IH].
  - intros m H. apply O_le_n.
  - intros m. destruct m. 
    intros H. inversion H.
    intros H. apply n_le_m__Sn_le_Sm. apply IH. apply H. Qed.

(** Hint: The next one may be easiest to prove by induction on [m]. *)

Theorem leb_correct : forall n m,
  n <= m ->
  leb n m = true.
Proof. intros n m. generalize dependent n. induction m as [|m IH].
  - intros n H. inversion H. reflexivity. 
  - intros n H. destruct n. 
    + reflexivity. 
    + apply IH. apply Sn_le_Sm__n_le_m. apply H. Qed.

(** [] *)

(** **** Exercise: 2 stars, optional (leb_iff)  *)
Theorem leb_iff : forall n m,
  leb n m = true <-> n <= m.
Proof. intros n m. split. apply leb_complete. apply leb_correct. Qed. 

(** Hint: This theorem can easily be proved without using [induction]. *)

Theorem leb_true_trans : forall n m o,
  leb n m = true -> leb m o = true -> leb n o = true.
Proof. intros n m o. rewrite leb_iff, leb_iff, leb_iff.
  apply le_trans. Qed.

(** [] *)

Module R.

(** **** Exercise: 3 stars, recommended (R_provability)  *)
(** We can define three-place relations, four-place relations,
    etc., in just the same way as binary relations.  For example,
    consider the following three-place relation on numbers: *)

Inductive R : nat -> nat -> nat -> Prop :=
   | c1 : R 0 0 0
   | c2 : forall m n o, R m n o -> R (S m) n (S o)
   | c3 : forall m n o, R m n o -> R m (S n) (S o)
   | c4 : forall m n o, R (S m) (S n) (S (S o)) -> R m n o
   | c5 : forall m n o, R m n o -> R n m o.

(** - Which of the following propositions are provable?
      - [R 1 1 2]
      - [R 2 2 6]

    - If we dropped constructor [c5] from the definition of [R],
      would the set of provable propositions change?  Briefly (1
      sentence) explain your answer.

    - If we dropped constructor [c4] from the definition of [R],
      would the set of provable propositions change?  Briefly (1
      sentence) explain your answer.

[R 1 1 2]

(forall a b c, R a b c <-> a + b = c) holds even we drop c4, c5.
 
*)
(** [] *)

(** **** Exercise: 3 stars, optional (R_fact)  *)
(** The relation [R] above actually encodes a familiar function.
    Figure out which function; then state and prove this equivalence
    in Coq? *)

Definition fR : nat -> nat -> nat :=
  plus.
  
Theorem R_equiv_fR : forall m n o, R m n o <-> m + n = o.
Proof. intros m n o. split. 
  - intros H. induction H. 
    + reflexivity.
    + rewrite <- IHR. reflexivity.
    + rewrite <- plus_n_Sm, IHR. reflexivity.
    + rewrite <- plus_n_Sm in IHR. inversion IHR. reflexivity.
    + rewrite plus_comm. apply IHR.
  - generalize dependent m. 
    generalize dependent n.
    induction o. 
      + intros n m H. apply and_exercise in H.
        inversion H. inversion H0. inversion H1. apply c1.
      + intros n [|m]. 
          simpl.  intros H. rewrite H.
          assert (H2: forall k, R 0 k k).
          { induction k. apply c1. apply c3. apply IHk. }
          apply H2.
        
          intros H. apply c2. apply IHo. inversion H. 
          reflexivity. Qed.

(** [] *)

End R.

(** **** Exercise: 4 stars, advanced (subsequence)  *)
(** A list is a _subsequence_ of another list if all of the elements
    in the first list occur in the same order in the second list,
    possibly with some extra elements in between. For example,

      [1;2;3]

    is a subsequence of each of the lists

      [1;2;3]
      [1;1;1;2;2;3]
      [1;2;7;3]
      [5;6;1;9;9;2;7;3;8]

    but it is _not_ a subsequence of any of the lists

      [1;2]
      [1;3]
      [5;6;2;1;7;3;8].

    - Define an inductive proposition [subseq] on [list nat] that
      captures what it means to be a subsequence. (Hint: You'll need
      three cases.)

    - Prove [subseq_refl] that subsequence is reflexive, that is,
      any list is a subsequence of itself.

    - Prove [subseq_app] that for any lists [l1], [l2], and [l3],
      if [l1] is a subsequence of [l2], then [l1] is also a subsequence
      of [l2 ++ l3].

    - (Optional, harder) Prove [subseq_trans] that subsequence is
      transitive -- that is, if [l1] is a subsequence of [l2] and [l2]
      is a subsequence of [l3], then [l1] is a subsequence of [l3].
      Hint: choose your induction carefully! *)


Inductive subseq: list nat -> list nat -> Prop :=
  | sq_empty : forall l, subseq [] l
  | sq_1 : forall h l1 l2, subseq l1 l2 -> subseq l1 (h::l2)
  | sq_2 : forall h l1 l2, subseq l1 l2 -> subseq (h::l1) (h::l2).
(*
Theorem subseq_refl : forall l,
  subseq l l.
Proof. induction l as [|h l IH]. 
  - apply sq_empty.
  - apply sq_2. apply IH. Qed.

Theorem subseq_app : forall l1 l2 l3,
  subseq l1 l2 -> subseq l1 (l2 ++ l3).
Proof. intros l1 l2 l3 sq. induction sq.
  apply sq_empty.
  apply sq_1. apply IHsq.
  apply sq_2. apply IHsq. Qed.

Theorem sss : forall x y z, 
      subseq (x++y) z -> subseq y z.
      Proof. intros x y z. generalize dependent y. 
generalize dependent z.  induction x as [|h x IH].
       intros z y sq. apply sq.
       intros z y sq. apply IH. 
       inversion sq.
       inversion sq. Abort.

Lemma head_sub : forall h t l, l = h :: t ->
  subseq t l.
Proof. intros h t l H. rewrite H. apply sq_1. 
  apply subseq_refl. Qed. 

Theorem subsh : forall h y z a b,
  subseq (h::y) z -> z = a ++ (h :: b).
Proof. Admitted.

Theorem subseq_trans : forall l1 l2 l3, 
  subseq l1 l2 -> subseq l2 l3 -> subseq l1 l3.
Proof. intros l1 l2 l3 sq.
  generalize dependent l3.
  induction sq. 
  - intros H H2. apply sq_empty.
  - intros l3 H. apply IHsq. 
      Abort.

Theorem subseq_trans2 : forall l1 l2 l3, 
  subseq l2 l3 -> subseq l1 l2 -> subseq l1 l3.
Proof. intros l1 l2 l3 sq23. induction sq23.
  *)


 
(** [] *)

(** **** Exercise: 2 stars, optional (R_provability2)  *)
(** Suppose we give Coq the following definition:

    Inductive R : nat -> list nat -> Prop :=
      | c1 : R 0 []
      | c2 : forall n l, R n l -> R (S n) (n :: l)
      | c3 : forall n l, R (S n) l -> R n l.

    Which of the following propositions are provable?

    - [R 2 [1;0]]
    - [R 1 [1;2;1;0]]
    - [R 6 [3;2;1;0]]  *)

(*
    - [R 2 [1;0]]
    - [R 1 [1;2;1;0]]
*)

(** [] *)


(* ################################################################# *)
(** * Case Study: Regular Expressions *)

(** The [ev] property provides a simple example for illustrating
    inductive definitions and the basic techniques for reasoning about
    them, but it is not terribly exciting -- after all, it is
    equivalent to the two non-inductive definitions of evenness that
    we had already seen, and does not seem to offer any concrete
    benefit over them.  To give a better sense of the power of
    inductive definitions, we now show how to use them to model a
    classic concept in computer science: _regular expressions_. *)

(** Regular expressions are a simple language for describing strings,
    defined as follows: *)

Inductive reg_exp {T : Type} : Type :=
| EmptySet : reg_exp
| EmptyStr : reg_exp
| Char : T -> reg_exp
| App : reg_exp -> reg_exp -> reg_exp
| Union : reg_exp -> reg_exp -> reg_exp
| Star : reg_exp -> reg_exp.

(** Note that this definition is _polymorphic_: Regular
    expressions in [reg_exp T] describe strings with characters drawn
    from [T] -- that is, lists of elements of [T].

    (We depart slightly from standard practice in that we do not
    require the type [T] to be finite.  This results in a somewhat
    different theory of regular expressions, but the difference is not
    significant for our purposes.) *)

(** We connect regular expressions and strings via the following
    rules, which define when a regular expression _matches_ some
    string:

      - The expression [EmptySet] does not match any string.

      - The expression [EmptyStr] matches the empty string [[]].

      - The expression [Char x] matches the one-character string [[x]].

      - If [re1] matches [s1], and [re2] matches [s2], then [App re1
        re2] matches [s1 ++ s2].

      - If at least one of [re1] and [re2] matches [s], then [Union re1
        re2] matches [s].

      - Finally, if we can write some string [s] as the concatenation of
        a sequence of strings [s = s_1 ++ ... ++ s_k], and the
        expression [re] matches each one of the strings [s_i], then
        [Star re] matches [s].

        As a special case, the sequence of strings may be empty, so
        [Star re] always matches the empty string [[]] no matter what
        [re] is. *)

(** We can easily translate this informal definition into an
    [Inductive] one as follows: *)

Inductive exp_match {T} : list T -> (@reg_exp T) -> Prop :=
| MEmpty : exp_match [] EmptyStr
| MChar : forall x, exp_match [x] (Char x)
| MApp : forall s1 re1 s2 re2,
           exp_match s1 re1 ->
           exp_match s2 re2 ->
           exp_match (s1 ++ s2) (App re1 re2)
| MUnionL : forall s1 re1 re2,
              exp_match s1 re1 ->
              exp_match s1 (Union re1 re2)
| MUnionR : forall re1 s2 re2,
              exp_match s2 re2 ->
              exp_match s2 (Union re1 re2)
| MStar0 : forall re, exp_match [] (Star re)
| MStarApp : forall s1 s2 re,
               exp_match s1 re ->
               exp_match s2 (Star re) ->
               exp_match (s1 ++ s2) (Star re).

(** Again, for readability, we can also display this definition using
    inference-rule notation.  At the same time, let's introduce a more
    readable infix notation. *)

Notation "s =~ re" := (exp_match s re) (at level 80).


(**

                          ----------------                    (MEmpty)
                           [] =~ EmptyStr

                          ---------------                      (MChar)
                           [x] =~ Char x

                       s1 =~ re1    s2 =~ re2
                      -------------------------                 (MApp)
                       s1 ++ s2 =~ App re1 re2

                              s1 =~ re1
                        ---------------------                (MUnionL)
                         s1 =~ Union re1 re2

                              s2 =~ re2
                        ---------------------                (MUnionR)
                         s2 =~ Union re1 re2

                          ---------------                     (MStar0)
                           [] =~ Star re

                      s1 =~ re    s2 =~ Star re
                     ---------------------------            (MStarApp)
                        s1 ++ s2 =~ Star re
*)

(** Notice that these rules are not _quite_ the same as the informal
    ones that we gave at the beginning of the section.  First, we
    don't need to include a rule explicitly stating that no string
    matches [EmptySet]; we just don't happen to include any rule that
    would have the effect of some string matching [EmptySet].  (Indeed,
    the syntax of inductive definitions doesn't even _allow_ us to
    give such a "negative rule.")

    Second, the informal rules for [Union] and [Star] correspond
    to two constructors each: [MUnionL] / [MUnionR], and [MStar0] /
    [MStarApp].  The result is logically equivalent to the original
    rules but more convenient to use in Coq, since the recursive
    occurrences of [exp_match] are given as direct arguments to the
    constructors, making it easier to perform induction on evidence.
    (The [exp_match_ex1] and [exp_match_ex2] exercises below ask you
    to prove that the constructors given in the inductive declaration
    and the ones that would arise from a more literal transcription of
    the informal rules are indeed equivalent.)

    Let's illustrate these rules with a few examples. *)

Example reg_exp_ex1 : [1] =~ Char 1.
Proof.
  apply MChar.
Qed.

Example reg_exp_ex2 : [1; 2] =~ App (Char 1) (Char 2).
Proof.
  apply (MApp [1] _ [2]).
  - apply MChar.
  - apply MChar.
Qed.

(** (Notice how the last example applies [MApp] to the strings [[1]]
    and [[2]] directly.  Since the goal mentions [[1; 2]] instead of
    [[1] ++ [2]], Coq wouldn't be able to figure out how to split the
    string on its own.)

    Using [inversion], we can also show that certain strings do _not_
    match a regular expression: *)

Example reg_exp_ex3 : ~ ([1; 2] =~ Char 1).
Proof.
  intros H. inversion H.
Qed.

(** We can define helper functions for writing down regular
    expressions. The [reg_exp_of_list] function constructs a regular
    expression that matches exactly the list that it receives as an
    argument: *)

Fixpoint reg_exp_of_list {T} (l : list T) :=
  match l with
  | [] => EmptyStr
  | x :: l' => App (Char x) (reg_exp_of_list l')
  end.

Example reg_exp_ex4 : [1; 2; 3] =~ reg_exp_of_list [1; 2; 3].
Proof.
  simpl. apply (MApp [1]).
  { apply MChar. }
  apply (MApp [2]).
  { apply MChar. }
  apply (MApp [3]).
  { apply MChar. }
  apply MEmpty.
Qed.

(** We can also prove general facts about [exp_match].  For instance,
    the following lemma shows that every string [s] that matches [re]
    also matches [Star re]. *)

Lemma MStar1 :
  forall T s (re : @reg_exp T) ,
    s =~ re ->
    s =~ Star re.
Proof.
  intros T s re H.
  rewrite <- (app_nil_r _ s).
  apply (MStarApp s [] re).
  - apply H.
  - apply MStar0.
Qed.

(** (Note the use of [app_nil_r] to change the goal of the theorem to
    exactly the same shape expected by [MStarApp].) *)

(** **** Exercise: 3 stars (exp_match_ex1)  *)
(** The following lemmas show that the informal matching rules given
    at the beginning of the chapter can be obtained from the formal
    inductive definition. *)

Lemma empty_is_empty : forall T (s : list T),
  ~ (s =~ EmptySet).
Proof. intros T s H. inversion H. Qed.

Lemma MUnion' : forall T (s : list T) (re1 re2 : @reg_exp T),
  s =~ re1 \/ s =~ re2 ->
  s =~ Union re1 re2.
Proof. intros T s re1 re2 [H|H]. 
  apply MUnionL. apply H. 
  apply MUnionR. apply H. 
Qed.

(** The next lemma is stated in terms of the [fold] function from the
    [Poly] chapter: If [ss : list (list T)] represents a sequence of
    strings [s1, ..., sn], then [fold app ss []] is the result of
    concatenating them all together. *)

Lemma MStar' : forall T (ss : list (list T)) (re : reg_exp),
  (forall s, In s ss -> s =~ re) ->
  fold app ss [] =~ Star re.
Proof. intros T ss re H. induction ss as [|h ss IH].
  apply MStar0.
  apply (MStarApp h (fold app ss []) re).
  - apply H. left. reflexivity.
  - apply IH. intros s H2. apply H. right. apply H2. Qed. 

(** [] *)

(** **** Exercise: 4 stars, optional (reg_exp_of_list_spec)  *)
(** Prove that [reg_exp_of_list] satisfies the following
    specification: *)

Lemma reg_exp_of_list_spec : forall T (s1 s2 : list T),
  s1 =~ reg_exp_of_list s2 <-> s1 = s2.
Proof. intros T s1. induction s1 as [|h s1 IH].
  - intros s2. split. 
    + destruct s2.
      intros H. reflexivity.
      { simpl. intros H. inversion H. inversion H3. rewrite <- H5 in H0.
        inversion H0. }
    + intros H. rewrite <- H. apply MEmpty.
  - intros s2. split.
    + destruct s2. 
      simpl. intros H. inversion H.
      { simpl. intros H. inversion H. inversion H3. 
        rewrite <- H5 in H0. inversion H0. apply f_equal.
        apply IH. rewrite <- H9. apply H4. }
    + destruct s2. 
      intros H. inversion H.
      intros H. inversion H.
      rewrite <- H2. 
        apply (MApp [t] _ s1 _). apply MChar. apply IH. reflexivity. Qed.
    

(** [] *)

(** Since the definition of [exp_match] has a recursive
    structure, we might expect that proofs involving regular
    expressions will often require induction on evidence. *)


(** For example, suppose that we wanted to prove the following
    intuitive result: If a regular expression [re] matches some string
    [s], then all elements of [s] must occur as character literals
    somewhere in [re].

    To state this theorem, we first define a function [re_chars] that
    lists all characters that occur in a regular expression: *)

Fixpoint re_chars {T} (re : reg_exp) : list T :=
  match re with
  | EmptySet => []
  | EmptyStr => []
  | Char x => [x]
  | App re1 re2 => re_chars re1 ++ re_chars re2
  | Union re1 re2 => re_chars re1 ++ re_chars re2
  | Star re => re_chars re
  end.

(** We can then phrase our theorem as follows: *)

Theorem in_re_match : forall T (s : list T) (re : reg_exp) (x : T),
  s =~ re ->
  In x s ->
  In x (re_chars re).
Proof.
  intros T s re x Hmatch Hin.
  induction Hmatch
    as [| x'
        | s1 re1 s2 re2 Hmatch1 IH1 Hmatch2 IH2
        | s1 re1 re2 Hmatch IH | re1 s2 re2 Hmatch IH
        | re | s1 s2 re Hmatch1 IH1 Hmatch2 IH2].
  (* WORKED IN CLASS *)
  - (* MEmpty *)
    apply Hin.
  - (* MChar *)
    apply Hin.
  - simpl. rewrite In_app_iff in *.
    destruct Hin as [Hin | Hin].
    + (* In x s1 *)
      left. apply (IH1 Hin).
    + (* In x s2 *)
      right. apply (IH2 Hin).
  - (* MUnionL *)
    simpl. rewrite In_app_iff.
    left. apply (IH Hin).
  - (* MUnionR *)
    simpl. rewrite In_app_iff.
    right. apply (IH Hin).
  - (* MStar0 *)
    destruct Hin.

(** Something interesting happens in the [MStarApp] case.  We obtain
    _two_ induction hypotheses: One that applies when [x] occurs in
    [s1] (which matches [re]), and a second one that applies when [x]
    occurs in [s2] (which matches [Star re]).  This is a good
    illustration of why we need induction on evidence for [exp_match],
    as opposed to [re]: The latter would only provide an induction
    hypothesis for strings that match [re], which would not allow us
    to reason about the case [In x s2]. *)

  - (* MStarApp *)
    simpl. rewrite In_app_iff in Hin.
    destruct Hin as [Hin | Hin].
    + (* In x s1 *)
      apply (IH1 Hin).
    + (* In x s2 *)
      apply (IH2 Hin).
Qed.

(** **** Exercise: 4 stars (re_not_empty)  *)
(** Write a recursive function [re_not_empty] that tests whether a
    regular expression matches some string. Prove that your function
    is correct. *)

Fixpoint re_not_empty {T : Type} (re : @reg_exp T) : bool :=
  match re with
  | EmptySet => false
  | EmptyStr => true
  | Char t => true
  | App X Y => (re_not_empty X) && (re_not_empty Y)
  | Union X Y => (re_not_empty X) || (re_not_empty Y)
  | Star X => true
  end.

Lemma re_not_empty_correct : forall T (re : @reg_exp T),
  (exists s, s =~ re) <-> re_not_empty re = true.
Proof. intros T re. split.
  + intros [e E]. induction E.
    - reflexivity.
    - reflexivity.
    - simpl. rewrite IHE1. apply IHE2.
    - simpl. rewrite IHE. reflexivity.
    - simpl. rewrite orb_true_iff. right. apply IHE.
    - reflexivity.
    - reflexivity.
  + intros H. induction re.
    - inversion H.
    - exists []. apply MEmpty.
    - exists [t]. apply MChar.
    - simpl in H. rewrite andb_true_iff in H. destruct H as [H1 H2].
      apply IHre1 in H1. apply IHre2 in H2. 
      destruct H1 as [s1 S1]. destruct H2 as [s2 S2].
      exists (s1++s2). apply MApp.
        apply S1. 
        apply S2.
    - simpl in H. rewrite orb_true_iff in H. destruct H as [H|H].
      apply IHre1 in H. destruct H as [s S]. 
      exists s. apply MUnionL. apply S.
      apply IHre2 in H. destruct H as [s S].
      exists s. apply MUnionR. apply S.
    - exists []. apply MStar0. Qed.

(** [] *)

(* ================================================================= *)
(** ** The [remember] Tactic *)

(** One potentially confusing feature of the [induction] tactic is
    that it happily lets you try to set up an induction over a term
    that isn't sufficiently general.  The effect of this is to lose
    information (much as [destruct] can do), and leave you unable to
    complete the proof.  Here's an example: *)

Lemma star_app: forall T (s1 s2 : list T) (re : @reg_exp T),
  s1 =~ Star re ->
  s2 =~ Star re ->
  s1 ++ s2 =~ Star re.
Proof.
  intros T s1 s2 re H1.

(** Just doing an [inversion] on [H1] won't get us very far in
    the recursive cases. (Try it!). So we need induction (on
    evidence!). Here is a naive first attempt: *)

  induction H1
    as [|x'|s1 re1 s2' re2 Hmatch1 IH1 Hmatch2 IH2
        |s1 re1 re2 Hmatch IH|re1 s2' re2 Hmatch IH
        |re''|s1 s2' re'' Hmatch1 IH1 Hmatch2 IH2].

(** But now, although we get seven cases (as we would expect from the
    definition of [exp_match]), we have lost a very important bit of
    information from [H1]: the fact that [s1] matched something of the
    form [Star re].  This means that we have to give proofs for _all_
    seven constructors of this definition, even though all but two of
    them ([MStar0] and [MStarApp]) are contradictory.  We can still
    get the proof to go through for a few constructors, such as
    [MEmpty]... *)

  - (* MEmpty *)
    simpl. intros H. apply H.

(** ... but most cases get stuck.  For [MChar], for instance, we
    must show that

    s2 =~ Char x' -> x' :: s2 =~ Char x',

    which is clearly impossible. *)

  - (* MChar. Stuck... *)
Abort.

(** The problem is that [induction] over a Prop hypothesis only works
    properly with hypotheses that are completely general, i.e., ones
    in which all the arguments are variables, as opposed to more
    complex expressions, such as [Star re].

    (In this respect, [induction] on evidence behaves more like
    [destruct] than like [inversion].)

    We can solve this problem by generalizing over the problematic
    expressions with an explicit equality: *)

Lemma star_app: forall T (s1 s2 : list T) (re re' : reg_exp),
  re' = Star re ->
  s1 =~ re' ->
  s2 =~ Star re ->
  s1 ++ s2 =~ Star re.

(** We can now proceed by performing induction over evidence directly,
    because the argument to the first hypothesis is sufficiently
    general, which means that we can discharge most cases by inverting
    the [re' = Star re] equality in the context.

    This idiom is so common that Coq provides a tactic to
    automatically generate such equations for us, avoiding thus the
    need for changing the statements of our theorems. *)

Abort.

(** Invoking the tactic [remember e as x] causes Coq to (1) replace
    all occurrences of the expression [e] by the variable [x], and (2)
    add an equation [x = e] to the context.  Here's how we can use it
    to show the above result: *)

Lemma star_app: forall T (s1 s2 : list T) (re : reg_exp),
  s1 =~ Star re ->
  s2 =~ Star re ->
  s1 ++ s2 =~ Star re.
Proof.
  intros T s1 s2 re H1.
  remember (Star re) as re'.

(** We now have [Heqre' : re' = Star re]. *)

  generalize dependent s2.
  induction H1
    as [|x'|s1 re1 s2' re2 Hmatch1 IH1 Hmatch2 IH2
        |s1 re1 re2 Hmatch IH|re1 s2' re2 Hmatch IH
        |re''|s1 s2' re'' Hmatch1 IH1 Hmatch2 IH2].

(** The [Heqre'] is contradictory in most cases, which allows us to
    conclude immediately. *)

  - (* MEmpty *)  inversion Heqre'.
  - (* MChar *)   inversion Heqre'.
  - (* MApp *)    inversion Heqre'.
  - (* MUnionL *) inversion Heqre'.
  - (* MUnionR *) inversion Heqre'.

(** The interesting cases are those that correspond to [Star].  Note
    that the induction hypothesis [IH2] on the [MStarApp] case
    mentions an additional premise [Star re'' = Star re'], which
    results from the equality generated by [remember]. *)

  - (* MStar0 *)
    inversion Heqre'. intros s H. apply H.

  - (* MStarApp *)
    inversion Heqre'. rewrite H0 in IH2, Hmatch1.
    intros s2 H1. rewrite <- app_assoc.
    apply MStarApp.
    + apply Hmatch1.
    + apply IH2.
      * reflexivity.
      * apply H1.
Qed.

(** **** Exercise: 4 stars, optional (exp_match_ex2)  *)

(** The [MStar''] lemma below (combined with its converse, the
    [MStar'] exercise above), shows that our definition of [exp_match]
    for [Star] is equivalent to the informal one given previously. *)

Lemma MStar'' : forall T (s : list T) (re : reg_exp),
  s =~ Star re ->
  exists ss : list (list T),
    s = fold app ss []
    /\ forall s', In s' ss -> s' =~ re.
Proof. intros T s re H. remember (Star re) as rex eqn:Heq. 
  induction H. 
  - inversion Heq.
  - inversion Heq.
  - inversion Heq.
  - inversion Heq.
  - inversion Heq.
  - exists []. split. 
    + reflexivity.
    + intros s' contra. inversion contra.
  - inversion Heq. apply IHexp_match2 in Heq. destruct Heq as [ss [He1 He2]].
    exists (s1 :: ss).
    split.
    + simpl. rewrite He1. reflexivity.
    + intros s. simpl. intros [Hx|Hx].
      * rewrite <- Hx, <- H2. apply H.
      * apply He2. apply Hx.
Qed.

(** [] *)

(** **** Exercise: 5 stars, advanced (pumping)  *)
(** One of the first really interesting theorems in the theory of
    regular expressions is the so-called _pumping lemma_, which
    states, informally, that any sufficiently long string [s] matching
    a regular expression [re] can be "pumped" by repeating some middle
    section of [s] an arbitrary number of times to produce a new
    string also matching [re].

    To begin, we need to define "sufficiently long."  Since we are
    working in a constructive logic, we actually need to be able to
    calculate, for each regular expression [re], the minimum length
    for strings [s] to guarantee "pumpability." *)

Module Pumping.

Fixpoint pumping_constant {T} (re : @reg_exp T) : nat :=
  match re with
  | EmptySet => 0
  | EmptyStr => 1
  | Char _ => 2
  | App re1 re2 =>
      pumping_constant re1 + pumping_constant re2
  | Union re1 re2 =>
      pumping_constant re1 + pumping_constant re2
  | Star _ => 1
  end.

(** Next, it is useful to define an auxiliary function that repeats a
    string (appends it to itself) some number of times. *)

Fixpoint napp {T} (n : nat) (l : list T) : list T :=
  match n with
  | 0 => []
  | S n' => l ++ napp n' l
  end.

Lemma napp_plus: forall T (n m : nat) (l : list T),
  napp (n + m) l = napp n l ++ napp m l.
Proof.
  intros T n m l.
  induction n as [|n IHn].
  - reflexivity.
  - simpl. rewrite IHn, app_assoc. reflexivity.
Qed.

(** Now, the pumping lemma itself says that, if [s =~ re] and if the
    length of [s] is at least the pumping constant of [re], then [s]
    can be split into three substrings [s1 ++ s2 ++ s3] in such a way
    that [s2] can be repeated any number of times and the result, when
    combined with [s1] and [s3] will still match [re].  Since [s2] is
    also guaranteed not to be the empty string, this gives us
    a (constructive!) way to generate strings matching [re] that are
    as long as we like. *)

Lemma pump_lemma : forall T (s:list T) re m, 
  s =~ re ->
  napp m s =~ Star re.
Proof. intros T s re m. induction m as [|m].
  intros H. simpl. apply MStar0.
  intros H. simpl. apply MStarApp.
  apply H. apply IHm. apply H. Qed.

Lemma pumping : forall T (re : @reg_exp T) s,
  s =~ re ->
  pumping_constant re <= length s ->
  exists s1 s2 s3,
    s = s1 ++ s2 ++ s3 /\
    s2 <> [] /\
    forall m, s1 ++ napp m s2 ++ s3 =~ re.

(** To streamline the proof (which you are to fill in), the [omega]
    tactic, which is enabled by the following [Require], is helpful in
    several places for automatically completing tedious low-level
    arguments involving equalities or inequalities over natural
    numbers.  We'll return to [omega] in a later chapter, but feel
    free to experiment with it now if you like.  The first case of the
    induction gives an example of how it is used. *)

Import Coq.omega.Omega.

Proof.
  intros T re s Hmatch.
  induction Hmatch
    as [ | x | s1 re1 s2 re2 Hmatch1 IH1 Hmatch2 IH2
       | s1 re1 re2 Hmatch IH | re1 s2 re2 Hmatch IH
       | re | s1 s2 re Hmatch1 IH1 Hmatch2 IH2 ].
  - (* MEmpty *)
    simpl. omega.
  - simpl. omega.
  - simpl. rewrite app_length.
    intros H. 
    assert (Ha: forall a b c d,
      (a + b) <= (c + d) -> (a <= c) \/ (b <= d)).
      intros a b c d. omega.
    apply Ha in H. destruct H as [H|H].
    * apply IH1 in H. destruct H as [s11 [s12 [s13 [H1 [H2 H3]]]]].
      exists s11, s12, (s13 ++ s2). split.
      + rewrite H1. rewrite <- (app_assoc T s11 (s12 ++ s13)).
        rewrite <- app_assoc. reflexivity.
      + split. apply H2.
        intros m. rewrite app_assoc, 
          app_assoc, <- (app_assoc T _ _ s13). apply MApp.
        apply H3. 
        apply Hmatch2.
    * apply IH2 in H. destruct H as [s21 [s22 [s23 [H1 [H2 H3]]]]].
      exists (s1++s21), s22, s23. split.
      + rewrite H1. rewrite app_assoc. reflexivity.
      + split. apply H2. 
        intros n. rewrite <- app_assoc. apply MApp.
        apply Hmatch1.
        apply H3. 
  - intros H. simpl in H.
    assert (H2: pumping_constant re1 <= length s1).
      {apply le_trans with (m:=(pumping_constant re1 + pumping_constant re2)).
       apply le_plus_l. apply H. }
    apply IH in H2. destruct H2 as [s2 [s3 [s4 [Ha [Hb Hc]]]]].
    exists s2, s3, s4. split. apply Ha. split. apply Hb. 
    intros m. apply MUnionL. apply Hc.
  - intros H. simpl in H. 
    assert (H2: pumping_constant re2 <= length s2).
      {apply le_trans with (m:=(pumping_constant re1 + pumping_constant re2)).
       rewrite plus_comm. apply le_plus_l. apply H. }
    apply IH in H2. destruct H2 as [s1 [s3 [s4 [Ha [Hb Hc]]]]].
    exists s1, s3, s4. split. apply Ha. split. apply Hb. 
    intros m. apply MUnionR. apply Hc.
  - intros H. inversion H.
  - destruct s2. 
    * intros H. exists [], s1, [].
      rewrite app_nil_r in *. split. reflexivity.
      split. 
      + intros Hx.
        rewrite Hx in H. inversion H.
      + simpl. intros m. rewrite app_nil_r.
        apply pump_lemma. apply Hmatch1.
    * assert (H: pumping_constant (Star re) <= length (t :: s2)).
        { apply n_le_m__Sn_le_Sm. apply O_le_n. }
      apply IH2 in H. 
      destruct H as [s21 [s22 [s23 [Ha [Hb Hc]]]]].
      intros H'. exists (s1++s21), s22, s23.
      rewrite Ha. rewrite <- (app_assoc T (s1)). split. reflexivity.
      split. apply Hb. intros m. rewrite <- (app_assoc T (s1)).
      apply MStarApp. apply Hmatch1. apply Hc. Qed.

End Pumping.
(** [] *)

(* ################################################################# *)
(** * Case Study: Improving Reflection *)

(** We've seen in the [Logic] chapter that we often need to
    relate boolean computations to statements in [Prop].  But
    performing this conversion as we did it there can result in
    tedious proof scripts.  Consider the proof of the following
    theorem: *)

Theorem filter_not_empty_In : forall n l,
  filter (beq_nat n) l <> [] ->
  In n l.
Proof.
  intros n l. induction l as [|m l' IHl'].
  - (* l = [] *)
    simpl. intros H. apply H. reflexivity.
  - (* l = m :: l' *)
    simpl. destruct (beq_nat n m) eqn:H.
    + (* beq_nat n m = true *)
      intros _. rewrite beq_nat_true_iff in H. rewrite H.
      left. reflexivity.
    + (* beq_nat n m = false *)
      intros H'. right. apply IHl'. apply H'.
Qed.

(** In the first branch after [destruct], we explicitly apply
    the [beq_nat_true_iff] lemma to the equation generated by
    destructing [beq_nat n m], to convert the assumption [beq_nat n m
    = true] into the assumption [n = m]; then we had to [rewrite]
    using this assumption to complete the case. *)

(** We can streamline this by defining an inductive proposition that
    yields a better case-analysis principle for [beq_nat n m].
    Instead of generating an equation such as [beq_nat n m = true],
    which is generally not directly useful, this principle gives us
    right away the assumption we really need: [n = m]. *)

Inductive reflect (P : Prop) : bool -> Prop :=
| ReflectT : P -> reflect P true
| ReflectF : ~ P -> reflect P false.

(** The [reflect] property takes two arguments: a proposition
    [P] and a boolean [b].  Intuitively, it states that the property
    [P] is _reflected_ in (i.e., equivalent to) the boolean [b]: that
    is, [P] holds if and only if [b = true].  To see this, notice
    that, by definition, the only way we can produce evidence that
    [reflect P true] holds is by showing that [P] is true and using
    the [ReflectT] constructor.  If we invert this statement, this
    means that it should be possible to extract evidence for [P] from
    a proof of [reflect P true].  Conversely, the only way to show
    [reflect P false] is by combining evidence for [~ P] with the
    [ReflectF] constructor.

    It is easy to formalize this intuition and show that the two
    statements are indeed equivalent: *)

Theorem iff_reflect : forall P b, (P <-> b = true) -> reflect P b.
Proof.
  (* WORKED IN CLASS *)
  intros P b H. destruct b.
  - apply ReflectT. rewrite H. reflexivity.
  - apply ReflectF. rewrite H. intros H'. inversion H'.
Qed.

(** **** Exercise: 2 stars, recommended (reflect_iff)  *)
Theorem reflect_iff : forall P b, reflect P b -> (P <-> b = true).
Proof. intros P b H. destruct b. 
  - split. intros p. reflexivity.
    intros _. inversion H. apply H0.
  - split. intros p. inversion H. exfalso. apply H0. apply p.
    intros contra. inversion contra. Qed.

(** [] *)

(** The advantage of [reflect] over the normal "if and only if"
    connective is that, by destructing a hypothesis or lemma of the
    form [reflect P b], we can perform case analysis on [b] while at
    the same time generating appropriate hypothesis in the two
    branches ([P] in the first subgoal and [~ P] in the second). *)


Lemma beq_natP : forall n m, reflect (n = m) (beq_nat n m).
Proof.
  intros n m. apply iff_reflect. rewrite beq_nat_true_iff. reflexivity.
Qed.

(** The new proof of [filter_not_empty_In] now goes as follows.
    Notice how the calls to [destruct] and [apply] are combined into a
    single call to [destruct]. *)

(** (To see this clearly, look at the two proofs of
    [filter_not_empty_In] with Coq and observe the differences in
    proof state at the beginning of the first case of the
    [destruct].) *)

Theorem filter_not_empty_In' : forall n l,
  filter (beq_nat n) l <> [] ->
  In n l.
Proof.
  intros n l. induction l as [|m l' IHl'].
  - (* l = [] *)
    simpl. intros H. apply H. reflexivity.
  - (* l = m :: l' *)
    simpl. destruct (beq_natP n m) as [H | H].
    + (* n = m *)
      intros _. rewrite H. left. reflexivity.
    + (* n <> m *)
      intros H'. right. apply IHl'. apply H'.
Qed.

(** **** Exercise: 3 stars, recommended (beq_natP_practice)  *)
(** Use [beq_natP] as above to prove the following: *)

Fixpoint count n l :=
  match l with
  | [] => 0
  | m :: l' => (if beq_nat n m then 1 else 0) + count n l'
  end.

Theorem beq_natP_practice : forall n l,
  count n l = 0 -> ~(In n l).
Proof. intros n l H. induction l as [|h l IH].
  - intros contra. inversion contra. 
  - intros H1. simpl in *. destruct (beq_natP n h).
    + inversion H.
    + destruct H1 as [H1|H1].
      * apply H0. symmetry. apply H1.
      * apply IH. apply H. apply H1.
Qed.     

(** [] *)

(** In this small example, this technique gives us only a rather small
    gain in convenience for the proofs we've seen; however, using
    [reflect] consistently often leads to noticeably shorter and
    clearer scripts as proofs get larger.  We'll see many more
    examples in later chapters and in _Programming Language
    Foundations_.

    The use of the [reflect] property was popularized by _SSReflect_,
    a Coq library that has been used to formalize important results in
    mathematics, including as the 4-color theorem and the
    Feit-Thompson theorem.  The name SSReflect stands for _small-scale
    reflection_, i.e., the pervasive use of reflection to simplify
    small proof steps with boolean computations. *)

(* ################################################################# *)
(** * Additional Exercises *)

(** **** Exercise: 3 stars, recommended (nostutter_defn)  *)
(** Formulating inductive definitions of properties is an important
    skill you'll need in this course.  Try to solve this exercise
    without any help at all.

    We say that a list "stutters" if it repeats the same element
    consecutively.  (This is different from the [NoDup] property in 
    the exercise above: the sequence [1;4;1] repeats but does not
    stutter.)  The property "[nostutter mylist]" means that
    [mylist] does not stutter.  Formulate an inductive definition for
    [nostutter]. *)

Inductive nostutter {X:Type} : list X -> Prop :=
  | nos_nil : nostutter []
  | nos_one : forall x, nostutter [x]
  | nos_cons : forall x h l, 
      nostutter (h :: l) -> (x <> h) -> (nostutter (x :: h :: l)).

(** Make sure each of these tests succeeds, but feel free to change
    the suggested proof (in comments) if the given one doesn't work
    for you.  Your definition might be different from ours and still
    be correct, in which case the examples might need a different
    proof.  (You'll notice that the suggested proofs use a number of
    tactics we haven't talked about, to make them more robust to
    different possible ways of defining [nostutter].  You can probably
    just uncomment and use them as-is, but you can also prove each
    example with more basic tactics.)  *)

Example test_nostutter_1: nostutter [3;1;4;1;5;6].

  Proof. repeat constructor; apply beq_nat_false_iff; auto.
  Qed.

Example test_nostutter_2:  nostutter (@nil nat).
  Proof. repeat constructor; apply beq_nat_false_iff; auto.
  Qed.

Example test_nostutter_3:  nostutter [5].
  Proof. repeat constructor; apply beq_nat_false; auto. Qed.

Example test_nostutter_4:      not (nostutter [3;1;1;4]).
  Proof. intro.
  repeat match goal with
    h: nostutter _ |- _ => inversion h; clear h; subst
  end.
  contradiction H5; auto. Qed.

(** [] *)

(** **** Exercise: 4 stars, advanced (filter_challenge)  *)
(** Let's prove that our definition of [filter] from the [Poly]
    chapter matches an abstract specification.  Here is the
    specification, written out informally in English:

    A list [l] is an "in-order merge" of [l1] and [l2] if it contains
    all the same elements as [l1] and [l2], in the same order as [l1]
    and [l2], but possibly interleaved.  For example,

    [1;4;6;2;3]

    is an in-order merge of

    [1;6;2]

    and

    [4;3].

    Now, suppose we have a set [X], a function [test: X->bool], and a
    list [l] of type [list X].  Suppose further that [l] is an
    in-order merge of two lists, [l1] and [l2], such that every item
    in [l1] satisfies [test] and no item in [l2] satisfies test.  Then
    [filter test l = l1].

    Translate this specification into a Coq theorem and prove
    it.  (You'll need to begin by defining what it means for one list
    to be a merge of two others.  Do this with an inductive relation,
    not a [Fixpoint].)  *)

Inductive merge {X:Type} : list X -> list X -> list X -> Prop :=
  | merge_0 : merge [] [] []
  | mergeL : forall l1 l2 l h, merge l1 l2 l -> merge (h::l1) l2 (h::l)
  | mergeR : forall l1 l2 l h, merge l1 l2 l -> merge l1 (h::l2) (h::l).

Theorem merge_theorem : forall X (test:X->bool) l l1 l2,
  merge l1 l2 l ->
  (forall x, In x l1 -> test x = true) -> 
  (forall x, In x l2 -> test x = false) -> 
  filter test l = l1.
Proof. intros X test l l1 l2 Hind. 
  induction Hind as [|l1 l2 l h H IH| l1 l2 l h H IH].
  - reflexivity.
  - simpl. intros H2. 
    assert (Ha: forall x : X, In x l1 -> test x = true).
    { intros x HIn. apply (H2 x (or_intror HIn)). }
    assert (Hb: test h = true).
    { apply H2. left. reflexivity. }
    rewrite Hb. intros H3.
    apply f_equal.
    apply IH. apply Ha. apply H3. 
  - simpl. intros H2 H3.
    assert (Ha: forall x : X, In x l2 -> test x = false).
    { intros x HIn. apply H3. right. apply HIn. }
    assert (Hb: test h = false).
    { apply (H3 h (or_introl eq_refl)). }
    rewrite Hb. 
    apply IH. apply H2. apply Ha. Qed.

(** [] *)

(** **** Exercise: 5 stars, advanced, optional (filter_challenge_2)  *)
(** A different way to characterize the behavior of [filter] goes like
    this: Among all subsequences of [l] with the property that [test]
    evaluates to [true] on all their members, [filter test l] is the
    longest.  Formalize this claim and prove it. *)

Inductive subseqX {X:Type}: list X -> list X -> Prop :=
  | sqx_empty : forall l, subseqX [] l
  | sqx_1 : forall h l1 l2, subseqX l1 l2 -> subseqX l1 (h::l2)
  | sqx_2 : forall h l1 l2, subseqX l1 l2 -> subseqX (h::l1) (h::l2).

Theorem filter_challenge_2 : forall X (test:X->bool) l ls,
  subseqX ls l ->
  (forall x, In x ls -> test x = true) ->
  length ls <= length (filter test l).
Proof. intros X test l ls HInd.
  induction HInd as [l|h ls l H IH|h ls l H IH].
  - intros H. apply O_le_n.
  - intros Ha. apply IH in Ha. 
    apply le_trans with (n:=(length (filter test l))).
    apply Ha. simpl. destruct (test h). apply le_S. apply le_n.
    reflexivity.
  - intros H1.
    assert (Ha: forall x : X, In x ls -> test x = true).
    { intros x HIn. apply H1. right. apply HIn. }
    assert (Hb: test h = true).
    {apply H1. left. reflexivity. }
    simpl. rewrite Hb. apply n_le_m__Sn_le_Sm. apply IH. apply Ha. Qed.    

(** **** Exercise: 4 stars, optional (palindromes)  *)
(** A palindrome is a sequence that reads the same backwards as
    forwards.

    - Define an inductive proposition [pal] on [list X] that
      captures what it means to be a palindrome. (Hint: You'll need
      three cases.  Your definition should be based on the structure
      of the list; just having a single constructor like

        c : forall l, l = rev l -> pal l

      may seem obvious, but will not work very well.)

    - Prove ([pal_app_rev]) that

       forall l, pal (l ++ rev l).

    - Prove ([pal_rev] that)

       forall l, pal l -> l = rev l.
*)

Inductive pal {X:Type}: list X -> Prop :=
  | pal_0 : pal []
  | pal_1 : forall x, pal [x]
  | pal_2 : forall x l, pal l -> pal (x :: l ++ [x]).

Theorem pal_app_rev: forall X  (l:list X), pal (l ++ rev l).
Proof. intros X l. induction l as [|x l IH].
  - constructor.
  - simpl. rewrite app_assoc. constructor. apply IH. Qed.

Theorem pal_rev : forall X (l:list X), pal l -> l = rev l.
Proof. intros X l p. induction p as [|x IH|x l H IH].
  - reflexivity.
  - reflexivity.
  - simpl. rewrite rev_app_distr, <- IH. reflexivity. Qed.

(** [] *)

(** **** Exercise: 5 stars, optional (palindrome_converse)  *)
(** Again, the converse direction is significantly more difficult, due
    to the lack of evidence.  Using your definition of [pal] from the
    previous exercise, prove that

     forall l, l = rev l -> pal l.
*)

Lemma list_represent : forall X (l:list X),
  l = [] \/ (exists x, l = [x]) \/ (exists x l' y, l = (x :: l' ++ [y])).
Proof. intros X. induction l as [|h l IH].
  - left. reflexivity. 
  - destruct IH as [H | [[x H] | [x [l' [y H]]]]].
    + right. left. exists h. rewrite H. reflexivity.
    + right. right. exists h, [], x. rewrite H. reflexivity.
    + right. right. exists h, (x :: l'), y. rewrite H. reflexivity. Qed.

Theorem palindrome_converse_n : forall X  n (l:list X), length l <= n -> 
l = rev l -> pal l.
Proof. intros X. induction n as [|n].
  intros l Hlength. destruct l. 
    intros _. constructor.
    inversion Hlength.
  intros l Hlength Hrev.
  destruct (list_represent X l) as [H | [[x H] | [x [l' [y H]]]]].
  - inversion H. constructor. 
  - inversion H. constructor. 
  - rewrite H in Hrev. simpl in Hrev. rewrite rev_app_distr in Hrev. 
    inversion Hrev. rewrite <- H1 in H. rewrite H. 
    apply (f_equal _ _ rev _ _) in H2. 
    rewrite rev_app_distr, rev_app_distr in H2.
    rewrite rev_involutive in H2. inversion H2. rewrite H3. 
    rewrite H in Hlength.
    simpl in Hlength. rewrite app_length, plus_comm in Hlength. 
    apply le_S, Sn_le_Sm__n_le_m, Sn_le_Sm__n_le_m in Hlength.
    constructor. apply IHn. apply Hlength. symmetry. apply H3.
Qed. 

Theorem palindrome_converse : forall X (l:list X), l = rev l -> pal l.
Proof. intros X l. apply (palindrome_converse_n X (length l)). 
  constructor. Qed.

(** [] *)

(** **** Exercise: 4 stars, advanced, optional (NoDup)  *)
(** Recall the definition of the [In] property from the [Logic]
    chapter, which asserts that a value [x] appears at least once in a
    list [l]: *)

(* Fixpoint In (A : Type) (x : A) (l : list A) : Prop :=
   match l with
   | [] => False
   | x' :: l' => x' = x \/ In A x l'
   end *)

(** Your first task is to use [In] to define a proposition [disjoint X
    l1 l2], which should be provable exactly when [l1] and [l2] are
    lists (with elements of type X) that have no elements in
    common. *)

Inductive disjoint {X:Type} : list X -> list X -> Prop :=
  | dis_nilL : forall l, disjoint [] l
  | dis_nilR : forall l, disjoint l []
  | dis_consL: forall l1 l2 x, disjoint l1 l2 -> ~ In x l2 -> disjoint (x::l1) l2  
  | dis_consR: forall l1 l2 x, disjoint l1 l2 -> ~ In x l1 -> disjoint l1 (x::l2).

(** Next, use [In] to define an inductive proposition [NoDup X
    l], which should be provable exactly when [l] is a list (with
    elements of type [X]) where every member is different from every
    other.  For example, [NoDup nat [1;2;3;4]] and [NoDup
    bool []] should be provable, while [NoDup nat [1;2;1]] and
    [NoDup bool [true;true]] should not be.  *)

Inductive NoDup {X:Type} : list X -> Prop :=
  | nd_nil : NoDup []
  | nd_cons : forall l x, ~ In x l -> NoDup l -> NoDup (x::l). 

(** Finally, state and prove one or more interesting theorems relating
    [disjoint], [NoDup] and [++] (list append).  *)

Lemma not_in_append1 : forall X x (l1 l2 : list X),
  ~ In x (l1++l2) -> ~ In x l1.
Proof. intros X x l1 l2 H H2. rewrite In_app_iff in H.
  apply H. left. apply H2. Qed.

Lemma not_in_append2 : forall X x (l1 l2 : list X),
  ~ In x (l1++l2) -> ~ In x l2.
Proof. intros X x l1 l2 H H2. rewrite In_app_iff in H.
  apply H. right. apply H2. Qed.

Lemma in_app : forall X x (l1 l2 : list X),
  ~ In x l1 -> ~ In x l2 -> ~ In x (l1++l2).
Proof. intros X x l1 l2 H1 H2 H.
  rewrite In_app_iff in H. destruct H as [H|H].
  - apply H1. apply H.
  - apply H2. apply H. Qed.

Lemma not_in_comm : forall X x (l1 l2 : list X),
  ~ In x (l1++l2) -> ~ In x (l2++l1).
Proof. intros X x l1 l2 H. apply in_app.
  - apply not_in_append2 with l1. apply H.
  - apply not_in_append1 with l2. apply H. Qed.

Lemma nodup_insert : forall X x (l1 l2 : list X),
  NoDup (l1 ++ l2) -> ~ In x (l1++l2) -> NoDup (l1++(x::l2)).
Proof. intros X x l1 l2 Hnd HnIn. induction l1 as [|h l1 IH].
 - constructor. apply HnIn. apply Hnd.
 - assert (H: x <> h).
   { intros Hx.  apply HnIn. left. symmetry. apply Hx. }
   inversion Hnd.
   constructor. 
   + apply in_app. 
     * apply not_in_append1 with l2. apply H2.
     * intros [Hx|Hx]. apply H. apply Hx. 
       apply H2. rewrite In_app_iff. right. apply Hx.
   + apply IH. 
     * apply H3.
     * intros Hx. apply HnIn.
       right. apply Hx. Qed.
   
Lemma nodup_comm : forall X (l1 l2 : list X),
  NoDup (l1++l2) -> NoDup (l2++l1).
Proof. intros X l1 l2 H. induction l1 as [|h l1 IH].
 - rewrite app_nil_r.
   apply H.
 - inversion H. apply nodup_insert. apply IH, H3.
   apply not_in_comm. apply H2. Qed.

Theorem nodup_disjoint : forall X (l1 l2: list X),
  NoDup (l1++l2) -> disjoint l1 l2.
Proof. intros X l1 l2 H. induction l1 as [|h l1 IH].
  - constructor. 
  - inversion H. constructor. apply IH. apply H3.
    apply not_in_append2 with l1. apply H2. Qed.

Theorem disjoint_of_nodups : forall X (l1 l2: list X),
  NoDup l1 -> NoDup l2 -> disjoint l1 l2 -> NoDup (l1++l2).
Proof. intros X l1 l2 Hl1 Hl2 Hdj. induction Hdj.
  - apply Hl2.
  - rewrite app_nil_r. apply Hl1.  
  - inversion Hl1. constructor. 
    + apply in_app. apply H2. apply H. 
    + apply IHHdj. apply H3. apply Hl2.
  - inversion Hl2. apply nodup_insert. 
    + apply IHHdj. apply Hl1. apply H3.
    + apply in_app.  apply H. apply H2. Qed.

(** [] *)

(** **** Exercise: 4 stars, advanced, optional (pigeonhole_principle)  *)
(** The _pigeonhole principle_ states a basic fact about counting: if
    we distribute more than [n] items into [n] pigeonholes, some
    pigeonhole must contain at least two items.  As often happens, this
    apparently trivial fact about numbers requires non-trivial
    machinery to prove, but we now have enough... *)

(** First prove an easy useful lemma. *)

Lemma in_split : forall (X:Type) (x:X) (l:list X),
  In x l ->
  exists l1 l2, l = l1 ++ x :: l2.
Proof. intros X x l HIn. induction l as [|h l IH].
  - inversion HIn.
  - destruct HIn as [HIn|HIn]. 
    * exists [], l. inversion HIn. reflexivity.
    * apply IH in HIn. destruct HIn as [l1 [l2 E]].
      exists (h::l1), l2. rewrite E. reflexivity. Qed.
  
(** Now define a property [repeats] such that [repeats X l] asserts
    that [l] contains at least one repeated element (of type [X]).  *)

Inductive repeats {X:Type} : list X -> Prop :=
 | rp_in : forall l x, In x l -> repeats (x::l)
 | rp_rp : forall l x, repeats l -> repeats (x::l).

(** Now, here's a way to formalize the pigeonhole principle.  Suppose
    list [l2] represents a list of pigeonhole labels, and list [l1]
    represents the labels assigned to a list of items.  If there are
    more items than labels, at least two items must have the same
    label -- i.e., list [l1] must contain repeats.

    This proof is much easier if you use the [excluded_middle]
    hypothesis to show that [In] is decidable, i.e., [forall x l, (In x
    l) \/ ~ (In x l)].  However, it is also possible to make the proof
    go through _without_ assuming that [In] is decidable; if you
    manage to do this, you will not need the [excluded_middle]
    hypothesis. *)

Fixpoint natlists (n:nat) : list nat :=
  match n with
  | O => []
  | S n => (S n) :: natlists n
  end.

Inductive natl : list nat -> Prop :=
  | nl_0 : natl [] 
  | nl_1 : natl [1]
  | nl_n : forall n l, natl (n :: l) -> natl ((S n)::n :: l).

Definition inj {A B: Type} (f:A->B) :=
  forall (x y:A), f x = f y -> x = y.
(* 
Fixpoint delete_one {X:Type} (x:X) (l:list X) (em : excluded_middle) : list X :=
  match l with
  | [] => []
  | h :: t => match (em (h=x)) with
              | or_introl _ => l
              | or_intror _ => h :: (delete_one x t em)
              end
  end.

Lemma aux_pigeon: forall (X:Type) (l1  l2:list X) h,
(~ In h l1)
 (forall x, In x l1 -> In x l2) -> 
   l2 = (delete_one h l2).
Proof. Qed.*)


Lemma in_comm: forall X x (l1 l2:list X),
  In x (l1 ++ l2) -> In x (l2 ++ l1). 
Proof. intros X x l1 l2 H. rewrite In_app_iff in *.
  destruct H as [H|H].
  - right. apply H.
  - left. apply H.
Qed.

Theorem pigeonhole_principle: forall (X:Type) (l1  l2:list X),
   excluded_middle ->
   (forall x, In x l1 -> In x l2) ->
   length l2 < length l1 ->
   repeats l1.
Proof.
   intros X l1. induction l1 as [|h l1 IH].
   - intros l2 em H1 H2. inversion H2.
   - intros l2 em H1 H2. destruct (em (In h l1)).
     + constructor. apply H.
     + apply rp_rp. 
       assert (H': In h l2).
       { apply H1. left. reflexivity. }
       apply in_split in H'. destruct H' as [l21 [l22 Hl2]].
       apply IH with (l2:=l22++l21).
       * apply em.
       * intros x HH. 
         assert (Ha:In x (h::l22 ++ l21)).
         { replace (h :: l22 ++ l21) with ((h :: l22) ++ l21).
           apply in_comm. rewrite <- Hl2. apply H1. 
           right. apply HH. 
           reflexivity. }
         destruct Ha as [Ha|Ha].
           exfalso. apply H. inversion Ha. apply HH.
           apply Ha.
        * rewrite Hl2 in H2.
          rewrite app_length, plus_comm in H2. 
          simpl in H2. apply Sn_le_Sm__n_le_m in H2. rewrite app_length.
          apply H2.
Qed.
          

(** [] *)


(* ================================================================= *)
(** ** Extended Exercise: A Verified Regular-Expression Matcher *)

(** We have now defined a match relation over regular expressions and
    polymorphic lists. We can use such a definition to manually prove that
    a given regex matches a given string, but it does not give us a
    program that we can run to determine a match autmatically.

    It would be reasonable to hope that we can translate the definitions
    of the inductive rules for constructing evidence of the match relation
    into cases of a recursive function reflects the relation by recursing
    on a given regex. However, it does not seem straightforward to define
    such a function in which the given regex is a recursion variable
    recognized by Coq. As a result, Coq will not accept that the function
    always terminates.

    Heavily-optimized regex matchers match a regex by translating a given
    regex into a state machine and determining if the state machine
    accepts a given string. However, regex matching can also be
    implemented using an algorithm that operates purely on strings and
    regexes without defining and maintaining additional datatypes, such as
    state machines. We'll implemement such an algorithm, and verify that
    its value reflects the match relation. *)

(** We will implement a regex matcher that matches strings represeneted
    as lists of ASCII characters: *)
Require Export Coq.Strings.Ascii.

Definition string := list ascii.

(** The Coq standard library contains a distinct inductive definition
    of strings of ASCII characters. However, we will use the above
    definition of strings as lists as ASCII characters in order to apply
    the existing definition of the match relation.

    We could also define a regex matcher over polymorphic lists, not lists
    of ASCII characters specifically. The matching algorithm that we will
    implement needs to be able to test equality of elements in a given
    list, and thus needs to be given an equality-testing
    function. Generalizing the definitions, theorems, and proofs that we
    define for such a setting is a bit tedious, but workable. *)

(** The proof of correctness of the regex matcher will combine
    properties of the regex-matching function with properties of the
    [match] relation that do not depend on the matching function. We'll go
    ahead and prove the latter class of properties now. Most of them have
    straightforward proofs, which have been given to you, although there
    are a few key lemmas that are left for you to prove. *)


(** Each provable [Prop] is equivalent to [True]. *)
Lemma provable_equiv_true : forall (P : Prop), P -> (P <-> True).
Proof.
  intros.
  split.
  - intros. constructor.
  - intros _. apply H.
Qed.

(** Each [Prop] whose negation is provable is equivalent to [False]. *)
Lemma not_equiv_false : forall (P : Prop), ~P -> (P <-> False).
Proof.
  intros.
  split.
  - apply H.
  - intros. inversion H0.
Qed.

(** [EmptySet] matches no string. *)
Lemma null_matches_none : forall (s : string), (s =~ EmptySet) <-> False.
Proof.
  intros. 
  apply not_equiv_false.
  unfold not. intros. inversion H.
Qed.

(** [EmptyStr] only matches the empty string. *)
Lemma empty_matches_eps : forall (s : string), s =~ EmptyStr <-> s = [ ].
Proof.
  split.
  - intros. inversion H. reflexivity.
  - intros. rewrite H. apply MEmpty.
Qed.

(** [EmptyStr] matches no non-empty string. *)
Lemma empty_nomatch_ne : forall (a : ascii) s, (a :: s =~ EmptyStr) <-> False.
Proof.
  intros.
  apply not_equiv_false.
  unfold not. intros. inversion H.
Qed.

(** [Char a] matches no string that starts with a non-[a] character. *)
Lemma char_nomatch_char :
  forall (a b : ascii) s, b <> a -> (b :: s =~ Char a <-> False).
Proof.
  intros.
  apply not_equiv_false.
  unfold not.
  intros.
  apply H.
  inversion H0.
  reflexivity.
Qed. 

(** If [Char a] matches a non-empty string, then the string's tail is empty. *)
Lemma char_eps_suffix : forall (a : ascii) s, a :: s =~ Char a <-> s = [ ].
Proof.
  split.
  - intros. inversion H. reflexivity.
  - intros. rewrite H. apply MChar.
Qed.

(** [App re0 re1] matches string [s] iff [s = s0 ++ s1], where [s0]
    matches [re0] and [s1] matches [re1]. *)
Lemma app_exists : forall (s : string) re0 re1,
    s =~ App re0 re1 <->
    exists s0 s1, s = s0 ++ s1 /\ s0 =~ re0 /\ s1 =~ re1.
Proof.
  intros.
  split.
  - intros. inversion H. exists s1, s2. split.
    * reflexivity.
    * split. apply H3. apply H4.
  - intros [ s0 [ s1 [ Happ [ Hmat0 Hmat1 ] ] ] ].
    rewrite Happ. apply (MApp s0 _ s1 _ Hmat0 Hmat1).
Qed.

(** **** Exercise: 3 stars, optional (app_ne)  *)
(** [App re0 re1] matches [a::s] iff [re0] matches the empty string
    and [a::s] matches [re1] or [s=s0++s1], where [a::s0] matches [re0]
    and [s1] matches [re1].

    Even though this is a property of purely the match relation, it is a
    critical observation behind the design of our regex matcher. So (1)
    take time to understand it, (2) prove it, and (3) look for how you'll
    use it later. *)
Lemma app_ne : forall (a : ascii) s re0 re1,
    a :: s =~ (App re0 re1) <->
    ([ ] =~ re0 /\ a :: s =~ re1) \/
    exists s0 s1, s = s0 ++ s1 /\ a :: s0 =~ re0 /\ s1 =~ re1.
Proof. intros a s re0 re1. split. 
  - intros H. inversion H. destruct s1 as [|h s1].
    * left. split.
      + apply H3.
      + apply H4.
    * right. exists s1, s2. inversion H0. split.
      + reflexivity.
      + split. rewrite H6 in *. apply H3. apply H4. 
  - intros [[H1 H2]|H].
    + replace (a :: s) with ([] ++ (a :: s)). 
      * constructor. 
         apply H1.
         apply H2.
      * reflexivity.
    + destruct H as [s0 [s1 [H1 [H2 H3]]]].
      rewrite H1. 
      replace (a :: s0 ++ s1) with ((a :: s0) ++ s1).
      * constructor.
          apply H2. 
          apply H3. 
      * reflexivity. Qed.

(** [] *)

(** [s] matches [Union re0 re1] iff [s] matches [re0] or [s] matches [re1]. *)
Lemma union_disj : forall (s : string) re0 re1,
    s =~ Union re0 re1 <-> s =~ re0 \/ s =~ re1.
Proof.
  intros. split.
  - intros. inversion H.
    + left. apply H2.
    + right. apply H2.
  - intros [ H | H ].
    + apply MUnionL. apply H.
    + apply MUnionR. apply H. 
Qed.

(** **** Exercise: 3 stars, optional (star_ne)  *)
(** [a::s] matches [Star re] iff [s = s0 ++ s1], where [a::s0] matches
    [re] and [s1] matches [Star re]. Like [app_ne], this observation is
    critical, so understand it, prove it, and keep it in mind.

    Hint: you'll need to perform induction. There are quite a few
    reasonable candidates for [Prop]'s to prove by induction. The only one
    that will work is splitting the [iff] into two implications and
    proving one by induction on the evidence for [a :: s =~ Star re]. The
    other implication can be proved without induction.

    In order to prove the right property by induction, you'll need to
    rephrase [a :: s =~ Star re] to be a [Prop] over general variables,
    using the [remember] tactic.  *)

Lemma not_empty_star: forall (s:string), 
  (s =~ Star EmptyStr) -> s = [].
Proof. intros s H2. remember (Star EmptyStr) as x eqn:H.
  induction H2.
  - reflexivity.
  - inversion H.
  - inversion H.
  - inversion H.
  - inversion H.
  - reflexivity.
  - inversion H. rewrite H1 in *. inversion H2_. 
    rewrite IHexp_match2. reflexivity. reflexivity. Qed.  

Lemma star_ne : forall (a : ascii) s re,
    a :: s =~ Star re <->
    exists s0 s1, s = s0 ++ s1 /\ a :: s0 =~ re /\ s1 =~ Star re.
Proof. intros a s re. split.
  - intros H. remember (Star re) as re'. remember (a::s) as s'.
    induction H .
    + inversion Heqre'.
    + inversion Heqre'.
    + inversion Heqre'.
    + inversion Heqre'.
    + inversion Heqre'.
    + inversion Heqs'.
    + destruct s1 as [|h s1]. 
      * inversion Heqre'. rewrite H2 in *. 
        apply IHexp_match2 in Heqre'.
        destruct Heqre' as [s0 [s1 [Ha [Hb Hc]]]].
        exists s0, s1. split. 
          apply Ha. split.
          apply Hb.
          apply Hc.
        apply Heqs'.
      * inversion Heqs'. rewrite H2 in *.
        inversion Heqre'. rewrite H4 in *.
        exists s1, s2. split.
          reflexivity. split.
          apply H.
          apply H0.
  - intros [s0 [s1 [H [H1 H2]]]]. 
    rewrite H. apply (MStarApp (a :: s0)).
    apply H1. apply H2. Qed.

(** [] *)

(** The definition of our regex matcher will include two fixpoint
    functions. The first function, given regex [re], will evaluate to a
    value that reflects whether [re] matches the empty string. The
    function will satisfy the following property: *)
Definition refl_matches_eps m :=
  forall re : @reg_exp ascii, reflect ([ ] =~ re) (m re).

(** **** Exercise: 2 stars, optional (match_eps)  *)
(** Complete the definition of [match_eps] so that it tests if a given
    regex matches the empty string: *)
Fixpoint match_eps (re: @reg_exp ascii) : bool :=
  match re with
  | EmptySet => false
  | EmptyStr => true
  | Char _ => false
  | App x y => andb (match_eps x) (match_eps y)
  | Union x y => orb (match_eps x) (match_eps y)
  | Star _ => true
  end.

(** [] *)

(** **** Exercise: 3 stars, optional (match_eps_refl)  *)
(** Now, prove that [match_eps] indeed tests if a given regex matches
    the empty string.  (Hint: You'll want to use the reflection lemmas
    [ReflectT] and [ReflectF].) *)
Lemma match_eps_refl : refl_matches_eps match_eps.
Proof. intros re. apply iff_reflect. split.
  - intros H. remember [] as s.
    induction H.
    + reflexivity.
    + inversion Heqs.
    + simpl.
      destruct s1, s2.
      * rewrite IHexp_match1, IHexp_match2. reflexivity.
      reflexivity. reflexivity.
      * inversion Heqs.
      * inversion Heqs.
      * inversion Heqs.
    + simpl. rewrite IHexp_match. reflexivity. apply Heqs.
    + simpl. rewrite orb_true_iff. right. apply IHexp_match.
      apply Heqs.
    + reflexivity.
    + reflexivity.
  - intros H. induction re.
    + inversion H.
    + constructor.
    + inversion H.
    + apply andb_true_iff in H. destruct H as [H1 H2]. apply (MApp []). 
      * apply IHre1. apply H1.
      * apply IHre2. apply H2.
    + apply orb_true_iff in H. destruct H as [H | H].
      * apply MUnionL. apply IHre1. apply H.
      * apply MUnionR. apply IHre2. apply H.
    + constructor.
Qed.
 

(** [] *)

(** We'll define other functions that use [match_eps]. However, the
    only property of [match_eps] that you'll need to use in all proofs
    over these functions is [match_eps_refl]. *)


(** The key operation that will be performed by our regex matcher will
    be to iteratively construct a sequence of regex derivatives. For each
    character [a] and regex [re], the derivative of [re] on [a] is a regex
    that matches all suffixes of strings matched by [re] that start with
    [a]. I.e., [re'] is a derivative of [re] on [a] if they satisfy the
    following relation: *)

Definition is_der re (a : ascii) re' :=
  forall s, a :: s =~ re <-> s =~ re'.

(** A function [d] derives strings if, given character [a] and regex
    [re], it evaluates to the derivative of [re] on [a]. I.e., [d]
    satisfies the following property: *)
Definition derives d := forall a re, is_der re a (d a re).

(** **** Exercise: 3 stars, optional (derive)  *)
(** Define [derive] so that it derives strings. One natural
    implementation uses [match_eps] in some cases to determine if key
    regex's match the empty string. *)

Check forall A B, A + B.

Print ascii_dec.

Check @left.

Fixpoint derive (a : ascii) (re : @reg_exp ascii) : @reg_exp ascii :=
  match re with
  | EmptySet => EmptySet
  | EmptyStr => EmptySet
  | Char x => if ascii_dec a x then EmptyStr else EmptySet
  | App A B => if (match_eps A) then Union (derive a B) (App (derive a A) B)  
               else App (derive a A) B
  | Union A B => Union (derive a A) (derive a B)
  | Star A => App (derive a A) (Star A)
  end.
  
(** [] *)

(** The [derive] function should pass the following tests. Each test
    establishes an equality between an expression that will be
    evaluated by our regex matcher and the final value that must be
    returned by the regex matcher. Each test is annotated with the
    match fact that it reflects. *)
Example c := ascii_of_nat 99.
Example d := ascii_of_nat 100.

(** "c" =~ EmptySet: *)
Example test_der0 : match_eps (derive c (EmptySet)) = false.
Proof. reflexivity. Qed.

(** "c" =~ Char c: *)
Example test_der1 : match_eps (derive c (Char c)) = true.
Proof. reflexivity. Qed.

(** "c" =~ Char d: *)
Example test_der2 : match_eps (derive c (Char d)) = false.
Proof. reflexivity. Qed.

(** "c" =~ App (Char c) EmptyStr: *)
Example test_der3 : match_eps (derive c (App (Char c) EmptyStr)) = true.
Proof. reflexivity. Qed.

(** "c" =~ App EmptyStr (Char c): *)
Example test_der4 : match_eps (derive c (App EmptyStr (Char c))) = true.
Proof. reflexivity. Qed.

(** "c" =~ Star c: *)
Example test_der5 : match_eps (derive c (Star (Char c))) = true.
Proof. reflexivity. Qed.

(** "cd" =~ App (Char c) (Char d): *)
Example test_der6 :
  match_eps (derive d (derive c (App (Char c) (Char d)))) = true.
Proof. reflexivity. Qed.

(** "cd" =~ App (Char d) (Char c): *)
Example test_der7 :
  match_eps (derive d (derive c (App (Char d) (Char c)))) = false.
Proof. reflexivity. Qed.

(** **** Exercise: 4 stars, optional (derive_corr)  *)
(** Prove that [derive] in fact always derives strings.

    Hint: one proof performs induction on [re], although you'll need
    to carefully choose the property that you prove by induction by
    generalizing the appropriate terms.

    Hint: if your definition of [derive] applies [match_eps] to a
    particular regex [re], then a natural proof will apply
    [match_eps_refl] to [re] and destruct the result to generate cases
    with assumptions that the [re] does or does not match the empty
    string.

    Hint: You can save quite a bit of work by using lemmas proved
    above. In particular, to prove many cases of the induction, you
    can rewrite a [Prop] over a complicated regex (e.g., [s =~ Union
    re0 re1]) to a Boolean combination of [Prop]'s over simple
    regex's (e.g., [s =~ re0 \/ s =~ re1]) using lemmas given above
    that are logical equivalences. You can then reason about these
    [Prop]'s naturally using [intro] and [destruct]. *)


Lemma derive_corr : derives derive.
Proof. intros a re s. split.
* remember (a :: s) as s'.
  intros H. generalize dependent s. induction H.
  - intros s Heqs'. inversion Heqs'.
  - intros s Heqs'. simpl. destruct (ascii_dec a x).
    + inversion Heqs'. constructor.
    + inversion Heqs'. exfalso. apply n. symmetry. apply H0.
  - intros s Heqs'. simpl. destruct (match_eps re1) eqn: Heps.
    + destruct s1. 
        apply MUnionL. apply IHexp_match2. apply Heqs'.
        inversion Heqs'. apply MUnionR. constructor.
        apply IHexp_match1. inversion H2. reflexivity.
        apply H0.
    + destruct s1. 
        destruct (match_eps_refl re1). 
        inversion Heps. exfalso. apply H1. apply H.
        inversion Heqs'. constructor. apply IHexp_match1.
        inversion H2. reflexivity. apply H0.
   - intros s H'. apply MUnionL. apply IHexp_match.
     apply H'.
   - intros s H'. apply MUnionR. apply IHexp_match.
     apply H'.
   - intros s contra. inversion contra.
   - intros s H'.
     simpl. destruct s1.
     + simpl in H'. apply IHexp_match2. apply H'.
     + inversion H'. constructor. 
         apply IHexp_match1. inversion H2.
         reflexivity.
         apply H0.
* generalize dependent s. induction re.
  - intros s H. rewrite null_matches_none in H. inversion H.
  - intros s H. simpl in H. rewrite null_matches_none in H. inversion H.
  - intros s H. simpl in H. destruct (ascii_dec a t).
    + rewrite empty_matches_eps in H. rewrite H. inversion e. constructor.
    + rewrite null_matches_none in H. inversion H.
  - intros s H. simpl in H. destruct (match_eps re1) eqn: He.
    + rewrite union_disj in H. destruct H as [H|H].
      destruct (match_eps_refl re1).
        replace (a :: s) with ([]++(a :: s)).
        constructor. 
          apply H0.
          apply IHre2. apply H.
        reflexivity.
        inversion He.
      rewrite app_exists in H. destruct H as [s0 [s1 [H [H1 H2]]]]. 
      apply IHre1 in H1. 
      apply app_exists. exists (a :: s0), s1.
      split. rewrite H. reflexivity.
      split. apply H1. apply H2.
    + rewrite app_exists in H.
      destruct H as [s0 [s1 [H [H1 H2]]]]. apply IHre1 in H1.
      rewrite app_exists. exists (a :: s0), s1.
      split. rewrite H. reflexivity.
      split. apply H1. apply H2.
  - intros s H. simpl in H. rewrite union_disj in *.
    destruct H as [H|H]. 
      left. apply IHre1. apply H.
      right. apply IHre2. apply H.
  - intros s H. simpl in H. rewrite app_exists, star_ne in *.
    destruct H as [s0 [s1 [H [H1 H2]]]].
    exists s0, s1. 
    split. 
      + apply H.
      + split. 
        apply IHre. apply H1. 
        apply H2.
Qed.  
    

(** [] *)

(** We'll define the regex matcher using [derive]. However, the only
    property of [derive] that you'll need to use in all proofs of
    properties of the matcher is [derive_corr]. *)


(** A function [m] matches regexes if, given string [s] and regex [re],
    it evaluates to a value that reflects whether [s] is matched by
    [re]. I.e., [m] holds the following property: *)
Definition matches_regex m : Prop :=
  forall (s : string) re, reflect (s =~ re) (m s re).

(** **** Exercise: 2 stars, optional (regex_match)  *)
(** Complete the definition of [regex_match] so that it matches
    regexes. *)

Fixpoint regex_match (s : string) (re : @reg_exp ascii) : bool :=
  match s with
  | [] => match_eps re
  | h :: t => regex_match t (derive h re)
  end.

(** [] *)

(** **** Exercise: 3 stars, optional (regex_refl)  *)
(** Finally, prove that [regex_match] in fact matches regexes.

    Hint: if your definition of [regex_match] applies [match_eps] to
    regex [re], then a natural proof applies [match_eps_refl] to [re]
    and destructs the result to generate cases in which you may assume
    that [re] does or does not match the empty string.

    Hint: if your definition of [regex_match] applies [derive] to
    character [x] and regex [re], then a natural proof applies
    [derive_corr] to [x] and [re] to prove that [x :: s =~ re] given
    [s =~ derive x re], and vice versa. *)

Theorem regex_refl : matches_regex regex_match.
Proof. intros s. induction s as [|h s IH].
  - intros re. simpl. destruct (match_eps_refl re). 
    + constructor. apply H.
    + constructor. apply H.
  - intros re. simpl. destruct (derive_corr h re s).
    destruct (IH (derive h re)).
      constructor. apply H0. apply H1.
      constructor. intros contra. apply H1. apply H. apply contra. Qed.

