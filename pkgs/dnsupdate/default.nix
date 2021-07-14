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
    rev = "f0168b423a1ee41e2ee04325657b7e08f21d30dc";
    sha256 = "sha256-K519Jc5wY4wAoiM9kbzPJNu7EAVbR7Cs6vlOtFQRpyc=";
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
