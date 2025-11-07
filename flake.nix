{
  description = "custom shell writen with astal";
  outputs = inputs @ {self, ...}:
    inputs.flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            (import ./overlay.nix inputs)
          ];
        };
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            meson
            ninja
            pkg-config
            vala
            gobject-introspection
            dart-sass
            inputs.astal.packages.${system}.default
            vala-language-server
          ];

          buildInputs =
            (with inputs.astal.packages.${system}; [
              astal3
              tray
              hyprland
              battery
              network
            ])
            ++ (with pkgs; [
              gtk3
              json-glib
              libgtop.dev
              pkg-config
            ]);
        };

        packages.laptop = pkgs.strix-shell.laptop;
      }
    )
    // {
      overlays = rec {
        default = strix-shell;
        strix-shell = import ./overlay.nix inputs;
      };

      homeManagerModules = rec {
        default = strix-shell;
        strix-shell = {imports = [(import ./module.nix inputs)];};
      };
    };

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
