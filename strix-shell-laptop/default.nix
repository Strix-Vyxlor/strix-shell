astal: {
  stdenv,
  meson,
  ninja,
  pkg-config,
  vala,
  dart-sass,
  gtk3,
  gobject-introspection,
  ...
}:
stdenv.mkDerivation {
  name = "strix-shell-laptop";
  src = ./.;

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    vala
    gobject-introspection
    dart-sass
  ];

  buildInputs = with astal; [
    astal3
    tray
    hyprland
    battery
    network
  ];
}
