{
  description = "A mini merge DSL for data overlays";
  inputs.nixlib.url = "github:nix-community/nixpkgs.lib";
  inputs.yants.url = "github:divnix/yants";
  outputs = {
    self,
    nixlib,
    yants,
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
            singleton = head values;
            lhsFilePos = let
              lhsPos = builtins.unsafeGetAttrPos n (getAttrFromPath attrPath lhs);
            in
              if lhsPos != null
              then "${lhsPos.file}:${toString lhsPos.line}:${toString lhsPos.column}"
              else "undetectable posision";
            rhsFilePos = let
              rhsPos = builtins.unsafeGetAttrPos n (getAttrFromPath attrPath rhs);
            in
              if rhsPos != null
              then "${rhsPos.file}:${toString rhsPos.line}:${toString rhsPos.column}"
              else "undetectable posision";
          in
            if (isSingleton && isFunction singleton)
            then
              abort ''

                a fresh right-hand-side cannot be an array merge function
                at '${concatStringsSep "." here'}':
                  - rhs: ${typeOf rhs'} @ ${rhsFilePos}
              ''
            else if isSingleton
            then
              if (isAttrs singleton) # descend if it's an attrset
              then f here' [{} singleton]
              else singleton
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

    decorateAt = here: lhs: rhs: let
      inherit (builtins) isAttrs hasAttr head tail typeOf concatStringsSep tryEval;
      inherit (nixlib.lib) zipAttrsWith isList isFunction getAttrFromPath;

      f = attrPath: rhs_: lhs_:
        zipAttrsWith (
          n: values: let
            here' = attrPath ++ [n];
            rhs' = head values;
            lhs' = head (tail values);
            isSingleton = tail values == [];
            singleton = head values;
            lhsFilePos = let
              lhsPos = builtins.unsafeGetAttrPos n (getAttrFromPath attrPath lhs);
            in
              if lhsPos != null
              then "${lhsPos.file}:${toString lhsPos.line}:${toString lhsPos.column}"
              else "undetectable posision";
            rhsFilePos = let
              rhsPos = builtins.unsafeGetAttrPos n (getAttrFromPath attrPath rhs);
            in
              if rhsPos != null
              then "${rhsPos.file}:${toString rhsPos.line}:${toString rhsPos.column}"
              else "undetectable posision";
          in
            if isSingleton
            then
              if hasAttr n rhs_ # rhs-singleton
              then
                abort ''

                  you can only decorate existing attr paths, the following doesn't exist in the decorated attrs
                  at '${concatStringsSep "." here'}':
                    - decor: ${typeOf rhs'} @ ${rhsFilePos}
                ''
              else singleton # lhs-singleton
            else if !(isAttrs lhs' && isAttrs rhs')
            then
              if (isList lhs' && isFunction rhs')
              then rhs' lhs'
              else
                abort ''

                  The only thing you can do is to decorate an attrs' list with a function decorator at '${concatStringsSep "." here'}':
                  - attrs: ${typeOf lhs'} @ ${lhsFilePos}
                  - decor: ${typeOf rhs'} @ ${rhsFilePos}

                  Available array merge functions decorators:
                  - data-merge.update [ idx ... ]
                  - data-merge.append
                ''
            else f here' rhs' lhs'
        )
        [rhs_ lhs_];
    in
      f here rhs lhs;
  in
    with yants "data-merge"; {
      # ------
      # decorate
      # ------
      decorate = rhs: dec:
      # builtins.deepSeq
      # (decorateAt [] rhs dec)
      (decorateAt [] rhs dec);
      # ------

      # ------
      # merge
      # ------
      merge = lhs: rhs:
      # builtins.deepSeq
      # (mergeAt [] lhs rhs)
      (mergeAt [] lhs rhs);
      # ------

      # ------
      # append
      # ------
      append = new: orig: here: orig ++ (list any new);
      # ------

      # ------
      # combine
      # ------
      combine = first: second: orig: here: (function second) ((function first) orig here) orig here;
      # ------

      # ------
      # update
      # ------
      update = indices: updates: orig: here: let
        inherit (builtins) length listToAttrs elemAt hasAttr;
        inherit (nixlib.lib) zipListsWith imap0 assertMsg traceSeqN setAttrByPath getAttrFromPath;
      in
        assert assertMsg (length indices == length updates) ''
          UPDATING ARRAY MERGE: for each index there must be one corresponding update value, got: ${traceSeqN 1 indices "(see first trace above)"} indices & ${traceSeqN 1 updates "(see second trace above)"} updates''; let
          updated = listToAttrs (
            zipListsWith (
              idx: upd: let
                # manufacture a "here" for display purposes
                tmplhs = setAttrByPath (here ++ [(toString idx)]) (elemAt orig idx);
                tmprhs = setAttrByPath (here ++ [(toString idx)]) upd;
              in {
                name = toString idx;
                value = getAttrFromPath here (
                  # but start from an empty here on this commissioned merge operation
                  mergeAt [] tmplhs tmprhs
                );
              }
            )
            (list int indices)
            (list any updates)
          );
        in
          imap0 (
            i: v:
              if hasAttr "${toString i}" updated
              then updated.${toString i}
              else elemAt orig i
          )
          orig;
      # ------
    };
}
