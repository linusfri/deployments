{
  nixpkgs,
  lgl-site,
  uno-api,
  calc-api,
  weland-wp,
  caravanclub-wp,
  verdaccio-config
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
        inherit (pkgs) netdata netdataCloud;
        inherit (lgl-site.packages.${system}) ladugard-live;
        inherit (uno-api.packages.${system}) uno-api;
        inherit (calc-api.packages.${system}) calc-api;
        inherit (weland-wp.packages.${system}) weland-wp;
        inherit (caravanclub-wp.packages.${system}) caravanclub-wp;
        inherit verdaccio-config;
      }
    )
  ];
}
