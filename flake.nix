{

  description = "Crazy Shell";

  nixConfig = {
    extra-substituters = "https://horizon.cachix.org";
    extra-trusted-public-keys = "horizon.cachix.org-1:MeEEDRhRZTgv/FFGCv3479/dmJDfJ82G6kfUDxMSAw0=";
  };

  inputs = {
    get-flake.url = "github:ursi/get-flake";
    flake-utils.url = "github:numtide/flake-utils";
    horizon-platform.url = "git+https://gitlab.horizon-haskell.net/package-sets/horizon-platform";
    lint-utils = {
      url = "git+https://gitlab.homotopic.tech/nix/lint-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    inputs@
    { self
    , get-flake
    , flake-utils
    , horizon-platform
    , lint-utils
    , nixpkgs
    , ...
    }:
    let
      mkCrazyShell = import ./mkCrazyShell.nix;
    in
    flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" ] (system:
    let

      pkgs = import nixpkgs { inherit system; };

      haskellPackages = horizon-platform.legacyPackages.${system};

      defaultCrazyShell = mkCrazyShell { inherit pkgs haskellPackages; };

    in
    {

      apps = {

        default = {
          program = "${defaultCrazyShell}/bin/crazy-shell";
          type = "app";
        };

      };

      checks =
        with lint-utils.outputs.linters.${system}; {
          dhall-format = dhall-format { src = self; };
          nixpkgs-fmt = nixpkgs-fmt { src = self; };
          stylish-haskell = stylish-haskell { src = self; };
        };

      packages.default = defaultCrazyShell;

    }) // { lib = { inherit mkCrazyShell; }; };
}
