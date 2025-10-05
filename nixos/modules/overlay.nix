{
  nixpkgs,
  lgl-site,
  calc-api,
  website-for-friends,
  auth-server,
  strapi,
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
        inherit (auth-server.packages.${system}) auth-server;
        inherit (website-for-friends.packages.${system}) bedrock-wp;
        inherit (strapi.packages.${system}) next;
        strapiHashProd = strapi.strapiHash.${system};
      }
    )
  ];
}
