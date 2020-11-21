{ lib, fetchFromGitHub, buildPythonApplication, requests, pyyaml
, networkInterfaceSupport ? true, netifaces ? null
, webScrapingSupport ? false, beautifulsoup4 ? null }:

assert networkInterfaceSupport -> netifaces != null;
assert webScrapingSupport -> beautifulsoup4 != null;

buildPythonApplication rec {
  pname = "dnsupdate";
  version = "0.4";

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "dnsupdate";
    rev = version;
    sha256 = "11sajb6gspjfcf1j640v7gp6y0nk8i9b60izxl0a8146j4i1is7a";
  };

  propagatedBuildInputs = [ requests pyyaml ]
    ++ lib.optional webScrapingSupport beautifulsoup4
    ++ lib.optional networkInterfaceSupport netifaces;

  meta = with lib; {
    description = "A modern and flexible dynamic DNS client";
    homepage = "https://github.com/lopsided98/dnsupdate";
    license = licenses.gpl3;
    maintainers = with maintainers; [ lopsided98 ];
    platforms = platforms.all;
  };
}
