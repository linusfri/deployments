{
  nixpkgs,
  lgl-site,
  calc-api,
  website-for-friends,
  handy-gleam,
  strapi,
  github-docs
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
        inherit (calc-api.packages.${system}) calc-api;
        inherit (handy-gleam.packages.${system}) handygleam;
        inherit (website-for-friends.packages.${system}) bedrock-wp;
        inherit (strapi.packages.${system}) next;
        github-doc-sync = github-docs.packages.${system}.default;
        strapiHashProd = strapi.strapiHash.${system};
      }
    )
  ];
}
