{ config, pkgs, ... }:
let
  name = "enshrouded";
  appDir = "/var/lib/${name}";
  configFile = "enshrouded-config";
  generatedEnvPath = "${appDir}/.env";
  inherit (config.terraflake.input) node;

  createEnv = pkgs.writeShellScriptBin "create-env" ''
    mkdir -p ${appDir}

    cat ${config.age.secrets.${configFile}.path} > ${generatedEnvPath}
  '';
in
{
  users.users.root.extraGroups = [ "docker" ];
  virtualisation = {
    arion = {
      backend = "docker";
      projects = {
        "app".settings.services."${name}".service = {
          image = "sknnr/enshrouded-dedicated-server:latest";
          restart = "unless-stopped";
          env_file = [ "${generatedEnvPath}" ];
          ports = [
            "15636:15636/udp"
            "15637:15637/udp"
          ];
          volumes = [
            "${appDir}:/home/steam/${name}/savegame"
          ];
        };
      };
    };
  };

  age.secrets."${configFile}" = {
    rekeyFile = ../servers/${node.name}/secrets/${configFile};
    generator.script = "passphrase";
  };

  systemd.services."${name}-env" = {
    description = "Creates an env file";
    serviceConfig = {
      ExecStart = "${createEnv}/bin/create-env";
      Type = "simple";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
