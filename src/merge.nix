{
  root,
  yants,
}:
with yants "dmerge/decorate"; let
  inherit (root.internal) mergeAt;
in
  lhs: rhs: (mergeAt [] lhs rhs)
