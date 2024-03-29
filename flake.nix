{
  description = "A mini merge DSL for data overlays";
  inputs.nixlib.url = "github:nix-community/nixpkgs.lib";
  inputs.yants = {
    url = "github:divnix/yants";
    inputs.nixpkgs.follows = "nixlib";
  };

  inputs.haumea = {
    url = "github:nix-community/haumea/v0.2.2";
    inputs.nixpkgs.follows = "nixlib";
  };
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

  outputs = {
    self,
    nixlib,
    yants,
    haumea,
  }: let
    inherit (haumea.lib.transformers) liftDefault;
  in
    haumea.lib.load {
      src = ./src;
      transformer = liftDefault;
      inputs = {
        inherit (nixlib) lib;
        inherit yants;
      };
    };
}
