{
  description = "A mini merge DSL for data overlays";
  inputs.nixlib.url = "github:nix-community/nixpkgs.lib";
  outputs = {
    self,
    nixlib,
  }: let
    # Incrementality of the Data Spine
    # --------------------------------
    # To reduce mental complexity in chained merges,
    # we must ensure that the data spine of the left
    # hand side is not _destructively_ modified.
    #
    # This means, that like the keys of an attribute
    # set cannot be removed through a merge operation,
    # we also must ensure that no array element can
    # be removed either.
    #
    # In this reasoning, the composed types _arrays_
    # and _attribute sets_ represent the "data spine".
    # And while individual simple type merges necessarily
    # destroy information, the spine itself shall not
    # allowed to be transformed itself destructively.
    mergeAt = here: lhs: rhs: let
      inherit (builtins) isAttrs head tail typeOf concatStringsSep tryEval;
      inherit (nixlib.lib) zipAttrsWith isList isFunction getAttrFromPath;

      f = attrPath:
        zipAttrsWith (
          n: values: let
            here' = attrPath ++ [n];
            rhs' = head values;
            lhs' = head (tail values);
            isSingleton = tail values == [];
            lhsFilePos = let
              lhsPos = builtins.unsafeGetAttrPos n (getAttrFromPath attrPath lhs);
            in "${lhsPos.file}:${toString lhsPos.line}:${toString lhsPos.column}";
            rhsFilePos = let
              rhsPos = builtins.unsafeGetAttrPos n (getAttrFromPath attrPath rhs);
            in "${rhsPos.file}:${toString rhsPos.line}:${toString rhsPos.column}";
          in
            if (isSingleton && isFunction (head values))
            then
              abort ''

                a fresh right-hand-side cannot be an array merge function
                at '${concatStringsSep "." here'}':
                  - rhs: ${typeOf rhs'} @ ${rhsFilePos}
              ''
            else if isSingleton
            then head values
            else if !(isAttrs lhs' && isAttrs rhs')
            then
              if (typeOf lhs') != (typeOf rhs') && !(isList lhs' && isFunction rhs')
              then
                abort ''

                  rigt-hand-side must be of the same type as left-hand-side
                  at '${concatStringsSep "." here'}':
                  - lhs: ${typeOf lhs'} @ ${lhsFilePos}
                  - rhs: ${typeOf rhs'} @ ${rhsFilePos}
                ''
              else if isList lhs' && isList rhs'
              then
                abort ''

                  rigt-hand-side list is not allowed to override left-hand-side list,
                  this would break incrementality of the data spine. Use one of the array
                  merge functions instead at '${concatStringsSep "." here'}':
                  - lhs: ${typeOf lhs'} @ ${lhsFilePos}
                  - rhs: ${typeOf rhs'} @ ${rhsFilePos}

                  Available array merge functions:
                  - data-merge.update [ idx ... ] [ v ... ]
                  - data-merge.append [ v ]
                ''
              # array function merge
              else if isList lhs' && isFunction rhs'
              then let
                ex = tryEval (rhs' lhs' here');
              in
                if ex.success
                then ex.value
                else
                  abort ''

                    Array merge function error (see trace above the error line for details) on the right-hand-side:
                    - rhs: ${typeOf rhs'} @ ${rhsFilePos}
                  ''
              else rhs'
            else f here' values
        );
    in
      f here [rhs lhs];
  in {
    merge = mergeAt [];

    append = new: orig: _: let
      inherit (builtins) isList typeOf concatStringsSep;
      inherit (nixlib.lib) assertMsg;
    in
      assert assertMsg (isList new) ''
        APPENDING ARRAY MERGE: argument must be a list, got: ${typeOf new}'';
        orig ++ new;

    update = indices: updates: orig: here: let
      inherit (builtins) isList all isInt length typeOf listToAttrs elemAt hasAttr concatStringsSep;
      inherit (nixlib.lib) zipListsWith imap0 assertMsg traceSeqN;
    in
      assert assertMsg (isList indices) ''
        UPDATING ARRAY MERGE: first argument must be a list, got: ${typeOf indices}'';
      assert assertMsg (isList updates) ''
        UPDATING ARRAY MERGE: second argument must be a list, got: ${typeOf updates}'';
      assert assertMsg (all (i: isInt i) indices) ''
        UPDATING ARRAY MERGE: first argument must be a list of indices (integers) of items to update in the left-hand-side list, got: ${traceSeqN 1 indices "(see trace above)"}'';
      assert assertMsg (length indices == length updates) ''
        UPDATING ARRAY MERGE: for each index there must be one corresponding update value, got: ${traceSeqN 1 indices "(see first trace above)"} indices & ${traceSeqN 1 updates "(see second trace above)"} updates''; let
        updated = listToAttrs (
          zipListsWith (
            idx: upd: {
              name = toString idx;
              value =
                (
                  mergeAt here
                  {mergedListItem = elemAt orig idx;}
                  {mergedListItem = upd;}
                )
                .mergedListItem;
            }
          )
          indices
          updates
        );
      in
        imap0 (
          i: v:
            if hasAttr "${toString i}" updated
            then updated.${toString i}
            else elemAt orig i
        )
        orig;
  };
}
