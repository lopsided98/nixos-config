{ lib, stdenv, fetchFromGitHub, runtimeShell, jdk8, jre8, ant }:

stdenv.mkDerivation rec {
  pname = "openrocket";
  version = "unstable-2019-09-01";

  src = fetchFromGitHub {
    owner = "openrocket";
    repo = pname;
    rev = "0509f9e8ec66fd178dfaaddd4f59b95b40078057";
    sha256 = "0vz5ga2dcp9lj1rn5pa2wq4fw0jhdvfg1h44kf5vbafsbyv5n8xw";
  };

  nativeBuildInputs = [ jdk8 ant ];

  buildPhase = ''
    runHook preBuild
    ant
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"/{share/java,bin}
    mv swing/build/jar/OpenRocket.jar "$out/share/java"
    cat > "$out/bin/openrocket" <<EOF
    #!${runtimeShell}
    export JAVA_HOME='${jre8}'
    exec '${jre8}/bin/java' -jar '$out/share/java/OpenRocket.jar' "\$@"
    EOF
    chmod +x "$out/bin/openrocket"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Model rocket simulator";
    longDescription = ''
      OpenRocket is a free, fully featured model rocket simulator that allows
      you to design and simulate your rockets before actually building and
      flying them.
    '';
    homepage = "http://openrocket.info/";
    license = licenses.gpl3;
    maintainers = with maintainers; [ lopsided98 ];
  };
}
