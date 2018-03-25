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
    rev = "34da06243fefc76ce06ffe515781e7fbf781d182";
    sha256 = "08ggqndvzxb46dpz0f7r2ly96q0q68xzg1qda77xzw0yd6v1lsrg";
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
