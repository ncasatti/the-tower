# nix/home/secrets.nix
# agenix identity paths and secret declarations for Home Manager.
# .age files live in ./secrets/ (relative to this file).

{ config, ... }:

let
  home = config.home.homeDirectory;
  user = config.home.username;
in
{
  # --- IDENTITY: User key used to decrypt secrets at activation time ---
  # We try both the system host key (NixOS) and the user's personal key (Arch/NixOS)
  age.identityPaths = [ 
    "/etc/ssh/ssh_host_ed25519_key"
    "${home}/.ssh/id_ed25519"
  ];

  # --- SECRETS ---
  age.secrets = {
    # SSH keys
    ssh-key-nc-gh = {
      file  = ./secrets/ssh-key-nc-gh.age;
      owner = "${user}";
      path  = "${home}/.ssh/keys/nc-gh";
    };
    ssh-key-ncasatti-aws-puertorico = {
      file  = ./secrets/ssh-key-ncasatti-aws-puertorico.age;
      owner = "${user}";
      path  = "${home}/.ssh/keys/ncasatti-aws-puertorico";
    };
    ssh-key-ncasatti-aws-emser = {
      file  = ./secrets/ssh-key-ncasatti-aws-emser.age;
      owner = "${user}";
      path  = "${home}/.ssh/keys/ncasatti-aws-emser";
    };
    ssh-key-xionico-devops = {
      file  = ./secrets/ssh-key-xionico-devops.age;
      owner = "${user}";
      path  = "${home}/.ssh/keys/xionico-devops-ncasatti-keypair.pem";
    };
    ssh-key-emser-licenses = {
      file  = ./secrets/ssh-key-emser-licenses.age;
      owner = "${user}";
      path  = "${home}/.ssh/keys/emserlicensesserver-v2-key.pem";
    };
    ssh-key-emser-supplai = {
      file  = ./secrets/ssh-key-emser-supplai.age;
      owner = "${user}";
      path  = "${home}/.ssh/keys/emser-supplai-key.pem";
    };

    # SSH config
    ssh-config = {
      file  = ./secrets/ssh-config.age;
      owner = "${user}";
      path  = "${home}/.ssh/config";
    };

    # AWS
    aws-config = {
      file  = ./secrets/aws-config.age;
      owner = "${user}";
      path  = "${home}/.aws/config";
    };
    aws-credentials = {
      file  = ./secrets/aws-credentials.age;
      owner = "${user}";
      path  = "${home}/.aws/credentials";
    };

    # Rclone
    rclone-config = {
      file  = ./secrets/rclone-config.age;
      owner = "${user}";
      path  = "${home}/.config/rclone/rclone.conf";
    };
  };
}
