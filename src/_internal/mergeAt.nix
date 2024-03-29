{lib}: let
  inherit (builtins) isAttrs head tail typeOf concatStringsSep tryEval unsafeGetAttrPos;
  inherit (lib) zipAttrsWith isList isFunction getAttrFromPath;
  #
  # mergeAt: recursively merges left- & right-hand side
  # while keeping a cursor for good error reporting.
  #
  # Type:
  #   [ String ] -> lhs -> rhs -> merged
  #

  tryArrayMerge = cr: lhs: rhs: rhsFilePos: lhsFilePos:
    assert !(typeOf lhs == "list")
    -> throw ''

      During an attempted array merge, left-hand-side is not a list:
      - lhs: ${typeOf lhs} @ ${lhsFilePos}
    '';
    assert !(isFunction rhs)
    -> throw ''

      During an attempted array merge, right-hand-side is not a function:
      - rhs: ${typeOf rhs} @ ${rhsFilePos}
    '';
    assert !(isFunction (rhs lhs))
    -> throw ''

      During an attempted array merge, the result of left-hand-side applied to right-hand-side is not a function:
      - lhs: ${typeOf lhs} @ ${lhsFilePos}
      - rhs: ${typeOf rhs} @ ${rhsFilePos}
      - (rhs lhs): ${typeOf (rhs lhs)}
    ''; let
      ex = tryEval (rhs lhs cr);
    in
      if ex.success
      then ex.value
      else
        throw ''

          Array merge function error (see trace above the error line for details) on the right-hand-side:
          - rhs: ${typeOf rhs} @ ${rhsFilePos}
        '';
in
  cursor: lhs: rhs: let
    f = attrPath:
      zipAttrsWith (
        n: values: let
          cursor' = attrPath ++ [n];
          rhs' = head values;
          lhs' = head (tail values);
          isSingleton = tail values == [];
          singleton = head values;
          lhsFilePos = let
            lhsPos = unsafeGetAttrPos n (getAttrFromPath attrPath lhs);
          in
            if lhsPos != null
            then "${lhsPos.file}:${toString lhsPos.line}:${toString lhsPos.column}"
            else "undetectable posision";
          rhsFilePos = let
            rhsPos = unsafeGetAttrPos n (getAttrFromPath attrPath rhs);
          in
            if rhsPos != null
            then "${rhsPos.file}:${toString rhsPos.line}:${toString rhsPos.column}"
            else "undetectable posision";
        in
          if (isSingleton && isFunction singleton)
          then tryArrayMerge cursor' [] rhs' rhsFilePos lhsFilePos # empty lhs
          else if isSingleton
          then
            if (isAttrs singleton) # descend if it's an attrset
            then f cursor' [{} singleton]
            else singleton
          else if !(isAttrs lhs' && isAttrs rhs')
          then
            if (typeOf lhs') != (typeOf rhs') && !(isList lhs' && isFunction rhs')
            then
              throw ''

                rigt-hand-side must be of the same type as left-hand-side
                at '${concatStringsSep "." cursor'}':
                - lhs: ${typeOf lhs'} @ ${lhsFilePos}
                - rhs: ${typeOf rhs'} @ ${rhsFilePos}
              ''
            else if isList lhs' && isList rhs'
            then
              throw ''

                rigt-hand-side list is not allowed to override left-hand-side list,
                this would break incrementality of the data spine. Use one of the array
                merge functions instead at '${concatStringsSep "." cursor'}':
                - lhs: ${typeOf lhs'} @ ${lhsFilePos}
                - rhs: ${typeOf rhs'} @ ${rhsFilePos}

                Available array merge functions:
                - data-merge.update [ idx ... ] [ v ... ]
                - data-merge.append [ v ]
              ''
            # array function merge
            else if isList lhs' && isFunction rhs'
            then tryArrayMerge cursor' lhs' rhs' rhsFilePos lhsFilePos
            else rhs'
          else f cursor' values
      );
  in
    f cursor [rhs lhs]
