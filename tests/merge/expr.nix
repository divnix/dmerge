{merge}: let
  lhs.a.b = {};
  rhs.a.b.c = [];

  merged = {
    ok = merge lhs rhs;
    nok-AttemtptedListOverride =
      merge
      {a.b.c = [];} {a.b.c = ["c"];};
    nok-TypeMismatch =
      merge
      {a = {};} {a = "a";};
  };

  inherit (builtins) deepSeq mapAttrs tryEval;
in
  mapAttrs (_: x: tryEval (deepSeq x x)) merged
