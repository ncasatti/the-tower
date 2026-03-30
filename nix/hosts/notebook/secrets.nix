# nix/hosts/notebook/secrets.nix
# agenix identity paths and secret declarations.
# .age files live in ./secrets/ (relative to this file).

{ ... }:

{
  # --- IDENTITY: Host key used to decrypt secrets at activation time ---
  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # --- SECRETS ---
  age.secrets = {
    # SSH keys
    ssh-key-nc-gh = {
      file  = ./secrets/ssh-key-nc-gh.age;
      owner = "flyn";
      group = "users";
      mode  = "0600";
      path  = "/home/flyn/.ssh/keys/nc-gh";
    };
    ssh-key-ncasatti-aws-puertorico = {
      file  = ./secrets/ssh-key-ncasatti-aws-puertorico.age;
      owner = "flyn";
      group = "users";
      mode  = "0600";
      path  = "/home/flyn/.ssh/keys/ncasatti-aws-puertorico";
    };
    ssh-key-ncasatti-aws-emser = {
      file  = ./secrets/ssh-key-ncasatti-aws-emser.age;
      owner = "flyn";
      group = "users";
      mode  = "0600";
      path  = "/home/flyn/.ssh/keys/ncasatti-aws-emser";
    };
    ssh-key-xionico-devops = {
      file  = ./secrets/ssh-key-xionico-devops.age;
      owner = "flyn";
      group = "users";
      mode  = "0600";
      path  = "/home/flyn/.ssh/keys/xionico-devops-ncasatti-keypair.pem";
    };
    ssh-key-emser-licenses = {
      file  = ./secrets/ssh-key-emser-licenses.age;
      owner = "flyn";
      group = "users";
      mode  = "0600";
      path  = "/home/flyn/.ssh/keys/emserlicensesserver-v2-key.pem";
    };
    ssh-key-emser-supplai = {
      file  = ./secrets/ssh-key-emser-supplai.age;
      owner = "flyn";
      group = "users";
      mode  = "0600";
      path  = "/home/flyn/.ssh/keys/emser-supplai-key.pem";
    };

    # SSH config
    ssh-config = {
      file  = ./secrets/ssh-config.age;
      owner = "flyn";
      group = "users";
      mode  = "0600";
      path  = "/home/flyn/.ssh/config";
    };

    # AWS
    aws-config = {
      file  = ./secrets/aws-config.age;
      owner = "flyn";
      group = "users";
      mode  = "0600";
      path  = "/home/flyn/.aws/config";
    };
    aws-credentials = {
      file  = ./secrets/aws-credentials.age;
      owner = "flyn";
      group = "users";
      mode  = "0600";
      path  = "/home/flyn/.aws/credentials";
    };

    # Rclone
    rclone-config = {
      file  = ./secrets/rclone-config.age;
      owner = "flyn";
      group = "users";
      mode  = "0600";
      path  = "/home/flyn/.config/rclone/rclone.conf";
    };
  };
}
