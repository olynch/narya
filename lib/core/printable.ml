open Term
open Value
open Reporter

type printable +=
  | PTerm : ('a, 'b) Ctx.t * 'b term -> printable
  | PVal : ('a, 'b) Ctx.t * value -> printable
  | PCtx : ('a, 'b) Ctx.t -> printable
  | PNames : 'b Names.t -> printable
