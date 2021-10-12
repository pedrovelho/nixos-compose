{
  description = "nixos-compose - simple mutiple compositions";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      compositions = import ./compositions.nix;
      flavours = import ./nix/flavours.nix;
    in {

      packages.${system} = (import ./nix/compose.nix) {
        inherit nixpkgs system compositions flavours;
      };

      defaultPackage.x86_64-linux = self.packages.${system}."bar::nixos-test";
    };
}
