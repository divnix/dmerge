{
  lib,
  root,
  yants,
}:
with yants "dmerge/chainMerge"; let
  inherit
    (lib)
    isFunction
    foldl'
    ;

  m = root.merge;

  f' = fs: x:
    if isFunction x
    then f' (fs ++ [(x null)])
    else foldl' m {} (fs ++ [x]);
in
  f' []
