{ description = "A mini merge DSL for data overlays";
  inputs.nixlib.url = "github:nix-community/nixpkgs.lib";
  outputs = { self, nixlib }: let

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

    mergeAt = here: lhs: rhs:
    let
      inherit (builtins) isAttrs head tail typeOf concatStringsSep;
      inherit (nixlib.lib) zipAttrsWith isList isFunction;

      f = attrPath:
        zipAttrsWith (n: values:
          let
            here' = attrPath ++ [ n ];
            rhs' = head values;
            lhs' = head (tail values);
            isSingleton = tail values == [ ];
          in
          if isSingleton then head values
          else if !(isAttrs lhs' && isAttrs rhs')
          then
            if (typeOf lhs') != (typeOf rhs') && !(isList lhs' && isFunction rhs')
            then abort "rigt-hand-side must be of the same type as left-hand-side at '${concatStringsSep ''.'' here'}'"
            else if isList lhs' && isList rhs'
            then abort "rigt-hand-side list is not allowed to override left-hand-side list, this would break incrementality of the data spine. Use one of the array merge functions instead at '${concatStringsSep ''.'' here'}'"
            # array function merge
            else if isList lhs' && isFunction rhs' then rhs' lhs' here'
            else rhs'
          else f here' values
       );
    in f here [ rhs lhs ];

  in {

    merge = mergeAt [ ];

    append = new: orig: here: let
      inherit (builtins) isList typeOf concatStringsSep;
      inherit (nixlib.lib) assertMsg;
    in
      assert assertMsg (isList new) "appending array merge: right-hand-side must be a list, got: ${typeOf new} at '${concatStringsSep ''.'' here}'";
      orig ++ new;

    update = indices: updates: orig: here: let
      inherit (builtins) isList all isInt length typeOf listToAttrs elemAt hasAttr concatStringsSep;
      inherit (nixlib.lib) zipListsWith imap0 assertMsg;
    in
      assert assertMsg (isList indices && all (i: isInt i) indices)
        "updating array merge: first argument must be a list of indices of items to update in the left-hand-side list, got: ${indices} at '${concatStringsSep ''.'' here}'";
      assert assertMsg (isList updates) "updating array merge: right-hand-side must be a list, got: ${typeOf updates} at '${concatStringsSep ''.'' here}'";
      assert assertMsg (length indices == length updates)
        "updating array merge: for each index there must be one corresponding update value, got: ${length indices} indices & ${length updates} updates at '${concatStringsSep ''.'' here}'";
      let
        updated = listToAttrs (
          zipListsWith (idx: upd:
            {
              name = toString idx;
              value = (mergeAt here
                { mergedListItem = (elemAt orig idx); }
                { mergedListItem = upd; }
              ).mergedListItem;
            }
          ) indices updates);
      in imap0 (i: v:
        if hasAttr "${toString i}" updated
        then updated.${toString i}
        else elemAt orig i
      ) orig;
  };
}

