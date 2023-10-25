# Dmerge

A mini merge DSL for data overlays.

Dmerge is a lightweight alternative to the NixOS module system to wrangle data.
It aims to give you alternative semantics, currently not available in the ecosystem, when you need them.

## Semantics

- Simple semantics: `merge :: lhs -> rhs -> final`
- Monotonistic on the Dataspine
- Expressive Array Merge Decorations
- Typed-by-Precedent

### Simple semantics

```nix
# nix repl

> :lf github:divnix/dmerge

> :p merge { foo = "bar"; } { foo = "baz"; }
{ foo = "baz"; }

> :p merge { foo = [1]; } { foo = append [2]; }
{ foo = [ 1 2 ]; }

> :p merge { foo = [1]; } { foo = prepend [2]; }
{ foo = [ 2 1 ]; }

# update [idx] updates idx on lhs
> :p merge { foo = [1]; } { foo = update [0] [2]; }
{ foo = [ 2 ]; }

# recurses the arrays and attribute sets
> :p merge { foo = [{egg = {color = "yellow";};}]; } { foo = update [0] [{egg = {color = "green";};}]; }
{ foo = [ { egg = { color = "green"; }; } ]; }

# supports associative array merges
> :p merge { people = [{name = "bert"; age = 42;}]; } {people = updateOn "name" [{name = "bert"; age = 43;}]; }
{ people = [ { age = 43; name = "bert"; } ]; }

# chaining
> WithMichi = chainable {michelangelo = { age = 548; };}
> WithRemi = chainable {rembrandt = { age = 417; };}
> WithLeo = chainable {davinci = { age = 571; };}
> mkParty = chainMerge
> :p mkParty WithMichi WithRemi WithLeo {me = {age = 35;};}
{ davinci = { age = 571; }; me = { age = 35; }; michelangelo = { age = 548; }; rembrandt = { age = 417; }; }

```

### Monotonistic on the Dataspine

Dmerge never destroys an Attribute Set or an Array.
Unlike simple values, they are considered the dataspine and must be protected.

If you have a use case for destroying an Attribute Set or Array or plainly overriding an Array,
consider better factorizing your left hand side, instead. It's a symptom of poor factorization.

### Expressive Array Merge Decorations

In the above examples prooving its simplicity, you already got to know the full instruction set
of Dmerge to specify the array merge strategy on the right hand side: `append`, `prepend`, `update` & `updateOn`.

If you don't control the right hand side, but know it's structure, you can `decorate` it:

```nix
merge lhs (decorate rhs { people = updateOn "name";})
```

### Typed by Precedent

You can't modify the type of a left hand side node or leave in the right hand side.

## Tests

Check out the [tests](https://github.com/divnix/dmerge/tree/main/tests) for more examples.

## Implementor's Note

This repo has no `flake.lock`. Chose the dependencies you see fit; assert compatibilty &mdash; chances are high, you'll be fine, though.

**Example Use:**

```nix
# flake.nix
{
  inputs.nixpkgs.url = "github:nixos/nixpkgs";
  inputs.dmerge = {
    url = "github:divnix/dmerge";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.namaka.follows = ""; # testing only dependency
  };

  /* ... */
}
```

## Acknowledgements

- [Haumea](https://github.com/nix-community/haumea) for help me chore
- [Namaka](https://github.com/nix-community/namaka) for testing-made-easy (tm)
- [Cocogitto](https://github.com/cocogitto/cocogitto) for taking the guesswork out of releases
- [nix-quick-install-action](https://github.com/nixbuild/nix-quick-install-action) for making nix in CI a sure quick thing
