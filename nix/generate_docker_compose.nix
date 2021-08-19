{ nixpkgs, system, flavour ? "docker", extraConfigurations ? [ ],  ... }:
composition:

let
  pkgs = (import nixpkgs) { inherit system; };
  lib = pkgs.lib;
  modulesPath = "${toString nixpkgs}/nixos";
  compositionSet = composition { inherit pkgs lib modulesPath; };
  nodes = compositionSet.nodes;
  testScriptRaw =
    if compositionSet ? testScript then compositionSet.testScript else "";

  # from nixpkgs/nixos/lib/testing-python.nix
  testScript =
    # Call the test script with the computed nodes.
    if pkgs.lib.isFunction testScriptRaw then
      testScriptRaw { inherit nodes; }
    else
      testScriptRaw;
  testScriptFile = pkgs.writeTextFile {
    name = "test-script";
    text = "${testScript}";
  };
  # name and tag of the base container image
  name = "nxc-docker-base-image";
  tag = "latest";
  dockerComposeConfig = {
    version = "3.4";
    x-nxc = {
      image = import ./generate_image.nix {inherit pkgs name tag;};
      testScript = testScriptFile;
      flavour = "docker";
    };
  };
  baseEnv = pkgs.buildEnv { name = "container-system-env"; paths = [ pkgs.bashInteractive pkgs.coreutils ]; };

  dockerComposeConfig.services = builtins.mapAttrs (nodeName: nodeConfig:
    let
      config = {
        imports = [
          ./systemd.nix
          nodeConfig
        ] ++ extraConfigurations;
      };
      builtConfig = pkgs.nixos config;
    in
    {
      cap_add = [ "SYS_ADMIN" ];
      command = [ "${builtConfig.toplevel}/init" ];
      environment = {
        NIX_REMOTE = "";
        PATH = "/bin:/usr/bin:/run/current-system/sw/bin";
        container = "docker";
      };
      hostname = nodeName;
      image = "${name}:${tag}";
      stop_signal = "SIGINT";
      tmpfs = [
        "/run"
        "/run/wrappers:exec,suid"
        "/tmp:exec,mode=777"
      ];
      tty = true;
      volumes = [
        "/sys/fs/cgroup:/sys/fs/cgroup:ro"
        "/nix/store:/nix/store:ro"
        "${baseEnv}:/run/system:ro"
      ];
  }) nodes;

in
  pkgs.writeTextFile {
    name = "docker-compose.json";
    text = (builtins.toJSON dockerComposeConfig);
  }

