{lib}: let
  inherit (builtins) isAttrs hasAttr head tail typeOf concatStringsSep tryEval unsafeGetAttrPos;
  inherit (lib) zipAttrsWith isList isFunction getAttrFromPath;
  #
  # decorateAt: takes a given right-hand side and allows you to decorate its arrays with
  # array merge instructions.
  #
  # Type:
  #   [ String ] -> rhs -> dec -> rhs'
  #
in
  here: lhs: rhs: let
    f = attrPath: rhs_: lhs_:
      zipAttrsWith (
        n: values: let
          here' = attrPath ++ [n];
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
          if isSingleton
          then
            if hasAttr n rhs_ # rhs-singleton
            then
              throw ''

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
              throw ''

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
    f here rhs lhs
