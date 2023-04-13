{
  yants,
  root,
  lib,
}:
with yants "dmerge/update"; let
  inherit (builtins) length listToAttrs elemAt foldl';
  inherit (lib) zipListsWith imap0 assertMsg traceSeqN setAttrByPath getAttrFromPath max;
  inherit (lib.generators) toPretty;

  inherit (root.internal) mergeAt;
in
  indices: updates: orig: cursor: let
    updateset = listToAttrs (
      zipListsWith (
        idx: upd: let
          # manufacture a "cursor" for display purposes
          tmplhs = setAttrByPath (cursor ++ [(toString idx)]) (elemAt orig idx);
          tmprhs = setAttrByPath (cursor ++ [(toString idx)]) upd;
        in {
          name = toString idx;
          value = getAttrFromPath (cursor ++ [(toString idx)]) (
            # but start from an empty cursor on this commissioned merge operation
            mergeAt [] tmplhs tmprhs
          );
        }
      )
      (list int indices)
      (list any updates)
    );
  in
    assert assertMsg (length indices == length updates) ''
      UPDATING ARRAY MERGE: for each index there must be one corresponding update value,
      got: ${traceSeqN 1 indices "(see first trace above)"} indices and
      ${traceSeqN 1 updates "(see second trace above)"} updates'';
    assert assertMsg (foldl' max 0 indices < length orig) ''
      UPDATING ARRAY MERGE: an update index exceeds the available elements on the left
      hand side. Lenght of left hand side array: ${toString (length orig)}, details: ${traceSeqN 2 orig ""}.
      Indices of the update function: ${toPretty {} indices}.'';
      imap0 (
        i: v:
          if updateset ? ${toString i}
          then updateset.${toString i}
          else elemAt orig i
      )
      orig
