class Temp : Astal.Label {
  public Temp() {
    label = "WIP";
    
  }
}

class MenuContainer : Astal.EventBox {
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


  public MenuContainer(Gtk.Window window) {
    this.window = window;

    var stack = new Astal.Stack(); 
    Astal.widget_set_class_names(stack, {"MenuContainer"});

    stack.add_named(new Temp(), "temp");
    stack.set_visible_child_name("temp");

    this.add(stack);
    

    this.hover_lost.connect(this.on_hover_lost);
    this.window.show.connect(this.on_show);
  }
}

class Menu : Astal.Window {
  public Menu(Gdk.Monitor monitor) {
    Object(
      anchor: Astal.WindowAnchor.TOP
        | Astal.WindowAnchor.RIGHT,
        exclusivity: Astal.Exclusivity.NORMAL
    );

    Astal.widget_set_class_names(this, {"Menu"});

    gdkmonitor = monitor;

    this.add(new MenuContainer(this)); 
    this.show_all();
    this.hide();
  }  
}
