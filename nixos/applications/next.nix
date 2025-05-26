{ config, pkgs, ... }:
let
  inherit (config.terraflake.input) node nodes;

  startNextApp = pkgs.writeShellScriptBin "start-next-app" ''
    PATH="${pkgs.lib.makeBinPath [ pkgs.nodejs_22 ]}:$PATH"
  
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
