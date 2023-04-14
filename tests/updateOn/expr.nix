{
  updateOn,
  merge,
}: let
  lhs = {
    a = [
      {
        name = "foo";
        value = "bar";
      }
      {
        name = "baz";
        value = "qux";
      }
    ];
  };

  rhs = {
    a = updateOn "name" [
      {
        name = "foo";
        value = "barr";
      }
    ];
  };

  lhs' = {a = [{name = "duplicate";} {name = "duplicate";}];};
  rhs' = {a = updateOn "name" [{name = "duplicate";} {name = "duplicate";}];};

  merged = {
    ok = merge lhs rhs;
    nok-LhsDupliate = merge lhs' rhs;
    nok-RhsDupliate = merge lhs rhs';
  };

  inherit (builtins) deepSeq mapAttrs tryEval;
in
  mapAttrs (_: x: tryEval (deepSeq x x)) merged
