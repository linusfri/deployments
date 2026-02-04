{
  config,
  pkgs,
  ...
}:
let
  inherit (config.terraflake.input) node;
in
{
  imports = [ ../modules/wordpress/wordpress-service.nix ];

  services.linusfri.wordpress.sites = {
    # ladugard = {
    #   appName = "ladugard";
    #   package = pkgs.bedrock-wp; # Replace with your actual package
    #   user = "ladugard";
    #   home = "/var/lib/ladugard";
    #   domain = node.domains.ladugardlive-web; # Or use a string like "example.com"
    #   dbName = "ladugard_db";
    #   dbPrefix = "wp_";
    #   projectDir = "bedrock-wp"; # Adjust based on your package structure

    #   environment = "production";

    #   debug = {
    #     enabled = false;
    #     display = false;
    #   };

    #   ssl = {
    #     enable = true;
    #     force = true;
    #   };

    #   basicAuth = {
    #     enable = false;
    #   };
    # };
    elin = {
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

  };
}
