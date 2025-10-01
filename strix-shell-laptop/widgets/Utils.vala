public class Settings {
  public static Json.Node? settings = null;

  public static string get_config_dir() {
    string xdg_config_home = GLib.Environment.get_user_config_dir();
    return xdg_config_home + "/strix-shell/laptop";
  }

  public static int parse(string? user_config = null) {
    try {
      string json_text;
      string config_file;

      if (user_config == null)
        config_file = get_config_dir() + "/config.json";
      else 
        config_file = user_config;

      FileUtils.get_contents(config_file, out json_text);
      Json.Parser parser = new Json.Parser();
      parser.load_from_data(json_text);
      settings = parser.get_root();
    } catch (Error e) {
      stderr.printf("Failed to load JSON: %s\nUsing Defaults\n", e.message);
      try {
      Json.Parser parser = new Json.Parser();
        parser.load_from_data("""
          {
            "power_commands": {
              "shutdown": "systemctl poweroff",
              "reboot": "systemctl reboot",
              "logout": "logout",
              "hibernate": "systemctl hibernate"
            }
          }
        """);
      } catch (Error e) {
        stderr.printf("how did we end up here, (failed to parse defaults)");
        return -1;
      }
    }
    return 0;
  }
}

