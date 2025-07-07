{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (config.terraflake.input) node;
in
{
  config = {
    mailserver = {
      enable = true;
      fqdn = "mail.friikod.se";
      domains = [ "friikod.se" ];

      # A list of all login accounts. To create the password hashes, use
      # nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt'
      loginAccounts = {
        "linus@friikod.se" = {
          hashedPasswordFile = config.age.secrets.linusPass.path;
        };
        "carolin@friikod.se" = {
          hashedPasswordFile = config.age.secrets.carroPass.path;
        };
      };

      stateVersion = 3;

      # Use Let's Encrypt certificates. Note that this needs to set up a stripped
      # down nginx and opens port 80.
      certificateScheme = "acme-nginx";
    };

    age.secrets.linusPass = {
      rekeyFile = ../${node.name}/secrets/linus_mail_pass.age;
      generator.script = "passphrase";
    };
    age.secrets.carroPass = {
      rekeyFile = ../${node.name}/secrets/carro_mail_pass.age;
      generator.script = "passphrase";
    };
  };
}
