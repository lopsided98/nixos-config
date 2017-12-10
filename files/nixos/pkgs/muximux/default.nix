{ lib, stdenv, fetchFromGitHub, dataDir ? "/var/lib/muximux" }:

let
commit = "66b11488206b44364b6ed8bb438462cbbb0835c5";

in stdenv.mkDerivation {
  name = "muximux-${lib.substring 0 7 commit}";

  src = fetchFromGitHub {
    owner = "mescon";
    repo = "Muximux";
    rev = commit;
    sha256 = "039gil0glb3kjywf3ac3r0z6v75lgy8hf7bqzpnn0zq4pwsf060q";
  };

  installPhase = ''
    cp -ar . "${out}"

    ln -sf "${dataDir}/cache" "${out}/cache" 
  
    find "${out}" -type f -print0 | xargs -0 sed -i -e 's#settings\.ini\.php#${dataDir}/settings.ini.php#g' \
                                                    -e 's#muximux\.log#${dataDir}/muximux.log#g' \
                                                    -e 's#secret\.txt#${dataDir}/secret.txt#g' \
                                                    -e 's#js/iconset-muximux\.js#${dataDir}/iconset-muximux.js#g'
  '';


  meta = {
    description = "A lightweight way to manage your HTPC";
    homepage = https://github.com/mescon/Muximux;
    license = [ lib.licenses.gpl2 ];
  };
}
