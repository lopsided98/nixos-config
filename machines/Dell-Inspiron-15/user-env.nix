{ pkgs
, lib
, stdenv
, fetchFromGitHub
, runCommandLocal
, runtimeShell
, symlinkJoin
, buildEnv
, nixgl
, glibcLocales
, qadwaitadecorations-qt6
, qt5
, nixVersions
, dropbox
, cura
, prusa-slicer
, cutecom
, zotero
, qgroundcontrol
, mission-planner
, mutt
, keepassxc
, nixfmt
}: let
  # Environment variables to run Qt5 applications natively on Wayland with
  # reasonable GNOME integration. Missing shadows around window borders and
  # some weird behaviors with modal dialogs.
  qt5Env = let
    pkgs = [ (qadwaitadecorations-qt6.override { useQt6 = false; }) ];
    makeQtPath = prefix: map (p: "${p}/${qt5.qtbase.${prefix}}") pkgs;
  in {
    QT_PLUGIN_PATH = makeQtPath "qtPluginPrefix";
    QML2_IMPORT_PATH = makeQtPath "qtQmlPrefix";
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DECORATION = "adwaita";
  };

  wrapNixGL = {
    pkg, # Package containing binary to wrap
    file ? "bin/${pkg.meta.mainProgram}", # Binary to wrap relative to package
    desktopFile ? null, # Desktop file to wrap relative to package
    env ? {}, # Environment variables to set. Lists are colon separated and 
              # appended to any currently set value.
    preScript ? "" # Script to run before executing binary
  }: let
    scriptText = ''
      #!${runtimeShell}
      ${preScript}
      ${lib.concatStrings (lib.mapAttrsToList (var: val: let
        valStr = if builtins.isList val then
          ''"''${${var}}''${${var}:+:}"${lib.concatStringsSep ":" (map lib.escapeShellArg val)}''
        else
          lib.escapeShellArg val;
      in ''
        export ${var}=${valStr}
      '') env)}
      exec -a "$0" '${nixgl.nixGLIntel}'/bin/nixGLIntel ${lib.escapeShellArg "${pkg}/${file}"} "$@"
    '';

    wrapper = runCommandLocal ("${lib.getName pkg}-wrapper") {
      inherit scriptText;
      passAsFile = [ "scriptText" ];
    } (''
      mkdir -p "$out"/'${builtins.dirOf file}'
      cp "$scriptTextPath" "$out"/'${file}'
      chmod +x "$out"/${lib.escapeShellArg file}
    '' + lib.optionalString (desktopFile != null) ''
      mkdir -p "$out"/${lib.escapeShellArg (builtins.dirOf desktopFile)}
      cp ${lib.escapeShellArg "${pkg}/${desktopFile}"} "$out"/${lib.escapeShellArg desktopFile}
      sed -i s:${lib.escapeShellArg pkg}:"$out":g "$out"/${lib.escapeShellArg desktopFile}
    '');
  in symlinkJoin {
    name = "${pkg.name}-nixGLIntel";
    paths = [ wrapper pkg ];
  };
in buildEnv {
  name = "Dell-Inspiron-15-user-env";
  paths = [
    nixVersions.latest
    nixgl.nixGLIntel
    dropbox
    (wrapNixGL {
      pkg = prusa-slicer;
      file = "bin/prusa-slicer";
      preScript = ''
        export LOCALE_ARCHIVE="${glibcLocales}/lib/locale/locale-archive";
      '';
    })
    (wrapNixGL { pkg = cutecom; })
    (wrapNixGL { pkg = zotero; })
    (wrapNixGL { pkg = qgroundcontrol; })
    (wrapNixGL { pkg = mission-planner; })
    mutt
    (wrapNixGL { pkg = keepassxc; })
    nixfmt
  ];
}
