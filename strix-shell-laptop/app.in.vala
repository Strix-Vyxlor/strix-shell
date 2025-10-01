class App : Gtk.Application {
  static App instance;

  private Bar bar;
  private PowerMenu powermenu;

  private string default_style = """@STYLE@""";

  private void init_css() {
    var provider = new Gtk.CssProvider();
    provider.load_from_data(default_style);

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
      init_css();
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
