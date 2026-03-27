# secrets.nix — Defines which public keys can decrypt each secret
# User key: nc-gh (for editing secrets from the local machine)
# System key: NixOS host key (for decryption at activation time)
#
# IMPORTANT: After NixOS installation, update the system key with:
#   cat /etc/ssh/ssh_host_ed25519_key.pub
# Then rekey all secrets: agenix --rekey

let
  # User's personal SSH public key (for encrypting/editing secrets)
  user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPNEWwxKAqP5NgqoXz8p4UydYcqDHBKJINCOlmjMaKwJ nc@nc-development";

  # Current machine host key (will change after NixOS install — rekey required)
  system = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJNJQw7mUI7Autq8Ztj4+ihNO3iI9QUe0rIWzacpWMey root@ncasatti-work";

  allKeys = [ user system ];
in
{
  # SSH keys
  "ssh-key-nc-gh.age".publicKeys = allKeys;
  "ssh-key-ncasatti-aws-puertorico.age".publicKeys = allKeys;
  "ssh-key-ncasatti-aws-emser.age".publicKeys = allKeys;
  "ssh-key-xionico-devops.age".publicKeys = allKeys;
  "ssh-key-emser-licenses.age".publicKeys = allKeys;
  "ssh-key-emser-supplai.age".publicKeys = allKeys;

  # SSH config
  "ssh-config.age".publicKeys = allKeys;

  # AWS
  "aws-config.age".publicKeys = allKeys;
  "aws-credentials.age".publicKeys = allKeys;

  # Rclone
  "rclone-config.age".publicKeys = allKeys;
}
