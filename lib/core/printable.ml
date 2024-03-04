open Syntax
open Term
open Value
open Reporter

type printable +=
  | PUnit : printable
  | PString : string -> printable
  | PLevel : level -> printable
  | PTerm : ('a, 'b) Ctx.t * ('b, kinetic) term -> printable
  | PVal : ('a, 'b) Ctx.t * kinetic value -> printable
  | PNormal : ('a, 'b) Ctx.t * normal -> printable
  | PUninst : ('a, 'b) Ctx.t * uninst -> printable
  | PCtx : ('a, 'b) Ctx.t -> printable
  | PNames : 'b Names.t -> printable
