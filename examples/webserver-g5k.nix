let
  flavour = {
    name = "kexec-g5k";
    nixpkgs = import
      (fetchTarball "https://github.com/NixOS/nixpkgs/archive/20.09.tar.gz") { };
    image = {
      distribution = "all-in-one";
      type = "ramdisk";
    };
    extraModule = { pkgs, ... }:
      let
        g5k-ssh-host-keys = pkgs.stdenv.mkDerivation rec {
          name = "g5k-ssh-keys";
          src = pkgs.fetchgit {
            url = "https://gitlab.inria.fr/grid5000/g5k-postinstall";
            rev = "2f55241e8ed7ba82e2582b019b99a7299e58305e";
            sha256 = "KxfKjwm/vHE3vblRMe3dXZzZMGK+kq6uAybBbhyy3sU=";
          };
          installPhase = "mv ssh_host_keys $out/";
        };
      in {
        environment.etc."post-boot-script-00-g5k-ssh-keys" = {
          mode = "0755";
          source = pkgs.writeText "post-boot-script-00-g5k-ssh-keys" ''
            #!${pkgs.bash}/bin/bash
            ip_addr=$(cat /etc/ip_addr)
            ssh_host_keys_dir=$(${pkgs.findutils}/bin/find /etc/ssh_host_keys/ -name $ip_addr)
            if [ ! -z "$ssh_host_keys_dir" ]; then
               cp $ssh_host_keys_dir/ssh_host_* /etc/ssh
               chmod 0600 /etc/ssh/ssh_host_*
            else
               echo "Warning does not find ssh_host_keys for $ip_addr"
            fi
          '';
        };

        environment.etc.ssh_host_keys.source = g5k-ssh-host-keys;
        environment.systemPackages = [ pkgs.wget ]; # g5k-ssh-host-keys];
      };
  };
in import <compose> flavour ({ pkgs, ... }: {
  nodes = {
    server = { pkgs, ... }: {
      services.nginx = {
        enable = true;
        # a minimal site with one page
        virtualHosts.default = {
          root = pkgs.runCommand "testdir" { } ''
            mkdir "$out"
            echo hello world > "$out/index.html"
          '';
        };
      };
      networking.firewall.enable = false;
    };
    client = { ... }: { };
  };
  testScript = ''
    server.wait_for_unit("nginx.service")
    client.wait_for_unit("network.target")
    assert "hello world" in client.succeed("curl -sSf http://server/")
  '';
})
