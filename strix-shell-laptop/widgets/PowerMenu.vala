class ShutdownButton : Astal.Button {
  private void on_click() {
    try {
      string command = Settings.settings.get_object().get_object_member("power_commands").get_string_member("shutdown");
      string? standard_output;
      string? standard_error;
      int exit_status;

      Process.spawn_command_line_sync(
        command,
        out standard_output,
        out standard_error,
        out exit_status
      );

      if (standard_output != null) {
          print("Output: %s\n", standard_output);
      }
    } catch (Error e) {
      stderr.printf("Failed to shudown: %s\n", e.message); 
    } 
  } 

  public ShutdownButton() {
    Object(halign: Gtk.Align.CENTER, valign: Gtk.Align.CENTER);     
    Astal.widget_set_class_names(this, {"ShutdownButton"});  
    this.label = "";  

    this.clicked.connect(on_click);
  }
}

class RebootButton : Astal.Button {
  private void on_click() {
    try {
      string command = Settings.settings.get_object().get_object_member("power_commands").get_string_member("reboot");
      string? standard_output;
      string? standard_error;
      int exit_status;

      Process.spawn_command_line_sync(
        command,
        out standard_output,
        out standard_error,
        out exit_status
      );

      if (standard_output != null) {
          print("Output: %s\n", standard_output);
      }
    } catch (Error e) {
      stderr.printf("Failed to shudown: %s\n", e.message); 
    }
  }


  public RebootButton() {
    Object(halign: Gtk.Align.CENTER, valign: Gtk.Align.CENTER);     
    Astal.widget_set_class_names(this, {"RebootButton"});  
    this.label = "󰑥";    

    this.clicked.connect(on_click);
  }
}

class LogoutButton : Astal.Button {
  private void on_click() {
    try {
      string command = Settings.settings.get_object().get_object_member("power_commands").get_string_member("logout");
      string? standard_output;
      string? standard_error;
      int exit_status;

      Process.spawn_command_line_sync(
        command,
        out standard_output,
        out standard_error,
        out exit_status
      );

      if (standard_output != null) {
          print("Output: %s\n", standard_output);
      }
    } catch (Error e) {
      stderr.printf("Failed to shudown: %s\n", e.message); 
    }
  }

  public LogoutButton() {
    Object(halign: Gtk.Align.CENTER, valign: Gtk.Align.CENTER);     
    Astal.widget_set_class_names(this, {"LogoutButton"});  
    this.label = "󰍃";    

    this.clicked.connect(on_click);
  }
}

class HibernateButton : Astal.Button {
  private void on_click() {
    try {
      string command = Settings.settings.get_object().get_object_member("power_commands").get_string_member("hibernate");
      string? standard_output;
      string? standard_error;
      int exit_status;

      Process.spawn_command_line_sync(
        command,
        out standard_output,
        out standard_error,
        out exit_status
      );

      if (standard_output != null) {
          print("Output: %s\n", standard_output);
      }
    } catch (Error e) {
      stderr.printf("Failed to shudown: %s\n", e.message); 
    }
  }

  public HibernateButton() {
    Object(halign: Gtk.Align.CENTER, valign: Gtk.Align.CENTER);     
    Astal.widget_set_class_names(this, {"HibernateButton"});  
    this.label = "";    

    this.clicked.connect(on_click);
  }
}


class PowerMenuContainer : Astal.EventBox {
  private Gtk.Window window;

  private void on_hover_lost() {
    if (this.window.visible)
      this.window.hide();
  }

  private void on_show() {
    Timeout.add_once(3000, ()=>{
      this.window.hide();
    });
  }

  public PowerMenuContainer(Gtk.Window window) {
    this.window = window;

    var vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 3);
    Astal.widget_set_class_names(vbox, {"PowerMenuContainer"});
    vbox.add(new ShutdownButton());
    vbox.add(new RebootButton());
    vbox.add(new HibernateButton());
    vbox.add(new LogoutButton());

    this.add(vbox);  

    this.hover_lost.connect(this.on_hover_lost);
    this.window.show.connect(this.on_show);
  }
}

class PowerMenu : Astal.Window {
  public PowerMenu(Gdk.Monitor monitor) {
    Object(
      anchor: Astal.WindowAnchor.TOP
        | Astal.WindowAnchor.LEFT,
        exclusivity: Astal.Exclusivity.NORMAL
    );

    Astal.widget_set_class_names(this, {"PowerMenu"});

    gdkmonitor = monitor;

    this.add(new PowerMenuContainer(this)); 
    this.show_all();
    this.hide();
  }  
}
