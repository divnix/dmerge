{
  merge,
  decorate,
  update,
}: let
  lhs.a.b = [{c = "c";}];
  rhs.a.b = [{c = "bc";}];

  merged = {
    nok = merge lhs rhs;
    ok = merge lhs (decorate rhs {a.b = update [0];});
  };

  inherit (builtins) deepSeq mapAttrs tryEval;
in
  mapAttrs (_: x: tryEval (deepSeq x x)) merged
