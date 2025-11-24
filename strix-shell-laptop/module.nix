{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) mkOption types mkIf mkMerge literalExpression optional;
  cfg = config.programs.strix-shell.laptop;
  jsonFormat = pkgs.formats.json {};
in {
  options.programs.strix-shell.laptop = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        enable strix-shell-laptop configuration
      '';
    };
    systemd = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          create systemd function to run the shell
        '';
      };

      target = mkOption {
        type = types.str;
        default = config.wayland.systemd.target;
        defaultText = literalExpression "config.wayland.systemd.target";
        example = "sway-session.target";
        description = ''
          The systemd target that will automatically start the Waybar service.

          When setting this value to `"sway-session.target"`,
          make sure to also enable {option}`wayland.windowManager.sway.systemd.enable`,
          otherwise the service may never be started.
        '';
      };
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
        appended to default style if colors is defined
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

      # home.file.".config/strix-shell/laptop/config.json".text = builtins.toJSON cfg.config;
      xdg.configFile."strix-shell/laptop/config.json" = {
        source = jsonFormat.generate "strix-shell-config.json" cfg.config;
        onChange = ''
          ${pkgs.procps}/bin/pkill -u $USER -USR2 strix-shell-laptop || true
        '';
      };
    }
    (mkIf cfg.systemd.enable {
      systemd.user.services.strix-shell-laptop = {
        Unit = {
          Description = "Strix custom shell for laptops";
          PartOf = [
            cfg.systemd.target
            "tray.target"
          ];
          After = [cfg.systemd.target];
          ConditionEnvironment = "WAYLAND_DISPLAY";
          X-Reload-Triggers =
            ["${config.xdg.configFile."strix-shell/laptop/config.json".source}"]
            ++ optional (cfg.style != null && cfg.colors != null) "${config.xdg.configFile."strix-shell/laptop/style.css".source}";
        };

        Service = {
          ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
          ExecStart = "${cfg.package}/bin/strix-shell-laptop";
          KillMode = "mixed";
          Restart = "on-failure";
        };

        Install.WantedBy = [
          cfg.systemd.target
          "tray.target"
        ];
      };
    })
    (mkIf (cfg.style != null || cfg.colors != null) {
      xdg.configFile."strix-shell/laptop/style.css" = mkIf (cfg.style != null) {
        source =
          pkgs.writeText "strix-shell/laptop/style.css"
          (
            if (cfg.colors == null)
            then ""
            else
              (builtins.readFile (pkgs.runCommand "generate_style_css" {} ''
                cp ${./.}/style.scss .
                sed -ins "s/2E3440/${cfg.colors.base00}/" style.scss
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
        onChange = ''
          ${pkgs.procps}/bin/pkill -u $USER -USR2 strix-shell-laptop || true
        '';
      };
    })
  ]);
}
