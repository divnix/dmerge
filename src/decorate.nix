{
  root,
  yants,
}:
with yants "dmerge/decorate"; let
  inherit (root.internal) decorateAt;
in
  rhs: dec: (decorateAt [] rhs dec)
