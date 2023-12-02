open Monoid

(* Type-level dyadic rationals, represeted as surreal sign-sequences, plus +ω and -ω. *)
type zero = Dummy_zero
type 'a plus = Dummy_plus
type 'a minus = Dummy_minus
type plus_omega = Dummy_plus_omega
type minus_omega = Dummy_minus_omega
type _ fin = Zero : zero fin | Plus : 'a fin -> 'a plus fin | Minus : 'a fin -> 'a minus fin
type _ t = Fin : 'a fin -> 'a t | Plus_omega : plus_omega t | Minus_omega : minus_omega t

let zero = Fin Zero
let one = Fin (Plus Zero)
let minus_one = Fin (Minus Zero)
let two = Fin (Plus (Plus Zero))
let minus_two = Fin (Minus (Minus Zero))
let minus_omega = Minus_omega
let plus_omega = Plus_omega

(* Type-level indices for strict inequality < and non-strict inequality ≤. *)
type strict = Dummy_strict
type nonstrict = Dummy_nonstrict
type _ strictness = Strict : strict strictness | Nonstrict : nonstrict strictness

(* An element of "(a,strict,b) lt" is a witness that a<b, and similarly for nonstrict and a≤b. *)
type (_, _, _) lt =
  | Plusomega_plusomega : (plus_omega, nonstrict, plus_omega) lt
  | Minusomega_minusomega : (minus_omega, nonstrict, minus_omega) lt
  | Fin_plusomega : 'a fin -> ('a, 's, plus_omega) lt
  | Minusomega_plusomega : (minus_omega, 's, plus_omega) lt
  | Minusomega_fin : 'b fin -> (minus_omega, 's, 'b) lt
  | Zero_plus : 'b fin -> (zero, 's, 'b plus) lt
  | Minus_plus : 'a fin * 'b fin -> ('a minus, 's, 'b plus) lt
  | Minus_zero : 'a fin -> ('a minus, 's, zero) lt
  | Plus_plus : 'a fin * 'b fin * ('a, 's, 'b) lt -> ('a plus, 's, 'b plus) lt
  | Minus_minus : 'a fin * 'b fin * ('a, 's, 'b) lt -> ('a minus, 's, 'b minus) lt
  | Zero_zero : (zero, nonstrict, zero) lt

(* ≤, but not <, is reflexive. *)
let rec le_refl : type a. a t -> (a, nonstrict, a) lt = function
  | Plus_omega -> Plusomega_plusomega
  | Minus_omega -> Minusomega_minusomega
  | Fin Zero -> Zero_zero
  | Fin (Plus a) -> Plus_plus (a, a, le_refl (Fin a))
  | Fin (Minus a) -> Minus_minus (a, a, le_refl (Fin a))

type (_, _, _) strict_trans =
  | Strict_any : (strict, 'a, 'a) strict_trans
  | Any_strict : ('a, strict, 'a) strict_trans
  | Nonstrict_nonstrict : (nonstrict, nonstrict, nonstrict) strict_trans

let rec lt_to_le : type a b s. (a, strict, b) lt -> (a, s, b) lt =
 fun lt ->
  match lt with
  | Fin_plusomega x -> Fin_plusomega x
  | Minusomega_plusomega -> Minusomega_plusomega
  | Minusomega_fin x -> Minusomega_fin x
  | Zero_plus x -> Zero_plus x
  | Minus_plus (x, y) -> Minus_plus (x, y)
  | Minus_zero x -> Minus_zero x
  | Plus_plus (x, y, xy) -> Plus_plus (x, y, lt_to_le xy)
  | Minus_minus (x, y, xy) -> Minus_minus (x, y, lt_to_le xy)

(*
let le_left : type a b s. (a, s, b) lt -> a t = function
  | Plusomega_plusomega -> Plus_omega
  | Minusomega_minusomega -> Minus_omega
  | Zero_plus _ -> Fin Zero
  | Zero_zero -> Fin Zero
  | Fin_plusomega a -> Fin a
  | Minusomega_plusomega -> Minus_omega
  | Minusomega_fin _ -> Minus_omega
  | Minus_plus (a, _) -> Fin (Minus a)
  | Minus_zero a -> Fin (Minus a)
  | Plus_plus (a, _, _) -> Fin (Plus a)
  | Minus_minus (a, _, _) -> Fin (Minus a)

let le_right : type a b s. (a, s, b) lt -> b t = function
  | Plusomega_plusomega -> Plus_omega
  | Minusomega_minusomega -> Minus_omega
  | Zero_plus b -> Fin (Plus b)
  | Zero_zero -> Fin Zero
  | Fin_plusomega _ -> Plus_omega
  | Minusomega_plusomega -> Plus_omega
  | Minusomega_fin b -> Fin b
  | Minus_plus (_, b) -> Fin (Plus b)
  | Minus_zero _ -> Fin Zero
  | Plus_plus (_, b, _) -> Fin (Plus b)
  | Minus_minus (_, b, _) -> Fin (Minus b)
*)

let rec lt_trans :
    type a b c s1 s2 s3.
    (s1, s2, s3) strict_trans -> (a, s1, b) lt -> (b, s2, c) lt -> (a, s3, c) lt =
 fun tr ab bc ->
  match (ab, bc, tr) with
  | Plusomega_plusomega, Plusomega_plusomega, Nonstrict_nonstrict -> Plusomega_plusomega
  | Minusomega_plusomega, Plusomega_plusomega, _ -> Minusomega_plusomega
  | Fin_plusomega a, Plusomega_plusomega, _ -> Fin_plusomega a
  | Minusomega_minusomega, Minusomega_minusomega, Nonstrict_nonstrict -> Minusomega_minusomega
  | Minusomega_minusomega, Minusomega_plusomega, _ -> Minusomega_plusomega
  | Minusomega_minusomega, Minusomega_fin b, _ -> Minusomega_fin b
  | Zero_plus _, Fin_plusomega (Plus _), _ -> Fin_plusomega Zero
  | Minus_plus (a, _), Fin_plusomega _, _ -> Fin_plusomega (Minus a)
  | Minus_zero a, Fin_plusomega _, _ -> Fin_plusomega (Minus a)
  | Plus_plus (a, _, _), Fin_plusomega _, _ -> Fin_plusomega (Plus a)
  | Zero_zero, Fin_plusomega _, _ -> Fin_plusomega Zero
  | Minus_minus (a, _, _), Fin_plusomega _, _ -> Fin_plusomega (Minus a)
  | Minusomega_fin _, Fin_plusomega _, _ -> Minusomega_plusomega
  | Minusomega_fin _, Zero_plus b, _ -> Minusomega_fin (Plus b)
  | Minusomega_fin _, Minus_plus (_, b), _ -> Minusomega_fin (Plus b)
  | Minusomega_fin _, Minus_zero _, _ -> Minusomega_fin Zero
  | Minusomega_fin _, Plus_plus (_, b, _), _ -> Minusomega_fin (Plus b)
  | Minusomega_fin _, Minus_minus (_, b, _), _ -> Minusomega_fin (Minus b)
  | Minusomega_fin _, Zero_zero, _ -> Minusomega_fin Zero
  | Minus_plus (a, _), Plus_plus (_, b, _), _ -> Minus_plus (a, b)
  | Minus_zero a, Zero_plus b, _ -> Minus_plus (a, b)
  | Minus_zero a, Zero_zero, _ -> Minus_zero a
  | Plus_plus (a, _, ab), Plus_plus (_, c, ac), _ -> Plus_plus (a, c, lt_trans tr ab ac)
  | Zero_zero, Zero_plus b, _ -> Zero_plus b
  | Zero_zero, Zero_zero, Nonstrict_nonstrict -> Zero_zero
  | Minus_minus (a, _, _), Minus_plus (_, b), _ -> Minus_plus (a, b)
  | Minus_minus (a, _, _), Minus_zero _, _ -> Minus_zero a
  | Minus_minus (a, _, ab), Minus_minus (_, c, bc), _ -> Minus_minus (a, c, lt_trans tr ab bc)
  | Zero_plus _, Plus_plus (_, b, _), _ -> Zero_plus b
  | Plusomega_plusomega, Fin_plusomega _, _ -> .
  | Minusomega_minusomega, Fin_plusomega _, _ -> .
  | Minusomega_fin _, Plusomega_plusomega, _ -> .
  | Minusomega_plusomega, Fin_plusomega _, _ -> .
  | Minusomega_fin _, Minusomega_minusomega, _ -> .
  | Minusomega_fin _, Minusomega_plusomega, _ -> .
  | Minusomega_fin _, Minusomega_fin _, _ -> .
  | Fin_plusomega _, Fin_plusomega _, _ -> .

let rec equal_fin : type a b. a fin -> b fin -> (a, b) compare =
 fun x y ->
  match (x, y) with
  | Zero, Zero -> Eq
  | Plus x, Plus y -> (
      match equal_fin x y with
      | Eq -> Eq
      | Neq -> Neq)
  | Minus x, Minus y -> (
      match equal_fin x y with
      | Eq -> Eq
      | Neq -> Neq)
  | _ -> Neq

let equal : type a b. a t -> b t -> (a, b) compare =
 fun x y ->
  match (x, y) with
  | Fin x, Fin y -> equal_fin x y
  | Plus_omega, Plus_omega -> Eq
  | Minus_omega, Minus_omega -> Eq
  | _ -> Neq

let equalb : type a b. a t -> b t -> bool =
 fun x y ->
  match equal x y with
  | Eq -> true
  | Neq -> false

(* Inequality is transitive.  There are many versions of this, depending on strictness of the inputs and outputs, but the only one we have need for so far is this. *)
let rec lt_trans1 : type a b c s1 s2. (a, s1, b) lt -> (b, s2, c) lt -> (a, s1, c) lt =
 fun ab bc ->
  match (ab, bc) with
  | Plusomega_plusomega, Plusomega_plusomega -> Plusomega_plusomega
  | Minusomega_plusomega, Plusomega_plusomega -> Minusomega_plusomega
  | Fin_plusomega a, Plusomega_plusomega -> Fin_plusomega a
  | Minusomega_minusomega, Minusomega_minusomega -> Minusomega_minusomega
  | Minusomega_minusomega, Minusomega_plusomega -> Minusomega_plusomega
  | Minusomega_minusomega, Minusomega_fin b -> Minusomega_fin b
  | Zero_plus _, Fin_plusomega (Plus _) -> Fin_plusomega Zero
  | Minus_plus (a, _), Fin_plusomega _ -> Fin_plusomega (Minus a)
  | Minus_zero a, Fin_plusomega _ -> Fin_plusomega (Minus a)
  | Plus_plus (a, _, _), Fin_plusomega _ -> Fin_plusomega (Plus a)
  | Zero_zero, Fin_plusomega _ -> Fin_plusomega Zero
  | Minus_minus (a, _, _), Fin_plusomega _ -> Fin_plusomega (Minus a)
  | Minusomega_fin _, Fin_plusomega _ -> Minusomega_plusomega
  | Minusomega_fin _, Zero_plus b -> Minusomega_fin (Plus b)
  | Minusomega_fin _, Minus_plus (_, b) -> Minusomega_fin (Plus b)
  | Minusomega_fin _, Minus_zero _ -> Minusomega_fin Zero
  | Minusomega_fin _, Plus_plus (_, b, _) -> Minusomega_fin (Plus b)
  | Minusomega_fin _, Minus_minus (_, b, _) -> Minusomega_fin (Minus b)
  | Minusomega_fin _, Zero_zero -> Minusomega_fin Zero
  | Minus_plus (a, _), Plus_plus (_, b, _) -> Minus_plus (a, b)
  | Minus_zero a, Zero_plus b -> Minus_plus (a, b)
  | Minus_zero a, Zero_zero -> Minus_zero a
  | Plus_plus (a, _, ab), Plus_plus (_, c, ac) ->
      let lt = lt_trans1 ab ac in
      Plus_plus (a, c, lt)
  | Zero_zero, Zero_plus b -> Zero_plus b
  | Zero_zero, Zero_zero -> Zero_zero
  | Minus_minus (a, _, _), Minus_plus (_, b) -> Minus_plus (a, b)
  | Minus_minus (a, _, _), Minus_zero _ -> Minus_zero a
  | Minus_minus (a, _, ab), Minus_minus (_, c, bc) ->
      let lt = lt_trans1 ab bc in
      Minus_minus (a, c, lt)
  | Zero_plus _, Plus_plus (_, b, _) -> Zero_plus b
  | Plusomega_plusomega, Fin_plusomega _ -> .
  | Minusomega_minusomega, Fin_plusomega _ -> .
  | Minusomega_fin _, Plusomega_plusomega -> .
  | Minusomega_plusomega, Fin_plusomega _ -> .
  | Minusomega_fin _, Minusomega_minusomega -> .
  | Minusomega_fin _, Minusomega_plusomega -> .
  | Minusomega_fin _, Minusomega_fin _ -> .
  | Fin_plusomega _, Fin_plusomega _ -> .

(* Decidable test for inequality. *)

let rec compare : type a s b. s strictness -> a t -> b t -> (a, s, b) lt option =
 fun s x y ->
  let open Monad.Ops (Monad.Maybe) in
  match (x, y) with
  | Fin Zero, Fin Zero -> (
      match s with
      | Strict -> None
      | Nonstrict -> Some Zero_zero)
  | Fin (Plus _), Fin Zero -> None
  | Fin (Minus x), Fin Zero -> Some (Minus_zero x)
  | Fin Zero, Fin (Plus y) -> Some (Zero_plus y)
  | Fin (Plus x), Fin (Plus y) ->
      let* r = compare s (Fin x) (Fin y) in
      return (Plus_plus (x, y, r))
  | Fin (Minus x), Fin (Plus y) -> Some (Minus_plus (x, y))
  | Fin Zero, Fin (Minus _) -> None
  | Fin (Plus _), Fin (Minus _) -> None
  | Fin (Minus x), Fin (Minus y) ->
      let* r = compare s (Fin x) (Fin y) in
      return (Minus_minus (x, y, r))
  | Plus_omega, Fin _ -> None
  | Minus_omega, Fin y -> Some (Minusomega_fin y)
  | Fin x, Plus_omega -> Some (Fin_plusomega x)
  | Fin _, Minus_omega -> None
  | Plus_omega, Plus_omega -> (
      match s with
      | Strict -> None
      | Nonstrict -> Some Plusomega_plusomega)
  | Minus_omega, Plus_omega -> Some Minusomega_plusomega
  | Plus_omega, Minus_omega -> None
  | Minus_omega, Minus_omega -> (
      match s with
      | Strict -> None
      | Nonstrict -> Some Minusomega_minusomega)

(* Convert to rationals in ZArith.Q. *)

let q_two = Q.add Q.one Q.one

let to_rat : type a. a t -> Q.t =
 fun x ->
  let rec fin_to_rat : type a. Q.t -> Q.t -> a fin -> Q.t =
   fun accum step x ->
    match x with
    | Zero -> accum
    | Plus x ->
        let step = if step = Q.one then step else Q.div (Q.abs step) q_two in
        fin_to_rat (Q.add accum step) step x
    | Minus x ->
        let step = if step = Q.minus_one then step else Q.neg (Q.div (Q.abs step) q_two) in
        fin_to_rat (Q.add accum step) step x in
  match x with
  | Plus_omega -> Q.inf
  | Minus_omega -> Q.minus_inf
  | Fin Zero -> Q.zero
  | Fin (Plus x) -> fin_to_rat Q.one Q.one x
  | Fin (Minus x) -> fin_to_rat Q.minus_one Q.minus_one x

(* Conversion from ZArith.Q can fail, if the input is not a dyadic rational.  (Note that a similar algorithm for floats would never fail, since all floating-point numbers *are* technically dyadic.) *)

type wrapped_fin = Wrapfin : 'a fin -> wrapped_fin
type wrapped = Wrap : 'a t -> wrapped

let of_rat (x : Q.t) : wrapped option =
  let rec of_rat x l r =
    let m = Q.div (Q.add l r) q_two in
    if x = m then Wrapfin Zero
    else if Q.(x < m) then
      let (Wrapfin y) = of_rat x l m in
      Wrapfin (Minus y)
    else
      let (Wrapfin y) = of_rat x m r in
      Wrapfin (Plus y) in
  let rec of_pos x l =
    let l' = Q.add l Q.one in
    if x = l' then Wrapfin (Plus Zero)
    else if Q.(x > l') then
      let (Wrapfin y) = of_pos x l' in
      Wrapfin (Plus y)
    else
      let (Wrapfin y) = of_rat x l l' in
      Wrapfin (Plus (Minus y)) in
  let rec of_neg x r =
    let r' = Q.sub r Q.one in
    if x = r' then Wrapfin (Minus Zero)
    else if Q.(x < r') then
      let (Wrapfin y) = of_neg x r' in
      Wrapfin (Minus y)
    else
      let (Wrapfin y) = of_rat x r' r in
      Wrapfin (Minus (Plus y)) in
  if x = Q.zero then Some (Wrap (Fin Zero))
  else if x = Q.inf then Some (Wrap Plus_omega)
  else if x = Q.minus_inf then Some (Wrap Minus_omega)
  else if Z.log2 x.den = Z.log2up x.den then
    if x > Q.zero then
      let (Wrapfin y) = of_pos x Q.zero in
      Some (Wrap (Fin y))
    else
      let (Wrapfin y) = of_neg x Q.zero in
      Some (Wrap (Fin y))
  else None

let to_string : type a. a t -> string = function
  | Plus_omega -> "+ω"
  | Minus_omega -> "-ω"
  | Fin _ as x -> Q.to_string (to_rat x)

(* Our sign-sequences above are morally *forwards* lists of signs, even though OCaml's type-former notation forces us to write them postfix.  That is, the type "zero minus plus plus" actually represents the sign-sequence "++-", meaning 1.5.  But it is also sometimes useful to have "backwards" lists of signs, so that for instance "then_zero then_minus then_plus then_plus" represents "-++".  *)

type 'a then_plus = Dummy_then_plus
type 'a then_minus = Dummy_then_minus
type then_zero = Dummy_then_zero

(* We can prepend a backwards sign sequence onto a forwards one. *)

type (_, _, _) prepend =
  | Zero : (then_zero, 'a, 'a) prepend
  | Plus : ('a, 'b plus, 'c) prepend -> ('a then_plus, 'b, 'c) prepend
  | Minus : ('a, 'b minus, 'c) prepend -> ('a then_minus, 'b, 'c) prepend

let rec prepend_uniq : type a b c c'. (a, b, c) prepend -> (a, b, c') prepend -> (c, c') eq =
 fun ab ab' ->
  match (ab, ab') with
  | Zero, Zero -> Eq
  | Plus ab, Plus ab' -> prepend_uniq ab ab'
  | Minus ab, Minus ab' -> prepend_uniq ab ab'

let rec prepend_fin : type a b c. b fin -> (a, b, c) prepend -> c fin =
 fun b ab ->
  match ab with
  | Zero -> b
  | Plus ab -> prepend_fin (Plus b) ab
  | Minus ab -> prepend_fin (Minus b) ab

(* For a backwards 'a and forwards 'b, "('a, 'b) then_lt" says that whenever we prepend 'a onto a forwards sign-sequence 'c, the result is less than 'b.  This is a strong sort of inequality a<b. *)

type ('a, 'b) then_lt = { then_lt : 'c 'ac 's. 'c fin -> ('a, 'c, 'ac) prepend -> ('ac, 's, 'b) lt }

(* It is strong enough that extending 'a by anything preserves it. *)

let then_plus_lt : type a b. (a, b) then_lt -> (a then_plus, b) then_lt =
 fun g -> { then_lt = (fun c (Plus ac) -> g.then_lt (Plus c) ac) }

let then_minus_lt : type a b. (a, b) then_lt -> (a then_minus, b) then_lt =
 fun g -> { then_lt = (fun c (Minus ac) -> g.then_lt (Minus c) ac) }

(* Inequalities b<c and b≤c are preserved by prepending any a onto both b and c. *)

let rec prepend_lt :
    type a b c ab ac s.
    b fin -> c fin -> (b, s, c) lt -> (a, b, ab) prepend -> (a, c, ac) prepend -> (ab, s, ac) lt =
 fun b c lt ab ac ->
  match (ab, ac) with
  | Zero, Zero -> lt
  | Plus ab, Plus ac -> prepend_lt (Plus b) (Plus c) (Plus_plus (b, c, lt)) ab ac
  | Minus ab, Minus ac -> prepend_lt (Minus b) (Minus c) (Minus_minus (b, c, lt)) ab ac

(* a prepended onto zero, or anything starting with a plus, is strongly greater than a followed by a minus. *)

let then_minus_lt' : type a b. (a, zero, b) prepend -> (a then_minus, b) then_lt =
 fun a_zero ->
  { then_lt = (fun c (Minus a_mc) -> prepend_lt (Minus c) Zero (Minus_zero c) a_mc a_zero) }

let then_minus_plus_lt' : type a b c. b fin -> (a, b plus, c) prepend -> (a then_minus, c) then_lt =
 fun b ab ->
  { then_lt = (fun d (Minus a_md) -> prepend_lt (Minus d) (Plus b) (Minus_plus (d, b)) a_md ab) }

(* We define a notion of intrinsically well-typed immutable map, associating to some numbers 'a an element of 'a F.t. *)

module type Fam = sig
  type 'a t
end

module MapMake (F : Fam) = struct
  type 'a no = 'a t

  (* First we define a map for finite numbers, then add the two omegas.  An element of "a fin_t" is a piece of a map indexed by a backwards sign-sequence a, in which the forward sign-sequence b acts as an index for something parametrized by the prepending of a onto b. *)

  type _ node = None : 'a node | Some : (('a, zero, 'b) prepend * 'b F.t) -> 'a node

  type _ fin_t =
    | Emp : 'a fin_t
    | Node : 'a node * 'a then_minus fin_t * 'a then_plus fin_t -> 'a fin_t

  type t = {
    fin : then_zero fin_t;
    minus_omega : minus_omega F.t option;
    plus_omega : plus_omega F.t option;
  }

  (* The empty map *)
  let empty = { fin = Emp; minus_omega = None; plus_omega = None }

  (* 'find' looks up a number in the map and returns its associated value, if any.  (So this is like find_opt for ordinary maps.) *)

  let rec fin_find : type a b c. a fin_t -> b fin -> (a, b, c) prepend -> c F.t option =
   fun map x ab ->
    match map with
    | Emp -> None
    | Node (y, mmap, pmap) -> (
        match x with
        | Zero -> (
            match y with
            | None -> None
            | Some (aa, y) ->
                let Eq = prepend_uniq ab aa in
                Some y)
        | Minus x -> fin_find mmap x (Minus ab)
        | Plus x -> fin_find pmap x (Plus ab))

  let find : type a. t -> a no -> a F.t option =
   fun map x ->
    match x with
    | Fin x -> fin_find map.fin x Zero
    | Minus_omega -> map.minus_omega
    | Plus_omega -> map.plus_omega

  (* 'add' adds an entry to the map, replacing any existing entry for that number. *)

  let rec fin_add : type a b c. a fin_t -> b fin -> (a, b, c) prepend -> c F.t -> a fin_t =
   fun map x ab y ->
    match (x, map) with
    | Zero, Emp -> Node (Some (ab, y), Emp, Emp)
    | Zero, Node (_, mmap, pmap) -> Node (Some (ab, y), mmap, pmap)
    | Minus x, Emp -> Node (None, fin_add Emp x (Minus ab) y, Emp)
    | Minus x, Node (z, mmap, pmap) -> Node (z, fin_add mmap x (Minus ab) y, pmap)
    | Plus x, Emp -> Node (None, Emp, fin_add Emp x (Plus ab) y)
    | Plus x, Node (z, mmap, pmap) -> Node (z, mmap, fin_add pmap x (Plus ab) y)

  let add : type a. a no -> a F.t -> t -> t =
   fun x y map ->
    match x with
    | Fin x -> { map with fin = fin_add map.fin x Zero y }
    | Minus_omega -> { map with minus_omega = Some y }
    | Plus_omega -> { map with plus_omega = Some y }

  (* 'remove' removes an entry from the map. *)

  let rec fin_remove : type a b. b fin -> a fin_t -> a fin_t =
   fun x map ->
    match map with
    | Emp -> Emp
    | Node (z, mmap, pmap) -> (
        match x with
        | Zero -> Node (None, mmap, pmap)
        | Minus x -> Node (z, fin_remove x mmap, pmap)
        | Plus x -> Node (z, mmap, fin_remove x pmap))

  let remove : type a. a no -> t -> t =
   fun x map ->
    match x with
    | Fin x -> { map with fin = fin_remove x map.fin }
    | Minus_omega -> { map with minus_omega = None }
    | Plus_omega -> { map with plus_omega = None }

  (* 'map_le' applies a given polymorphic function to all elements of the map whose index is less than or equal to some fixed number, also passing the function a witness of that inequality as well as its strictness.  This requires a record type to pass the polymorphic mapper argument, as well as several helper functions.  *)

  type 'b map_le = { map : 'a 's. ('a, 's, 'b) lt -> 's strictness -> 'a F.t -> 'a F.t }

  (* "fin_map_all" applies a function to all elements of a fin_t, assuming that that is valid given its parameter. *)
  let rec fin_map_all : type a b c. c map_le -> (a, c) then_lt -> a fin_t -> a fin_t =
   fun f x map ->
    match map with
    | Emp -> Emp
    | Node (z, mmap, pmap) ->
        Node
          ( (match z with
            | None -> None
            | Some (ab, y) -> Some (ab, f.map (x.then_lt Zero ab) Strict y)),
            fin_map_all f (then_minus_lt x) mmap,
            fin_map_all f (then_plus_lt x) pmap )

  (* Similarly, "fin_map_plusomega" applies a function to all elements of a fin_t, because +ω is greater than them. *)
  let rec fin_map_plusomega : type a. plus_omega map_le -> a fin_t -> a fin_t =
   fun f map ->
    match map with
    | Emp -> Emp
    | Node (z, mmap, pmap) ->
        Node
          ( (match z with
            | None -> None
            | Some (ab, y) -> Some (ab, f.map (Fin_plusomega (prepend_fin Zero ab)) Strict y)),
            fin_map_plusomega f mmap,
            fin_map_plusomega f pmap )

  let rec fin_map_le : type a b c. c map_le -> b fin -> (a, b, c) prepend -> a fin_t -> a fin_t =
   fun f x ab map ->
    match map with
    | Emp -> Emp
    | Node (z, mmap, pmap) -> (
        match x with
        | Zero ->
            let z =
              match z with
              | None -> None
              | Some (a_zero, z) ->
                  let Eq = prepend_uniq ab a_zero in
                  Some (ab, f.map (le_refl (Fin (prepend_fin Zero ab))) Nonstrict z) in
            Node (z, fin_map_all f (then_minus_lt' ab) mmap, pmap)
        | Plus x ->
            let z =
              match z with
              | None -> None
              | Some (a_zero, z) ->
                  Some (a_zero, f.map (prepend_lt Zero (Plus x) (Zero_plus x) a_zero ab) Strict z)
            in
            Node (z, fin_map_all f (then_minus_plus_lt' x ab) mmap, fin_map_le f x (Plus ab) pmap)
        | Minus x -> Node (z, fin_map_le f x (Minus ab) mmap, pmap))

  let map_le : type b. b map_le -> b no -> t -> t =
   fun f x map ->
    match x with
    | Minus_omega ->
        {
          minus_omega = Option.map (f.map Minusomega_minusomega Nonstrict) map.minus_omega;
          fin = map.fin;
          plus_omega = map.plus_omega;
        }
    | Fin x ->
        {
          minus_omega = Option.map (f.map (Minusomega_fin x) Strict) map.minus_omega;
          fin = fin_map_le f x Zero map.fin;
          plus_omega = map.plus_omega;
        }
    | Plus_omega ->
        {
          minus_omega = Option.map (f.map Minusomega_plusomega Strict) map.minus_omega;
          fin = fin_map_plusomega f map.fin;
          plus_omega = Option.map (f.map Plusomega_plusomega Nonstrict) map.plus_omega;
        }

  (* 'fin_least' finds the element in a fin_t with the least index, or None if the map is empty. *)

  type 'a value = Value : ('a, 'b, 'c) prepend * 'b fin * 'c F.t -> 'a value | None : 'a value

  let rec fin_least : type a. a fin_t -> a value =
   fun map ->
    match map with
    | Emp -> None
    | Node (x, mmap, pmap) -> (
        match fin_least mmap with
        | Value (Minus ab, b, y) -> Value (ab, Minus b, y)
        | None -> (
            match x with
            | Some (ab, y) -> Value (ab, Zero, y)
            | None -> (
                match fin_least pmap with
                | Value (Plus ab, b, y) -> Value (ab, Plus b, y)
                | None -> None)))

  (* And dually for 'fin_greatest'. *)

  let rec fin_greatest : type a. a fin_t -> a value =
   fun map ->
    match map with
    | Emp -> None
    | Node (x, mmap, pmap) -> (
        match fin_greatest pmap with
        | Value (Plus ab, b, y) -> Value (ab, Plus b, y)
        | None -> (
            match x with
            | Some (ab, y) -> Value (ab, Zero, y)
            | None -> (
                match fin_greatest mmap with
                | Value (Minus ab, b, y) -> Value (ab, Minus b, y)
                | None -> None)))

  (* 'add_cut' adds a new entry to the map, with specified index, and whose value is computed from the next-highest and next-lowest entries, whatever they are, by a specified polymorphic function.  It requires upper and lower default values to be given in case there is no next-highest or next-lowest entry, i.e. the new entry will be the greatest and/or least one in the map.  If the specified index already has an entry, it is NOT replaced, instead the map is returned unchanged (but not untouched, so it is not physically equal to the input). *)

  type 'a upper = Upper : ('a, strict, 'c) lt * 'c F.t -> 'a upper | No_upper : 'a upper
  type 'a lower = Lower : ('b, strict, 'a) lt * 'b F.t -> 'a lower | No_lower : 'a lower

  let rec add_cut_fin :
      type a b c.
      (a, b, c) prepend ->
      b fin ->
      (c lower -> c upper -> c F.t) ->
      c lower ->
      c upper ->
      a fin_t ->
      a fin_t =
   fun ab x f lower upper map ->
    match (x, map) with
    | Plus x, Emp -> Node (None, Emp, add_cut_fin (Plus ab) x f lower upper Emp)
    | Minus x, Emp -> Node (None, add_cut_fin (Minus ab) x f lower upper Emp, Emp)
    | Zero, Emp -> Node (Some (ab, f lower upper), Emp, Emp)
    | Zero, Node (Some _, _, _) -> map
    | Zero, Node (None, mmap, pmap) ->
        let lower =
          match fin_greatest mmap with
          | Value (Minus ad, d, z) -> Lower (prepend_lt (Minus d) Zero (Minus_zero d) ad ab, z)
          | None -> lower in
        let upper =
          match fin_least pmap with
          | Value (Plus ad, d, z) -> Upper (prepend_lt Zero (Plus d) (Zero_plus d) ab ad, z)
          | None -> upper in
        Node (Some (ab, f lower upper), mmap, pmap)
    | Minus x, Node ((Some (lt, y) as z), mmap, pmap) ->
        Node
          ( z,
            add_cut_fin (Minus ab) x f lower
              (Upper (prepend_lt (Minus x) Zero (Minus_zero x) ab lt, y))
              mmap,
            pmap )
    | Minus x, Node (None, mmap, pmap) -> (
        match fin_least pmap with
        | Value (Plus ad, d, y) ->
            Node
              ( None,
                add_cut_fin (Minus ab) x f lower
                  (Upper (prepend_lt (Minus x) (Plus d) (Minus_plus (x, d)) ab ad, y))
                  mmap,
                pmap )
        | None -> Node (None, add_cut_fin (Minus ab) x f lower upper mmap, pmap))
    | Plus x, Node ((Some (lt, y) as z), mmap, pmap) ->
        Node
          ( z,
            mmap,
            add_cut_fin (Plus ab) x f
              (Lower (prepend_lt Zero (Plus x) (Zero_plus x) lt ab, y))
              upper pmap )
    | Plus x, Node (None, mmap, pmap) -> (
        match fin_greatest mmap with
        | Value (Minus ad, d, y) ->
            Node
              ( None,
                mmap,
                add_cut_fin (Plus ab) x f
                  (Lower (prepend_lt (Minus d) (Plus x) (Minus_plus (d, x)) ad ab, y))
                  upper pmap )
        | None -> Node (None, mmap, add_cut_fin (Plus ab) x f lower upper pmap))

  let add_cut : type b. b no -> (b lower -> b upper -> b F.t) -> t -> t =
   fun x f map ->
    match x with
    | Fin x ->
        let lower =
          match map.minus_omega with
          | None -> No_lower
          | Some y -> Lower (Minusomega_fin x, y) in
        let upper =
          match map.plus_omega with
          | None -> No_upper
          | Some y -> Upper (Fin_plusomega x, y) in
        { map with fin = add_cut_fin Zero x f lower upper map.fin }
    | Minus_omega -> (
        match map.minus_omega with
        | Some _ -> map
        | None ->
            {
              map with
              minus_omega =
                Some
                  (match fin_least map.fin with
                  | Value (Zero, b, y) -> f No_lower (Upper (Minusomega_fin b, y))
                  | None -> (
                      match map.plus_omega with
                      | Some y -> f No_lower (Upper (Minusomega_plusomega, y))
                      | None -> f No_lower No_upper));
            })
    | Plus_omega -> (
        match map.plus_omega with
        | Some _ -> map
        | None ->
            {
              map with
              plus_omega =
                Some
                  (match fin_greatest map.fin with
                  | Value (Zero, b, y) -> f (Lower (Fin_plusomega b, y)) No_upper
                  | None -> (
                      match map.minus_omega with
                      | Some y -> f (Lower (Minusomega_plusomega, y)) No_upper
                      | None -> f No_lower No_upper));
            })
end
