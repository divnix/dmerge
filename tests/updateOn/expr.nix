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
in
  merge lhs rhs
