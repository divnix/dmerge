{
  merge,
  append,
}: let
  lhs.a.b = [];
  rhs.a.b = append ["c"];

  rhs'.a.c = append ["c"];

  villain.a.c = throw;

  incomplete.a.c = x: x;

  merged = {
    ok = merge lhs rhs;
    nok-FreshRHSNotValue = merge lhs rhs';
    nok-VillainMergeFunc = merge lhs villain;
    nok-IncompleteArrayMergFunc = merge lhs incomplete;
  };

  inherit (builtins) deepSeq mapAttrs tryEval;
in
  mapAttrs (_: x: tryEval (deepSeq x x)) merged
