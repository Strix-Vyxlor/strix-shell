class ShutdownButton : Astal.Button {
  private void on_click() {
    print("shutdown\n");
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
    print("reboot\n");
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
    print("logout\n");
  }

  public LogoutButton() {
    Object(halign: Gtk.Align.CENTER, valign: Gtk.Align.CENTER);     
    Astal.widget_set_class_names(this, {"LogoutButton"});  
    this.label = "󰍃";    

    this.clicked.connect(on_click);
  }
}


class PowerMenuContainer : Astal.EventBox {
  private Gtk.Window window;

  private void on_hover_lost() {
    if (this.window.visible)
      this.window.hide();
  }

  public PowerMenuContainer(Gtk.Window window) {
    this.window = window;

    var vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 3);
    Astal.widget_set_class_names(vbox, {"PowerMenuContainer"});
    vbox.add(new ShutdownButton());
    vbox.add(new RebootButton());
    vbox.add(new LogoutButton());

    this.add(vbox);  

    this.hover_lost.connect(this.on_hover_lost);
  }
}

class PowerMenu : Astal.Window {
  public PowerMenu() {
    Object(
      anchor: Astal.WindowAnchor.TOP
        | Astal.WindowAnchor.LEFT,
        exclusivity: Astal.Exclusivity.NORMAL
    );

    Astal.widget_set_class_names(this, {"PowerMenu"});

   this.add(new PowerMenuContainer(this)); 
   this.show_all();
   this.hide();
  }
  
}
