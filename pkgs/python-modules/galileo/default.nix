{ lib, fetchFromBitbucket, buildPythonPackage, requests, pyusb, pydbus }:

buildPythonPackage rec {
  pname = "galileo";
  version = "unstable-2018-10-10";

  src = fetchFromBitbucket {
    owner = "benallard";
    repo = pname;
    rev = "83d19bece241a5c02e10eb657e32972d66343da7";
    sha256 = "1p23kfxld2m05cpc3iv6jyfx562h1gic14c6m6n0gbkd7vnmmji8";
  };

  propagatedBuildInputs = [ requests pyusb pydbus ];

  # Tests are broken
  doCheck = false;

  postInstall = ''
    mkdir -p "$out"/share/man/man{1,5}
    mv doc/galileo.1 "$out/share/man/man1"
    mv doc/galileorc.5 "$out/share/man/man5"
  '';

  meta = with lib; {
    description = "Python utility to synchronise Fitbit devices with the fitbit server.";
    homepage = "https://bitbucket.org/benallard/galileo";
    license = licenses.gpl3;
    maintainers = with maintainers; [ lopsided98 ];
  };
}
