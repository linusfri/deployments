let
  admin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFysqYr51xIHAb53EaGG8W8uLVJXGsJ77yW3WS+mkZaH";
  linus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICGavKgHzlln0r9APH/vyVQ5uGB+BXR6ybHoiAdLS+DY";
  vps1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAf8Wqvahm9Fm2twattmjSccCLsqpqMHrIft868NWaAd root@vps1";

  users = [ admin linus vps1 ];
in {
  "secrets.json.age".publicKeys = users;
}
