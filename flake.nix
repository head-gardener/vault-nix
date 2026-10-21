{
  description = "HashiCorp Vault with the web UI built in";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/cd4ea8d57de16f4810bc5f14207bac45fbf19f67";

  outputs =
    {
      nixpkgs,
      self,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system: f (nixpkgs.legacyPackages.${system}.extend self.overlays.vault-full)
        );
    in
    {
      overlays.vault-full = final: prev: {
        vault-full = final.callPackage ./packages/vault-full.nix { };
      };
      overlays.default = self.overlays.vault-full;

      packages = forAllSystems (pkgs: rec {
        vault-full = pkgs.vault-full;
        default = vault-full;
      });

      nixosModules.vault-full = {
        nixpkgs.overlays = [ self.overlays.vault-full ];
      };
      nixosModules.default = self.nixosModules.vault-full;
    };
}
