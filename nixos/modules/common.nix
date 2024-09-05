{ pkgs, lib, config, ... }: {
  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh.settings.PasswordAuthentication = false;

  security.acme.defaults.email = "chris@randomware.se";
  security.acme.acceptTerms = true;

  nix = {
    gc.automatic = true;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
}
