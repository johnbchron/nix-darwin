{
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helix-fork = {
      url = "github:AlexanderDickie/helix/copilot";
      # inputs.nixpkgs.follows = "nixpkgs";
    };
    copilot-wrapped = {
      url = "./copilot-wrapped";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, ... }@inputs:
  let
    configuration = { pkgs, copilot-wrapped, ... }: {
      environment.systemPackages = with pkgs; [
        # basic shell utils
        wget curl git tree file unzip gzip
  
        # why is docker here? idk. it's not a module :(
        docker

        # fancy shell utils
        fzf btop bat
    
        # proxies and such
        cloudflared # used to proxy ssh
      ];

      # Auto upgrade nix package and the daemon service.
      services.nix-daemon.enable = true;

      nix = {
        settings = {
          auto-optimise-store = true;
          experimental-features = "nix-command flakes";
          substituters = [
            "https://nix-community.cachix.org"
            "https://cache.nixos.org/"
          ];
          trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          ];
        };
      };

      # environment.variables = {
      #   "VISUAL" = "${pkgs.helix}";
      #   "EDITOR" = "${pkgs.helix}";
      # };
      # environment.shellAliases = {
      #   e = "exit";
      #   clr = "clear";
      #   snorbs = "sudo nixos-rebuild switch --flake '/etc/nixos#'";
      #   drbs = "darwin-rebuild switch --flake '/Users/jlewis/nix-darwin#'";
      #   treeg = "tree --gitignore";
      #   nd = "nix develop --command $SHELL";
      # };

      users.users.jlewis.home = "/Users/jlewis/";

      programs.zsh.enable = true;  # default shell on catalina

      system.configurationRevision = self.rev or self.dirtyRev or null;

      system.stateVersion = 4;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = {
        config = "aarch64-apple-darwin";
        system = "aarch64-darwin";
      };
    };
    
    nixpkgsConfig = {
      config = { allowUnfree = true; };
    };
  in
  {
    darwinConfigurations."gimli" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        configuration
        home-manager.darwinModules.home-manager {
          nixpkgs = nixpkgsConfig;

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.jlewis = import ./nix-config/home.nix;
            extraSpecialArgs = { } // inputs;
          };
        }
      ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."gimli".pkgs;
  };
}
