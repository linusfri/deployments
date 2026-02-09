# Node Deployment

This repository enables provisioning and configuration a Hetzner VPS.

## Setup Environment

To get bootstrapped you need the following:

- Install Nix: `sh <(curl -L https://nixos.org/nix/install) --no-daemon`
- Configure Nix to enable flakes: `echo experimental-features = nix-command flakes >> ~/.config/nix/nix.conf`
- Run `nix develop` or install [direnv](https://direnv.net/) for convenience
(recommended)

## Provisioning

Creating the basic infrastructure such as VPSs and DNS records, i.e.
infrastructure provisioning is done using `opentofu`.

The most important configuration file is `./opentofu/main.tf` and the high level
parameters are in `./opentofu/terraform.tfvars`.

Currently the providers configured are Cloudflare for DNS and Hetzner for VPSs.

## Configuring Each Node

Node configuration is done using NixOS and a CLI tool called `terraflake`. This is wrapped in this repo to fetch remote tofu state before execution.
It's called `tofuflake`

The root configuration file for the seed nodes is `./nixos/vps1.nix` and follows
the format of [NixOS's `configuration.nix`](https://nixos.org/manual/nixos/stable/#sec-configuration-file).
To configure the monitoring node look in `./nixos/monitor.nix`.

To push the configuration to all nodes after they have been provisioned run:

```sh
tofuflake push
```

This will "infect" any non-NixOS VPS and install NixOS on it making sure the
final state of a node matches the configuration of this repo.

## Agenix
### Generate age identity
```sh
age -p -o keyfile.age <(age-keygen)
```
### Create secrets
Create a secret in the nixos module that will use it.
```
age.secrets.NAME_OF_SECRET = {
    rekeyFile = ./secrets/NAME_OF_SECRET.age;
    generator.script = "passphrase";
};
```

### Generate the actual secret file
```sh
tofuage generate -a # -a for adding to git

tofuage rekey -a # rekey the secrets to specfied host ssh public key
```

### To edit secrets after generation and rekey
```sh
tofuage edit
```
