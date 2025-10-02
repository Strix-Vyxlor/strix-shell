{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) mkOption types mkIf;
  cfg = config.programs.strix-shell.laptop;
in {
  options.programs.strix-shell.laptop = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        enable strix-shell-laptop configuration
      '';
    };
    package = mkOption {
      type = types.package;
      default = pkgs.strix-shell.laptop;
      description = ''
        package to use
      '';
    };
    config = mkOption {
      type = types.attrs;
      default = {
        power_commands = {
          shutdown = "systemctl poweroff";
          reboot = "systemctl reboot";
          logout = "hyprctl dispatch exit";
          hibernate = "systemctl hibernate";
        };
      };
      description = ''
        config for strix-shell-laptop
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [cfg.package];

    home.file.".config/zix/config.json".text = builtins.toJSON cfg.config;
  };
}
