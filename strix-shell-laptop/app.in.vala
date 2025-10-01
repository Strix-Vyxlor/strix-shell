class App : Gtk.Application {
  static App instance;

  private Bar bar;
  private PowerMenu powermenu;

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
      stderr.printf("Failed to load style: %s", e.message);
      try {
        provider.load_from_data(default_style);
      } catch (Error e) {
        stderr.printf("How did we end up here, (failed to load default css)");
      }
    }
    

    Gtk.StyleContext.add_provider_for_screen(
      Gdk.Screen.get_default(),
      provider,
      Gtk.STYLE_PROVIDER_PRIORITY_USER
    );
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

      add_window((powermenu = new PowerMenu()));
      add_window((bar = new Bar(powermenu)));
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
