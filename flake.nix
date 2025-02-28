{
  description = "Kassadin!";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    rke2.url = "github:numtide/nixos-rke2";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    sops-nix = {
	url = "github:Mic92/sops-nix";
        inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs,  sops-nix, nixpkgs-unstable, vscode-server, ... } @inputs : let 
 	inherit (self) outputs; 
	unstable-pkgs = import nixpkgs-unstable {
		system = "x86_64-linux";
	};
	in 
  {
	nixosConfigurations = { 
		"Kassadin" = nixpkgs.lib.nixosSystem { 
 			specialArgs = { inherit inputs outputs unstable-pkgs; }; 
 			system = "x86_64-linux";
			modules = [ 
				./configuration.nix 
				sops-nix.nixosModules.sops
                                vscode-server.nixosModules.default
                                ({ config, pkgs, ... }: {
                                  services.vscode-server.enable = true;
                                })
			];
		};
	};
  };
}