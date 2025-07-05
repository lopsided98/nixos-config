{ lib, fetchFromGitHub, buildPythonApplication, setuptools, requests, pyyaml
, networkInterfaceSupport ? true, netifaces ? null
, webScrapingSupport ? false, beautifulsoup4 ? null }:

assert networkInterfaceSupport -> netifaces != null;
assert webScrapingSupport -> beautifulsoup4 != null;

buildPythonApplication rec {
  pname = "dnsupdate";
  version = "0.4.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "dnsupdate";
    rev = version;
    sha256 = "sha256-5inQReGp++8uQkuxsF4uDkvSlGO7to6S0ZA86EGt5i4=";
  };

  nativeBuildInputs = [ setuptools ];

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
