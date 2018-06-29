{ buildPythonPackage, fetchurlBoot, flask, grpcio, grpcio-tools, numpy, pyyaml, pyalsaaudio }:

buildPythonPackage rec {
  pname = "audio-recorder";
  version = "0.1";

  # Use fetchurlBoot to
  src = fetchurlBoot {
    name = "audio_recorder-${version}.tar.gz";
    url = "https://hydra.benwolsieffer.com/job/audio-recorder/release/tarball/latest/download/1";
    sha256 = "9974ffbe83fbb0505d67e2c0b3cd113810863ddab7cc2d579029276f842c7e47";
  };

  nativeBuildInputs = [ grpcio-tools ];
  propagatedBuildInputs = [ flask grpcio numpy pyyaml pyalsaaudio ];
}
