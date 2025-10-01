public class Settings {
  public static Json.Node? settings = null;
  public static string? config_dir = null;

  public static void get_config_dir() {
    string xdg_config_home = GLib.Environment.get_user_config_dir();
    config_dir = xdg_config_home + "/strix-shell/laptop";
  }

  public static void parse() {
    try {
      string json_text;
      string config_file = config_dir + "/settings.json";
      FileUtils.get_contents(config_file, out json_text);
      Json.Parser parser = new Json.Parser();
      parser.load_from_data(json_text);
      settings = parser.get_root();
    } catch (Error e) {
      stderr.printf("Failed to load JSON: %s\n", e.message);
    }
  }
}

