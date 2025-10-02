inputs: {
  pkgs,
  config,
  lib,
  ...
}: {
  imports = [
    ./strix-shell-laptop/module.nix
  ];

  config = {
    nixpkgs.overlays = [
      (import ./overlay.nix inputs)
    ];
  };
}
