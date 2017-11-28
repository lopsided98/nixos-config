#!/bin/bash
source "${stdenv}/setup"

installPhase() {
  cp -ar . "${out}"
  
  ln -sf "/var/lib/muximux/iconset-muximux.js" "${out}/js/iconset-muximux.js"
  ln -sf "/var/lib/muximux/cache" "${out}/cache" 
  
  find "${out}" -type f -print0 | xargs -0 sed -i -e 's#settings\.ini\.php#/var/lib/muximux/settings.ini.php#g' \
                                                  -e 's#muximux\.log#/var/lib/muximux/muximux.log#g' \
                                                  -e 's#secret\.txt#/var/lib/muximux/secret.txt#g' \
                                                  -e 's#js/iconset-muximux\.js#/var/lib/muximux/iconset-muximux.js#g' 

}

genericBuild
