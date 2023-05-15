{
  merge,
  prepend,
}: let
  lhs.a.b = ["last"];
  rhs.a.b = prepend ["first"];

  rhs'.a.c = prepend [""];

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
