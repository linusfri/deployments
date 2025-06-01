{ config, pkgs, ... }:
let
  inherit (config.terraflake.input) node nodes;

  startNextApp = pkgs.writeShellScriptBin "start-next-app" ''
    set -a

    PATH="${pkgs.lib.makeBinPath [ pkgs.nodejs_22 ]}:$PATH"

    NEXT_PRIVATE_STRAPI_TOKEN=021821b207e6bb26be756efd970d8a8f09b8927dd9b5ef00b7ee87109389982c1f2450719cbb6617112a0fcfce9a3a4e2bf6a1785345f8942d3727490f8a62636c76517b57615022017c17712a9f52048109c3d8f373b905a7b39820e60a8ffe82609b44f2da84edef704d690957e26cdf48549de1a327bcc63c285c5d694b2f
    NEXT_PUBLIC_API_URL=https://${node.domains.strapi}
    NEXT_PUBLIC_API_DOMAIN=strapi.friikod.se

    echo $NEXT_PUBLIC_API_URL

    ${pkgs.next}/lib/node_modules/frontend/node_modules/.bin/next start ${pkgs.next}/lib/node_modules/frontend
  '';
in
{
  config = {
    services.linusfri.nextjs = {
      enable = true;
      user = "nextuser";
      home = "/var/lib/nextuser";
      domainName = node.domains.next;
      port = 3000;
      startScript = startNextApp;
    };
  };
}
