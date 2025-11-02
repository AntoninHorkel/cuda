{
  description = "TODO";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    zig-overlay = {
      url = "github:mitchellh/zig-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    zls-overlay = {
      url = "github:zigtools/zls";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        zig-overlay.follows = "zig-overlay";
      };
    };
    # TODO: Remove when https://github.com/NixOS/nixpkgs/pull/428369 gets merged!
    tracy-upgrade.url = "github:MonaMayrhofer/nixpkgs/tracy-upgrade";
  };
  outputs =
    {
      nixpkgs,
      flake-utils,
      zig-overlay,
      # zls-overlay,
      tracy-upgrade,
      ...
    }:
    (flake-utils.lib.eachSystem nixpkgs.lib.platforms.linux) (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (final: prev: {
              tracy = (import tracy-upgrade { inherit system; }).tracy;
              zig = zig-overlay.packages.${system}.master; # "0.15.1"
              # zls = zls-overlay.packages.${system}.zls; # TODO
            })
          ];
        };
      in
      {
        devShells.default = pkgs.mkShellNoCC {
          packages = with pkgs; [
            lldb
            nixfmt-tree
            poop
            strace
            tinymist
            tracy
            typst
            zig
            zls
          ];
          NIX_ENFORCE_NO_NATIVE = 0;
        };
        formatter = pkgs.nixfmt-tree;
      }
    );
}
