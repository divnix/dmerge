{
  merge,
  update,
}: let
  lhs.a.b = [{c = "c";}];
  rhs.a.b = update [0] [{c = "bc";}];

  rhs'.a.b = update [1] [{c = "bc";}];
  rhs_.a.b = update [1] [{c = "bc";} {}];

  merged = {
    ok = merge lhs rhs;
    nok-WrongIndex = merge lhs rhs';
    nok-InstructionMismatch = merge lhs rhs_;
  };

  inherit (builtins) deepSeq mapAttrs tryEval;
in
  mapAttrs (_: x: tryEval (deepSeq x x)) merged
