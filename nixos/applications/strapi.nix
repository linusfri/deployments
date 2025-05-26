{
  imageVersion ? "latest",
}:
{ config, pkgs, ... }:
let
  inherit (config.terraflake.input) node nodes;

  user = "strapi_user";
  home = "/var/lib/${user}";

  dockerLogin = pkgs.writeShellScriptBin "docker-login" ''
    PATH="${pkgs.lib.makeBinPath [ pkgs.docker ]}:$PATH"
    GHCR_PASS=$(cat ${config.age.secrets.ghcrPass.path})
    docker login ghcr.io -u linusfri -p "$GHCR_PASS"

    if [[ $? == 0 ]]; then
      echo "Docker login succeded for linusfri."
      exit 0
    fi
  '';

  generateEnv = pkgs.writeShellScriptBin "generate-env" ''
    cat ${config.age.secrets.strapiEnv.path} > /var/lib/${user}/.env
  '';
in
{
  config = {
    services.linusfri.strapi = {
      enable = true;
      inherit user;
      inherit home;
      inherit imageVersion;
      databaseName = "strapi";
      domainName = node.domains.strapi;
      port = 1337;
      inherit dockerLogin;
      inherit generateEnv;
    };

    age.secrets.ghcrPass = {
      rekeyFile = ../${node.name}/secrets/ghcr_pass.age;
      generator.script = "passphrase";
    };

    age.secrets.strapiEnv = {
      rekeyFile = ../${node.name}/secrets/strapi_env.age;
      generator.script = "passphrase";
    };
  };
}
