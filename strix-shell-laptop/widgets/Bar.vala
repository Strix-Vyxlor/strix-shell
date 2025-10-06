class PowerButton : Astal.Button {
  private Gtk.Window powermenu;

  private void on_click() {
    if (this.powermenu.visible) {
      powermenu.hide();
    } else {
      powermenu.show ();
      }
  }

  private void on_hover() {
    if (!this.powermenu.visible) 
      powermenu.show();
  }

  public PowerButton(Gtk.Window powermenu) {
    Astal.widget_set_class_names (this, {"PowerButton"});
    this.label = "";
    
    this.powermenu = powermenu;

    this.clicked.connect (this.on_click);
    this.hover.connect(this.on_hover);
  }
}

class Clock : Astal.Label {
    string format;
    string tooltip;
    uint interval;

    bool sync() {
        this.label = new DateTime.now_local().format(format);
        return Source.CONTINUE;
    }

    public Clock(string format = "%I:%M:%S %P", string tooltip = "%a %d %b") {
        Astal.widget_set_class_names(this, {"Clock"});

        this.format = format;
        this.label = new DateTime.now_local().format(this.format);
        
        if (tooltip != "") {
          this.tooltip = tooltip; 
          this.tooltip_text = new DateTime.now_local().format(this.tooltip);
        }

        this.interval = Timeout.add(1000, sync, Priority.DEFAULT);
        this.destroy.connect(() => Source.remove(interval));
    }
}

class Tray : Gtk.Box {
  HashTable<string, Gtk.Widget> items = new HashTable<string, Gtk.Widget>(str_hash, str_equal);
  AstalTray.Tray tray = AstalTray.get_default();

  public Tray() {
    Astal.widget_set_class_names(this, { "TrayEmpty" });
    tray.item_added.connect(add_item);
    tray.item_removed.connect(remove_item);
    spacing = 0;
  }

  void add_item(string id) {
    if (items.contains(id))
      return;

    Astal.widget_set_class_names(this, { "Tray" });

    var item = tray.get_item(id);
    var btn = new Gtk.MenuButton() { use_popover = false, visible = true };
    var icon = new Astal.Icon() { visible = true };

    item.bind_property("tooltip-markup", btn, "tooltip-markup", BindingFlags.SYNC_CREATE);
    item.bind_property("gicon", icon, "gicon", BindingFlags.SYNC_CREATE);
    item.bind_property("menu-model", btn, "menu-model", BindingFlags.SYNC_CREATE);
    btn.insert_action_group("dbusmenu", item.action_group);
    item.notify["action-group"].connect(() => {
      btn.insert_action_group("dbusmenu", item.action_group);
    });

    btn.add(icon);
    add(btn);
    items.set(id, btn);
  }

  void remove_item(string id) {
    if (items.contains(id)) {
      items.get(id).hide();
      items.remove(id);
    }
    if (items.length == 0) {
      Astal.widget_set_class_names(this, {"TrayEmpty"});
    }
  }
}

class Workspaces : Gtk.Box {
  AstalHyprland.Hyprland hypr = AstalHyprland.get_default();

  public Workspaces() {
    Astal.widget_set_class_names(this, {"Workspaces"});
    hypr.notify["workspaces"].connect(sync);
    spacing = 0;
    sync();
  }

  void sync() {
    foreach (var child in get_children())
      child.destroy();
    
    var ws_list = hypr.workspaces;
    ws_list.sort((a,b) => {
      return a.id - b.id;
    }); 

    uint last_id = 0;

    foreach (var ws in ws_list) {
      // filter out special workspaces
      if (!(ws.id >= -99 && ws.id <= -2)) {
        if (ws.id != last_id+1) {
          for (uint i = last_id+1; (i<6)&&(i<ws.id); i++)
              add(inactive(i));
        }
        
        add(button(ws));
        last_id=ws.id;
      }
    }

    if (last_id<5) {
      for (uint i = last_id+1; i<6; i++)
        add(inactive(i));
    }
  }

  Gtk.Button inactive(uint id) {
    var btn = new Gtk.Button() {
      visible = true,
      label = "",
    };

    btn.clicked.connect(() => {
      hypr.dispatch("workspace", id.to_string());
    });

    Astal.widget_set_class_names(btn, {"Inactive"});
    return btn;

  }

  Gtk.Button button(AstalHyprland.Workspace ws) {
    var btn = new Gtk.Button() {
      visible = true,
      label = "",
    };

    hypr.notify["focused-workspace"].connect(() => {
      var focused = hypr.focused_workspace == ws;
      if (focused) {
          Astal.widget_set_class_names(btn, {"Focused"});
      } else {
          Astal.widget_set_class_names(btn, {});
      }
    });

    btn.clicked.connect(ws.focus);
    return btn;
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

class Inhibitor : Astal.Button {

  public Inhibitor() {
    Astal.widget_set_class_names(this, {"Inhibitor"});
    label = "󰌾";

    // Handle click
    this.clicked.connect(() => {
      SleepInhibitorController.instance.toggle();
    });

    // Update UI when state changes
    SleepInhibitorController.instance.notify["active"].connect(() => {
      update_state();
    });

    // Sync initial state
    update_state();
  }

  private void update_state() {
    if (SleepInhibitorController.instance.active) {
      Astal.widget_set_class_names(this, {"InhibitorActive"});
      label = "󱙱";
    } else {
      Astal.widget_set_class_names(this, {"Inhibitor"});
      label = "󰌾";
    }
  }
}

class Wifi : Astal.Label {
  public void on_change() {
    var wifi = AstalNetwork.get_default().wifi; 
    switch (wifi.internet) {
      case DISCONNECTED:
        this.label = "󱚵";
        break;
      case CONNECTING:
        this.label = "󱛇";
        break;
      case CONNECTED:
        this.label = "󰖩";
        break;
    }
  }

  public Wifi() {
    Astal.widget_set_class_names(this, {"Network","Wifi"});
    // var wifi = AstalNetwork.get_default().wifi;
    // wifi.notify.connect(this.on_change);
    on_change();
  }
}

class Wired : Astal.Label {
  public void on_change() {
    var wired = AstalNetwork.get_default().wired;  
    switch (wired.internet) {
      case DISCONNECTED:
        this.label = "󰌙";
        break;
      case CONNECTING:
        this.label = "󰌚";
        break;
      case CONNECTED:
        this.label = "󰌗";
        break;
    }
  }

  public Wired() {
    Astal.widget_set_class_names(this, {"Network","kWired"});
    on_change();
  }
}

class Network : Gtk.Bin {
  public void on_change() {
    var network = AstalNetwork.get_default();
    remove(get_child());
    switch (network.primary) {
      case UNKNOWN:
        var label = new Astal.Label() {label = ""};
        Astal.widget_set_class_names(label, {"Network", "Unknown"});
        add(label);
        break;
      case WIFI:
        add(new Wifi());  
        break;
      case WIRED:
        add(new Wired());
        break;
    }
    this.show_all();
  }

  public Network() {
    var network = AstalNetwork.get_default();  
    network.notify.connect(this.on_change);
    this.on_change();
  }
}

class Battery : Astal.Label {
  private AstalBattery.Device battery = AstalBattery.get_default();

  private void on_change() { 
    if (!this.battery.charging && this.battery.percentage > 0.1) {
      switch ( (int)Math.round((this.battery.percentage*300)/50) ) {
        case 0:
          Astal.widget_set_class_names(this, {"BatteryLow"});
          this.label = "󰂎";
          break;
        case 1:
          this.label = "󰁻";
          Astal.widget_set_class_names(this, {"BatteryLow"});
          break;
        case 2:
          this.label = "󰁼";
          break;
        case 3:
          this.label = "󰁾";
          break;
        case 4:
          this.label = "󰂀";
          break;
        case 5:
          this.label = "󰂂";
          break;
        case 6:
          this.label = "󰁹";
          break;
      }
    } else if (this.battery.percentage < 0.1) {
      this.label = "󰂃";
      Astal.widget_set_class_names(this, {"BatteryCritical"});
    }

    string time_hour;
    string time_minute;

    if (this.battery.charging) {
      this.label = "󰂄";
      Astal.widget_set_class_names(this, {"BatteryCharging"});
      time_hour = (this.battery.time_to_full/3600).to_string();
      time_minute = ((this.battery.time_to_full%3600)/60).to_string();
    } else {
      time_hour = (this.battery.time_to_empty/3600).to_string();
      time_minute = ((this.battery.time_to_empty%3600)/60).to_string();
    }
    
    this.tooltip_text = Math.round(this.battery.percentage*100).to_string() + "%, " + time_hour +" h "+ time_minute + " min";

  }

  public Battery() {
    //var icons =  {"󰂎","󰁻","󰁼","󰁾","󰂀","󰂂", "󰁹" };
    Astal.widget_set_class_names(this, {"Battery"});
    this.battery.notify.connect(this.on_change);
    on_change();    
  } 
}

class Spacer : Gtk.Box {
  public Spacer() {
    Object(hexpand: true, halign: Gtk.Align.FILL);
  }
}

class Left : Gtk.Box {
  public Left(Gtk.Window powermenu) {
    Object(hexpand: false, halign: Gtk.Align.START);
    Astal.widget_set_class_names (this, {"MainContainer"});
    add(new PowerButton(powermenu));
    add(new Clock());
    add(new Tray());
    add(new Spacer());
  }
}

class Center : Gtk.Box {
  public Center() {
    Astal.widget_set_class_names (this, {"MainContainer"});
    add(new Workspaces());
  }
}

class Right : Gtk.Box {
  public Right() {
    Object(hexpand: false, halign: Gtk.Align.END);
    Astal.widget_set_class_names (this, {"MainContainer"});
    add(new Spacer());
    add(new Inhibitor());
    add(new Network());
    add(new Battery());
  }
}

class Bar : Astal.Window {
  public Bar(Gdk.Monitor monitor,Gtk.Window powermenu) {
    Object(
      anchor: Astal.WindowAnchor.TOP
        | Astal.WindowAnchor.LEFT
        | Astal.WindowAnchor.RIGHT,
        exclusivity: Astal.Exclusivity.EXCLUSIVE
    );

    Astal.widget_set_class_names(this, {"Bar"});

    gdkmonitor = monitor;

    add(new Astal.CenterBox() {
      start_widget = new Left(powermenu),
      center_widget = new Center(),
      end_widget = new Right(),
    });
    show_all();
  }
}

