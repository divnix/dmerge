{
  merge,
  update,
  append,
}: let
  merged = {
    ok =
      merge {
        a.b = [
          {c = "c";} # 0
        ];
      } {
        a.b = update [0] [
          {c = "bc";}
        ];
      };
    ok2 =
      merge {
        "foo.yaml" = {bar = [];};
      } {
        "foo.yaml" = {bar = append [1];};
      };
    nok-WrongIndex =
      merge {
        a = [
          {} # 0
        ];
      } {
        a = update [1] [{}];
      };
    nok-InstructionMismatch = merge {a = [{}];} {
      a = update [0] [{} {}];
    };
  };

  inherit (builtins) deepSeq mapAttrs tryEval;
in
  mapAttrs (_: x: tryEval (deepSeq x x)) merged
