{
  yants,
  root,
  lib,
}:
with yants "dmerge/updateOn"; let
  inherit (lib) assertMsg isAttrs all foldl' traceSeqN setAttrByPath getAttrFromPath unique length;
  inherit (lib.generators) toPretty;

  inherit (root.internal) mergeAt;
in
  key: updates: orig: here: let
    updateset =
      foldl' (
        acc: new: (
          if acc ? ${new.${key}}
          then
            throw ''
              The key '${new.${key}}' must be unique in the update array, got: ${traceSeqN 2 updates ""}
            ''
          else acc // {"${new.${key}}" = new;}
        )
      ) {}
      updates;
  in
    assert assertMsg (all isAttrs orig) ''
      UPDATING ASSOCIATIVE ARRAY: the left hand side of an associative array merged
      must only contain attribute sets, got: ${traceSeqN 1 orig ""}'';
    assert assertMsg (all isAttrs updates) ''
      UPDATING ASSOCIATIVE ARRAY: the right hand side of an associative array merged
      must only contain attribute sets, got: ${traceSeqN 1 updates ""}'';
    assert assertMsg (all (o: o ? ${key}) orig) ''
      UPDATING ASSOCIATIVE ARRAY: all items of the left hand side of an associative
      array merged must contain attribute sets with a key ${key}, got: ${traceSeqN 2 orig ""}'';
    assert assertMsg (all (u: u ? ${key}) updates) ''
      UPDATING ASSOCIATIVE ARRAY: all items of the right hand side of an associative
      array merged must contain attribute sets with a key ${key}, got: ${traceSeqN 2 updates ""}'';
    assert assertMsg (length (map (o: o.${key}) orig) == (length (unique (map (o: o.${key}) orig)))) ''
      UPDATING ASSOCIATIVE ARRAY: keys of the left hand side of an associative
      array merged must be unique on ${key}, got: ${traceSeqN 2 orig ""}'';
      map (o: (
        if updateset ? ${o.${key}}
        then
          (
            let
              # synthkey = "[${key}=${o.${key}}]";
              synthkey = "my"; #[${key}=${o.${key}}]";
              # manufacture a "here" for display purposes
              tmplhs = setAttrByPath (here ++ [synthkey]) o;
              tmprhs = setAttrByPath (here ++ [synthkey]) updateset.${o.${key}};
              # but start from an empty here on this commissioned merge operation
              res = getAttrFromPath (here ++ [synthkey]) (mergeAt [] tmplhs tmprhs);
            in
              res
          )
        else o
      ))
      orig
