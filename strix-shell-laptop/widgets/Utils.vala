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

public class SleepInhibitorController : Object {
  private static SleepInhibitorController? _instance;
  public static SleepInhibitorController instance {
    get {
      if (_instance == null) {
        _instance = new SleepInhibitorController();
      }
      return _instance;
    }
  }

  private bool _active = false;
  private DBusProxy? screensaver_proxy = null;
  private uint inhibit_cookie = 0;

  public bool active {
    get { return _active; }
    set {
      if (_active != value) {
        _active = value;
        notify_property("active");

        if (_active) {
          inhibit_sleep.begin();
        } else {
          uninhibit_sleep();
        }
      }
    }
  }

  public void toggle() {
    active = !active;
  }

  private async void inhibit_sleep() {
    try {
      if (screensaver_proxy == null) {
        screensaver_proxy = new DBusProxy.for_bus_sync(
          BusType.SESSION,
          DBusProxyFlags.NONE,
          null,
          "org.freedesktop.ScreenSaver",
          "/org/freedesktop/ScreenSaver",
          "org.freedesktop.ScreenSaver"
        );
      }

      inhibit_cookie = screensaver_proxy.call_sync(
        "Inhibit",
        new Variant("(ss)", "MyApp", "Preventing sleep"),
        DBusCallFlags.NONE,
        -1,
        null
      ).get_child_value(0).get_uint32();

    } catch (Error e) {
      stderr.printf("Failed to inhibit sleep: %s\n", e.message);
    }
  }

  private void uninhibit_sleep() {
    if (screensaver_proxy != null && inhibit_cookie != 0) {
      try {
        screensaver_proxy.call_sync(
          "UnInhibit",
          new Variant("(u)", inhibit_cookie),
          DBusCallFlags.NONE,
          -1,
          null
        );
      } catch (Error e) {
        stderr.printf("Failed to uninhibit sleep: %s\n", e.message);
      }
    }
  }
}

