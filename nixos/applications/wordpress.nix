{
  config,
  pkgs,
  ...
}:
let
  inherit (config.terraflake.input) node;
in
{
  imports = [ ../modules/wordpress-service.nix ];

  services.linusfri.wordpress = {
    enable = true;
    appName = "elin";
    package = pkgs.bedrock-wp; # Replace with your actual package
    user = "elin";
    home = "/var/lib/elin";
    domain = node.domains.elin; # Or use a string like "example.com"
    dbName = "elin_db";
    dbPrefix = "wp_";
    projectDir = "bedrock-wp"; # Adjust based on your package structure

    environment = "production";

    debug = {
      enabled = false;
      display = false;
    };

    ssl = {
      enable = true;
      force = true;
    };

    basicAuth = {
      enable = false;
    };
  };
}
