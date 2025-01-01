{ pkgs
, lib
, stdenv
, fetchFromGitHub
, runCommandLocal
, runtimeShell
, symlinkJoin
, buildEnv
, glibcLocales
, qadwaitadecorations-qt6
, qt5
, nixVersions
, dropbox
, zoom-us
, cura
, prusa-slicer
, cutecom
, zotero
, qgroundcontrol
, mission-planner
, mutt
, keepassxc
}: let
  nixGL = ((import (fetchFromGitHub {
    owner = "nix-community";
    repo = "nixGL";
    rev = "310f8e49a149e4c9ea52f1adf70cdc768ec53f8a";
    hash = "sha256-lnzZQYG0+EXl/6NkGpyIz+FEOc/DSEG57AP1VsdeNrM=";
  }) { inherit pkgs; }).nixGLIntel);

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
      exec -a "\$0" '${nixGL}'/bin/nixGLIntel ${lib.escapeShellArg "${pkg}/${file}"} "\$@"
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

  zoom-us-wrapped = symlinkJoin {
    name = "${lib.getName zoom-us}-nixGLIntel";
    paths = [ zoom-us ];
    postBuild = ''
      rm "$out/bin/zoom" "$out/opt/zoom/ZoomLauncher"

      # ZoomLauncher is mostly useless and annoying; it overwrites
      # LD_LIBRARY_PATH with some Zoom directories and then executes
      # opt/zoom/zoom always from the package directory, making it impossible
      # to create a wrapper. Replace it instead with a simple shell script that
      # does the nixGL wrapping as well.
      cat << EOF > "$out/opt/zoom/ZoomLauncher"
      #!${runtimeShell}
      export LD_LIBRARY_PATH=${lib.escapeShellArg zoom-us}/opt/zoom/Qt/lib:${lib.escapeShellArg zoom-us}/opt/zoom/cef:${lib.escapeShellArg zoom-us}/opt/zoom"\''${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}"
      exec -a "\$0" '${nixGL}'/bin/nixGLIntel '${zoom-us}'/opt/zoom/zoom "\$@"
      EOF

      # Execute ZoomLauncher from the wrapped package
      sed s:'${zoom-us}':"$out":g '${zoom-us}'/bin/zoom > "$out/bin/zoom"

      chmod +x "$out/bin/zoom" "$out/opt/zoom/ZoomLauncher"
    '';
  };
in buildEnv {
  name = "Dell-Inspiron-15-user-env";
  paths = [
    nixVersions.latest
    nixGL
    dropbox
    zoom-us-wrapped
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
  ];
}
