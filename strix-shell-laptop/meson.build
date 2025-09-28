project(
  'strix-shell-laptop',
  'vala',
  meson_version : '>= 1.0.0',
  version : '0.1',
)

dependencies = [
  dependency('glib-2.0'),
  dependency('gobject-2.0'),
  dependency('libnm'),
  dependency('gtk+-3.0'),
  dependency('astal-io-0.1'),
  dependency('astal-3.0'),
  dependency('astal-tray-0.1'),
  dependency('astal-hyprland-0.1'),
  dependency('astal-battery-0.1'),
  dependency('astal-network-0.1'),
]

main = configure_file(
  input: 'app.in.vala',
  output: 'app.vala',
  configuration: {
    'STYLE': run_command(
      find_program('sass'),
      meson.project_source_root() / 'style.scss',
      ).stdout(),
    },
  )

sources = files(
  'widgets/Bar.vala',
  'widgets/PowerMenu.vala'
  )

exe = executable(
  'strix-shell-laptop',
  [sources, main],
  dependencies : dependencies,
  install : true
)

test('basic', exe)
