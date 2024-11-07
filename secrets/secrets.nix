let
  admin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFysqYr51xIHAb53EaGG8W8uLVJXGsJ77yW3WS+mkZaH";
  linus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICGavKgHzlln0r9APH/vyVQ5uGB+BXR6ybHoiAdLS+DY";
  users = [ admin linus ];
in {
  "secrets.json.age".publicKeys = users;
}
