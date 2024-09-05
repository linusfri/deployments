let
  admin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFysqYr51xIHAb53EaGG8W8uLVJXGsJ77yW3WS+mkZaH";
  users = [ admin ];
in {
  "secrets.json.age".publicKeys = users;
}
