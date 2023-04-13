{
  root,
  yants,
}:
with yants "dmerge"; let
  inherit (root.internal) decorateAt mergeAt;
in {
  __functor = self: self.merge;

  decorate = rhs: dec: (decorateAt [] rhs dec);

  merge = lhs: rhs: (mergeAt [] lhs rhs);
}
