{ nixpkgs, lgl-site }:

{ ... }: {
  nixpkgs.overlays = [
    (final: prev:
      let
        pkgs = import nixpkgs {
          inherit (prev.stdenv) system;
        };
      in
      {
        inherit (pkgs) netdata netdataCloud;
        inherit lgl-site;
      })
  ];
}
