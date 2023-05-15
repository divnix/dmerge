{
  merge,
  append,
}: let
  lhs = {
    a.b = [];
  };

  ok = {
    NormalMerge = merge lhs {a.b = append ["c"];};
    FreshRHSWithArrayMerge = merge lhs {a.new = append ["c"];};
  };

  nok = {
    VillainMergeFunc = merge lhs {a.new = throw "";};
    PartialMergeFunc = merge lhs {a.new = x: x;};
  };

  inherit (builtins) deepSeq mapAttrs tryEval;
in
  ok // (mapAttrs (_: x: tryEval (deepSeq x x)) nok)
