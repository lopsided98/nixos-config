{ lib, fetchFromGitHub, buildPythonApplication, makeWrapper,
  requests, pyyaml,
  webScrapingSupport ? false, beautifulsoup4 ? null, 
  networkInterfaceSupport ? false, netifaces ? null }:

assert networkInterfaceSupport -> netifaces != null;
assert webScrapingSupport -> beautifulsoup4 != null;

buildPythonApplication rec {
  pname = "dnsupdate";
  version = "0.2.1";
  name = "${pname}-${version}";

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "dnsupdate";
    rev = "1c8ea0c8ce73872f165dc449f7c2c121b261af7b";
    sha256 = "1rkp3sp2lf60iah9rl7cyyw8h382wphkyik2skmr5shr4cl8gbqf";
  };

  # Requests and PyYaml are needed for tests
  nativeBuildInputs = [ makeWrapper requests pyyaml ];
  propogatedBuildInputs = with lib; [ requests pyyaml ]
    ++ optional webScrapingSupport beautifulsoup4
    ++ optional networkInterfaceSupport netifaces;
    
  postFixup = ''
      wrapProgram $out/bin/dnsupdate --set PYTHONPATH "$PYTHONPATH"
    '';

  meta = {
    description = "A modern and flexible dynamic DNS client";
    homepage = https://github.com/lopsided98/dnsupdate;
  };
}
