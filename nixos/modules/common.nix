{ pkgs, lib, config, ... }: {
  config = {
    time.timeZone = "UTC";
    i18n.defaultLocale = "en_US.UTF-8";

    services.openssh.settings.PasswordAuthentication = false;

    security.acme.defaults.email = "linus@bravomedia.se";
    security.acme.acceptTerms = true;

    users.users.root.openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCzhVNFL+zJsluU3b8lIh2QvgqZ4PGS7O/kPkb5fN/UT6CCY/So78NSrPEB/GlUw+fGzNwxDCB54ylJDKQ+65nZ4qfROcTbpzVphS7Dv2wR+8pIc4cmsn9xMAJGLG0BRE7iE+4ar3FNzPhgKf9YGb/dwNso9lxufT0ssMT5tISj1Rwn+Welu5tqAHwfIBnoBRKgEQ9vYlwInzTtRSkfaS66JZw3vw8G0D7UI6AehwT3/b3rajI1kaIUe8MzDikqC/1ngkXtcA8WYJ3e9JNq9rnjx39AIQGipgaxF2a2MvOa4VSxzOBGYO5HUFB5Z7PQkCw01e1cxMG7rwu7EPTR/LtrUJRUFtC9nFnV1Fj9cTtIq8Jr8AUiCkC3FVcI0AXELuMMzkLwXlCf8839Qz2alTawzowRzT5+rQyqcSJkw0yr6G3UPqvydd7xbF6ZeImrmP+PfdZXmkZmbCa88x0u47awY8Hpv74zPyK+wFbNH7yP/PN+aW14QFTMEdQsxIoEt8cDJC1VdSclA2ZnFnbHdZQFcFRHWwcbv6N0ZrOoPjGxcZ+OgYbXHxDHx3XmL+6Y2R/Hsx1fZv06b0xuQ0v4fDjMJJYTy66Onq4P85nq/qh5DQ4EJgTKzUC5Lq0fDMX3MglfryZe7Wk4NbSpW5XsWpi5s7OK9iSBZOO5UdEGK+ns/w== linus@linus-bravo"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICGavKgHzlln0r9APH/vyVQ5uGB+BXR6ybHoiAdLS+DY linus@nixos"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDa5dGYecErPTzNhNeNPB8ACRMUoFYa37h861d/rtVJvh3gHyo3CFzu8BXxk9wLL2gSI4DPUGtBeJ8+BNPz1o9IxO9DsWpSdUpQ6F9zI+JHL4SDnoyaaypmcxp1w6DmrTmBefqEjZ8FdX0/YrpAbfXGGz3IUDkaLS8e4daGPBcLb41N9BATR902oIaQM6KneOBNsDI1GQ+s6JLUBCLJ8Kd7Z11acxp4yqTcPhAaQ/RhkzhTj5Cz7T8uVj0uWFq6UFin65M7xU0PXPK/5B/LtYq8YwYRPH16oYe+g7aXABm9rIhHqg1emjMZ++8AsRopn3H47FbnSRR6lysh61wrVxYn matssvanteman@Mats-MacBook-Pro.local"
    ];
    users.defaultUserShell = pkgs.zsh;

    nix = {
      gc.automatic = true;
      extraOptions = ''
        experimental-features = nix-command flakes
      '';
      settings = {
        sandbox = "relaxed";
      };
    };

    programs.zsh = {
      enable = true;
      ohMyZsh = {
        theme = "agnoster";
        plugins = [
          "git"
          "zsh-syntax-highlighting"
          "zsh-autosuggestions"
        ];
      };
    };

  };
}
