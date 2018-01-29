{ lib, fetchFromGitHub, buildPythonApplication, makeWrapper,
  requests, pyyaml,
  networkInterfaceSupport ? true, netifaces ? null,
  webScrapingSupport ? false, beautifulsoup4 ? null }:

assert networkInterfaceSupport -> netifaces != null;
assert webScrapingSupport -> beautifulsoup4 != null;

buildPythonApplication rec {
  pname = "dnsupdate";
  version = "0.3";
  name = "${pname}-${version}";

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "dnsupdate";
    rev = "1bb6cd0f7a84298087a3d90a0a9a78f41ae8a9aa";
    sha256 = "10ypzsk7c09lcs57p416gf491x2cwn49hhh0rxnz62pv7xymfqng";
  };

  # Requests and PyYaml are needed for tests
  nativeBuildInputs = [ makeWrapper ];
  buildInputs = with lib; [ requests pyyaml ]
    ++ optional webScrapingSupport beautifulsoup4
    ++ optional networkInterfaceSupport netifaces;
    
  postFixup = ''
      wrapProgram $out/bin/dnsupdate --set PYTHONPATH "$PYTHONPATH"
    '';

  meta = with lib; {
    description = "A modern and flexible dynamic DNS client";
    homepage = https://github.com/lopsided98/dnsupdate;
    license = licenses.gpl3;
  };
}
