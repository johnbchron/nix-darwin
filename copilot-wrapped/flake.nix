{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = (import nixpkgs) {
          inherit system;
        };

        copilot-wrapped = pkgs.writeShellScriptBin "copilot" ''
          ${pkgs.nodejs}/bin/node ${pkgs.vimPlugins.copilot-vim}/dist/agent.js $@
        '';
      in {
        packages = {
          inherit copilot-wrapped;
          default = copilot-wrapped;
        };
      }
    );
}
