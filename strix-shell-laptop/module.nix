{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) mkOption types mkIf mkMerge;
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
    style = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        custom style file.
      '';
    };
    colors = mkOption {
      type = types.nullOr types.attrs;
      default = null;
      description = ''
        colors to use, same attrset as stylix colors.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [cfg.package];

      home.file.".config/strix-shell/laptop/config.json".text = builtins.toJSON cfg.config;
    }
    (mkIf (cfg.style != null || cfg.colors != null) {
      home.file.".config/strix-shell/laptop/style.css".text =
        (
          if (cfg.colors == null)
          then ""
          else
            (builtins.readFile (pkgs.runCommand "generate_style_css" {} ''
              cp ${./.}/style.scss .
              sed -ins "s/2E3400/${cfg.colors.base00}/" style.scss
              sed -ins "s/3B4252/${cfg.colors.base01}/" style.scss
              sed -ins "s/434C5E/${cfg.colors.base02}/" style.scss
              sed -ins "s/4C566A/${cfg.colors.base03}/" style.scss
              sed -ins "s/D8DEE9/${cfg.colors.base04}/" style.scss
              sed -ins "s/E5E9F0/${cfg.colors.base05}/" style.scss
              sed -ins "s/ECEFF4/${cfg.colors.base06}/" style.scss
              sed -ins "s/8FBCBB/${cfg.colors.base07}/" style.scss
              sed -ins "s/BF616A/${cfg.colors.base08}/" style.scss
              sed -ins "s/D08770/${cfg.colors.base09}/" style.scss
              sed -ins "s/EBCB8B/${cfg.colors.base0A}/" style.scss
              sed -ins "s/A3BE8C/${cfg.colors.base0B}/" style.scss
              sed -ins "s/88C0D0/${cfg.colors.base0C}/" style.scss
              sed -ins "s/5E81AC/${cfg.colors.base0D}/" style.scss
              sed -ins "s/B48EAD/${cfg.colors.base0E}/" style.scss
              sed -ins "s/81A1C1/${cfg.colors.base0F}/" style.scss

              ${pkgs.dart-sass}/bin/sass style.scss $out
            ''))
        )
        + (
          if (cfg.style == null)
          then ""
          else cfg.style
        );
    })
  ]);
}
