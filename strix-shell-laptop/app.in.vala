uint monitor_hash(Gdk.Monitor monitor) {
    Gdk.Rectangle geom = monitor.get_geometry(); 
    return (uint) geom.x ^ (uint) geom.y ^ ((uint) geom.width << 1) ^ ((uint) geom.height << 2);
}

bool monitor_equal(Gdk.Monitor a, Gdk.Monitor b) {
    if (a == null || b == null) return false;

    Gdk.Rectangle ga = a.get_geometry();
    Gdk.Rectangle gb = b.get_geometry(); 

    return ga.x == gb.x && ga.y == gb.y &&
           ga.width == gb.width && ga.height == gb.height;
}



class App : Gtk.Application {
  static App instance;

  private HashTable<Gdk.Monitor,Bar> bars = new HashTable<Gdk.Monitor,Bar>(monitor_hash, monitor_equal);
  private HashTable<Gdk.Monitor,PowerMenu> powermenus = new HashTable<Gdk.Monitor,PowerMenu>(monitor_hash, monitor_equal);

  private string default_style = """@STYLE@""";

  private void init_css(string? user_style) {
    var provider = new Gtk.CssProvider();
    try {
      string css_text;
      string style_file; 
      if (user_style == null)
        style_file = Settings.get_config_dir() + "/style.css";
      else 
        style_file = user_style;

      FileUtils.get_contents(style_file, out css_text);
      provider.load_from_data(css_text);
    } catch (Error e) {
      stderr.printf("Failed to load style: %s\n", e.message);
      try {
        provider.load_from_data(default_style);
      } catch (Error e) {
        stderr.printf("How did we end up here, (failed to load default css)\n");
      }
    }
    

    Gtk.StyleContext.add_provider_for_screen(
      Gdk.Screen.get_default(),
      provider,
      Gtk.STYLE_PROVIDER_PRIORITY_USER
    );
  }

  public void add_monitor(Gdk.Display display, Gdk.Monitor monitor) {
    var powermenu = new PowerMenu(monitor); 
    var bar = new Bar(monitor,powermenu);
    bars.set(monitor,bar);
    powermenus.set(monitor,powermenu);

    add_window(powermenu);
    add_window(bar);
  }

  public void remove_monitor(Gdk.Display display, Gdk.Monitor monitor) {
    if (bars.contains(monitor)) {
      bars.get(monitor).hide();
      bars.remove(monitor);
    }
    if (powermenus.contains(monitor)) {
      powermenus.get(monitor).hide();
      powermenus.remove(monitor);
    }
  }


  public override int command_line(ApplicationCommandLine command_line) {
    var argv = command_line.get_arguments();

    if (command_line.is_remote) {
      command_line.print_literal("hello main from instance");
    } else {

      string? user_config = null;
      string? user_style = null;
      
      for (int i = 1; i < argv.length ; i++) {
        switch (argv[i]) {
          case "--config":
          case "-c":
            i++;
            print("using config file: %s", argv[i]);
            user_config = argv[i];
            break;
          case "--theme":
          case "-t":
            i++;
            print("using theme file: %s", argv[i]);
            user_style = argv[i];
            break;
        }
      }

      if (Settings.parse(user_config) == -1) 
        return -1;

      init_css(user_style);

      Gdk.Display display = Gdk.Display.get_default ();
      display.monitor_added.connect(add_monitor);
      display.monitor_removed.connect(remove_monitor);

      int n_monitors = display.get_n_monitors();
      for (int i = 0; i < n_monitors; i++) {
        var monitor = display.get_monitor(i);
        add_monitor(display, monitor); // Reuse same callback
      }
    }

    return 0;
  }
 
  private App() {
    application_id = "com.strixos.laptop-bar";
    flags = ApplicationFlags.HANDLES_COMMAND_LINE;
  }

  static int main(string[] argv) {
    App.instance = new App();
    Environment.set_prgname("strixos-laptop-bar");
    return App.instance.run(argv);
  }
}
