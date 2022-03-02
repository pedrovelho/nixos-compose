{
  description = "nixos-compose - simple mutiple compositions";

  inputs = { 
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; 
    nxc.url = "git+https://gitlab.inria.fr/nixos-compose/nixos-compose.git";
  };

  outputs = { self, nixpkgs, nxc }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages.${system} = nxc.lib.compose {
        inherit nixpkgs system;
        compositions = ./compositions.nix;
      };

      defaultPackage.${system} =
        self.packages.${system}."linux_5_4::nixos-test";

      devShell.${system} =
        pkgs.mkShell { buildInputs = [ nxc.defaultPackage.${system} ]; };
    };
}
