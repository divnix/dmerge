{
  merge,
  prepend,
}: let
  lhs = {
    a.b = ["last"];
  };

  ok = {
    NormalMerge = merge lhs {a.b = prepend ["first"];};
    FreshRHSWithArrayMerge = merge lhs {a.new = prepend ["new"];};
  };

  nok = {
    VillainMergeFunc = merge lhs {a.new = throw "";};
    PartialMergeFunc = merge lhs {a.new = x: x;};
  };

  inherit (builtins) deepSeq mapAttrs tryEval;
in
  ok // (mapAttrs (_: x: tryEval (deepSeq x x)) nok)
