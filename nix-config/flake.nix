{
  description = "richard's NixOS system";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix.url="github:ryantm/agenix";
  };
  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, agenix, ... }:
  let
    system = "x86_64-linux";
    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit agenix; };
      modules = [
        ./configuration.nix
	agenix.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.richard = import ./home.nix;
          home-manager.extraSpecialArgs = { inherit pkgs-unstable; };
          nixpkgs.config.allowUnfree = true;
        }
      ];
    };
  };
}
