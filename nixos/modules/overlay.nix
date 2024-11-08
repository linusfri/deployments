{ nixpkgs, lgl-site }:

{ ... }: {
  nixpkgs.overlays = [
    (final: prev:
      let
        inherit (prev.stdenv) system;
        pkgs = import nixpkgs {
          inherit system;
        };
      in
      {
        inherit (pkgs) netdata netdataCloud;
        inherit (lgl-site.packages.${system}) ladugard-live;
      })
  ];
}
