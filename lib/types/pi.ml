open Dim
open Core
open Syntax
open Term

let pisym = Constant.make ()

let install () =
  Scope.set [ "Π" ] pisym;
  Hashtbl.add Global.types pisym
    (pi None (UU D.zero) (pi None (pi None (Var (Top (id_sface D.zero))) (UU D.zero)) (UU D.zero)));
  let open Case in
  Hashtbl.add Global.constants pisym
    (Defined
       (ref
          (Lam
             ( D.zero,
               `Normal (CubeOf.singleton (Some "A")),
               ref
                 (Lam
                    ( D.zero,
                      `Normal (CubeOf.singleton (Some "B")),
                      ref
                        (Leaf
                           (Pi
                              ( (* TODO: Get the variable somehow from the second argument *)
                                Some "x",
                                CubeOf.singleton (Var (Pop (Top (id_sface D.zero)))),
                                CodCube.singleton
                                  (App
                                     ( Var (Pop (Top (id_sface D.zero))),
                                       CubeOf.singleton (Var (Top (id_sface D.zero))) )) ))) )) ))))