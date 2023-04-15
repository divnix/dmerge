{
  chainMerge,
  chainable,
}: let
  withA = chainable {foo = {};};
  withB = chainable {foo.bar = {};};
  withC = chainable {foo.bar.baz = {};};
in
  chainMerge withA withB withC {answer = 42;}
