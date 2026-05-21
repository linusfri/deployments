{ pkgs, config, ... }:
let
  user = "plantuml";
  group = "plantuml";
  home = "/var/lib/plantuml";
in
{
  services.plantuml-server = {
    enable = true;
    inherit group user home;
  };
}
