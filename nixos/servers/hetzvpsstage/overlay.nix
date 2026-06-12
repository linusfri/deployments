{
  nixpkgs,
  ...
}:

{ ... }:
{
  nixpkgs.overlays = [
    (
      final: prev:
      let
        inherit (prev.stdenv) system;
        pkgs = import nixpkgs {
          inherit system;
        };
      in
      {
      }
    )
  ];
}
