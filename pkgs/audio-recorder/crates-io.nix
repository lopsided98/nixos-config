{ lib, buildRustCrate, buildRustCrateHelpers }:
with buildRustCrateHelpers;
let inherit (lib.lists) fold;
    inherit (lib.attrsets) recursiveUpdate;
in
rec {

# aho-corasick-0.6.9

  crates.aho_corasick."0.6.9" = deps: { features?(features_.aho_corasick."0.6.9" deps {}) }: buildRustCrate {
    crateName = "aho-corasick";
    version = "0.6.9";
    authors = [ "Andrew Gallant <jamslam@gmail.com>" ];
    sha256 = "1lj20py6bvw3y7m9n2nqh0mkshfl1kjfp72lfika9gpkrp2r204l";
    libName = "aho_corasick";
    crateBin =
      [{  name = "aho-corasick-dot";  path = "src/main.rs"; }];
    dependencies = mapFeatures features ([
      (crates."memchr"."${deps."aho_corasick"."0.6.9"."memchr"}" deps)
    ]);
  };
  features_.aho_corasick."0.6.9" = deps: f: updateFeatures f (rec {
    aho_corasick."0.6.9".default = (f.aho_corasick."0.6.9".default or true);
    memchr."${deps.aho_corasick."0.6.9".memchr}".default = true;
  }) [
    (features_.memchr."${deps."aho_corasick"."0.6.9"."memchr"}" deps)
  ];


# end
# arc-swap-0.3.6

  crates.arc_swap."0.3.6" = deps: { features?(features_.arc_swap."0.3.6" deps {}) }: buildRustCrate {
    crateName = "arc-swap";
    version = "0.3.6";
    authors = [ "Michal 'vorner' Vaner <vorner@vorner.cz>" ];
    sha256 = "0va1hizl72v2q7q02z8f2vrqdq7blyarif50bk0b4lvp32ifxym8";
  };
  features_.arc_swap."0.3.6" = deps: f: updateFeatures f (rec {
    arc_swap."0.3.6".default = (f.arc_swap."0.3.6".default or true);
  }) [];


# end
# arrayvec-0.4.9

  crates.arrayvec."0.4.9" = deps: { features?(features_.arrayvec."0.4.9" deps {}) }: buildRustCrate {
    crateName = "arrayvec";
    version = "0.4.9";
    authors = [ "bluss" ];
    sha256 = "0hyafv26hj0wp96kf3cdq3hjv78ib9cham8j564n65j6gavjcw0s";
    dependencies = mapFeatures features ([
      (crates."nodrop"."${deps."arrayvec"."0.4.9"."nodrop"}" deps)
    ]);
    features = mkFeatures (features."arrayvec"."0.4.9" or {});
  };
  features_.arrayvec."0.4.9" = deps: f: updateFeatures f (rec {
    arrayvec = fold recursiveUpdate {} [
      { "0.4.9".default = (f.arrayvec."0.4.9".default or true); }
      { "0.4.9".serde =
        (f.arrayvec."0.4.9".serde or false) ||
        (f.arrayvec."0.4.9".serde-1 or false) ||
        (arrayvec."0.4.9"."serde-1" or false); }
      { "0.4.9".std =
        (f.arrayvec."0.4.9".std or false) ||
        (f.arrayvec."0.4.9".default or false) ||
        (arrayvec."0.4.9"."default" or false); }
    ];
    nodrop."${deps.arrayvec."0.4.9".nodrop}".default = (f.nodrop."${deps.arrayvec."0.4.9".nodrop}".default or false);
  }) [
    (features_.nodrop."${deps."arrayvec"."0.4.9"."nodrop"}" deps)
  ];


# end
# atty-0.2.11

  crates.atty."0.2.11" = deps: { features?(features_.atty."0.2.11" deps {}) }: buildRustCrate {
    crateName = "atty";
    version = "0.2.11";
    authors = [ "softprops <d.tangren@gmail.com>" ];
    sha256 = "0by1bj2km9jxi4i4g76zzi76fc2rcm9934jpnyrqd95zw344pb20";
    dependencies = (if kernel == "redox" then mapFeatures features ([
      (crates."termion"."${deps."atty"."0.2.11"."termion"}" deps)
    ]) else [])
      ++ (if (kernel == "linux" || kernel == "darwin") then mapFeatures features ([
      (crates."libc"."${deps."atty"."0.2.11"."libc"}" deps)
    ]) else [])
      ++ (if kernel == "windows" then mapFeatures features ([
      (crates."winapi"."${deps."atty"."0.2.11"."winapi"}" deps)
    ]) else []);
  };
  features_.atty."0.2.11" = deps: f: updateFeatures f (rec {
    atty."0.2.11".default = (f.atty."0.2.11".default or true);
    libc."${deps.atty."0.2.11".libc}".default = (f.libc."${deps.atty."0.2.11".libc}".default or false);
    termion."${deps.atty."0.2.11".termion}".default = true;
    winapi = fold recursiveUpdate {} [
      { "${deps.atty."0.2.11".winapi}"."consoleapi" = true; }
      { "${deps.atty."0.2.11".winapi}"."minwinbase" = true; }
      { "${deps.atty."0.2.11".winapi}"."minwindef" = true; }
      { "${deps.atty."0.2.11".winapi}"."processenv" = true; }
      { "${deps.atty."0.2.11".winapi}"."winbase" = true; }
      { "${deps.atty."0.2.11".winapi}".default = true; }
    ];
  }) [
    (features_.termion."${deps."atty"."0.2.11"."termion"}" deps)
    (features_.libc."${deps."atty"."0.2.11"."libc"}" deps)
    (features_.winapi."${deps."atty"."0.2.11"."winapi"}" deps)
  ];


# end
# autocfg-0.1.1

  crates.autocfg."0.1.1" = deps: { features?(features_.autocfg."0.1.1" deps {}) }: buildRustCrate {
    crateName = "autocfg";
    version = "0.1.1";
    authors = [ "Josh Stone <cuviper@gmail.com>" ];
    sha256 = "0pzhbmwg46y04n89vn8yi0z1q8m3yh9gmfi8b9wn72zwk60f1rx2";
  };
  features_.autocfg."0.1.1" = deps: f: updateFeatures f (rec {
    autocfg."0.1.1".default = (f.autocfg."0.1.1".default or true);
  }) [];


# end
# backtrace-0.3.13

  crates.backtrace."0.3.13" = deps: { features?(features_.backtrace."0.3.13" deps {}) }: buildRustCrate {
    crateName = "backtrace";
    version = "0.3.13";
    authors = [ "Alex Crichton <alex@alexcrichton.com>" "The Rust Project Developers" ];
    sha256 = "1xx0vjdih9zqj6vp8l69n0f213wmif5471prgpkp24jbzxndvb1v";
    dependencies = mapFeatures features ([
      (crates."cfg_if"."${deps."backtrace"."0.3.13"."cfg_if"}" deps)
      (crates."rustc_demangle"."${deps."backtrace"."0.3.13"."rustc_demangle"}" deps)
    ])
      ++ (if (kernel == "linux" || kernel == "darwin") && !(kernel == "fuchsia") && !(kernel == "emscripten") && !(kernel == "darwin") && !(kernel == "ios") then mapFeatures features ([
    ]
      ++ (if features.backtrace."0.3.13".backtrace-sys or false then [ (crates.backtrace_sys."${deps."backtrace"."0.3.13".backtrace_sys}" deps) ] else [])) else [])
      ++ (if (kernel == "linux" || kernel == "darwin") then mapFeatures features ([
      (crates."libc"."${deps."backtrace"."0.3.13"."libc"}" deps)
    ]) else [])
      ++ (if kernel == "windows" then mapFeatures features ([
      (crates."winapi"."${deps."backtrace"."0.3.13"."winapi"}" deps)
    ]) else []);

    buildDependencies = mapFeatures features ([
      (crates."autocfg"."${deps."backtrace"."0.3.13"."autocfg"}" deps)
    ]);
    features = mkFeatures (features."backtrace"."0.3.13" or {});
  };
  features_.backtrace."0.3.13" = deps: f: updateFeatures f (rec {
    autocfg."${deps.backtrace."0.3.13".autocfg}".default = true;
    backtrace = fold recursiveUpdate {} [
      { "0.3.13".addr2line =
        (f.backtrace."0.3.13".addr2line or false) ||
        (f.backtrace."0.3.13".gimli-symbolize or false) ||
        (backtrace."0.3.13"."gimli-symbolize" or false); }
      { "0.3.13".backtrace-sys =
        (f.backtrace."0.3.13".backtrace-sys or false) ||
        (f.backtrace."0.3.13".libbacktrace or false) ||
        (backtrace."0.3.13"."libbacktrace" or false); }
      { "0.3.13".coresymbolication =
        (f.backtrace."0.3.13".coresymbolication or false) ||
        (f.backtrace."0.3.13".default or false) ||
        (backtrace."0.3.13"."default" or false); }
      { "0.3.13".dbghelp =
        (f.backtrace."0.3.13".dbghelp or false) ||
        (f.backtrace."0.3.13".default or false) ||
        (backtrace."0.3.13"."default" or false); }
      { "0.3.13".default = (f.backtrace."0.3.13".default or true); }
      { "0.3.13".dladdr =
        (f.backtrace."0.3.13".dladdr or false) ||
        (f.backtrace."0.3.13".default or false) ||
        (backtrace."0.3.13"."default" or false); }
      { "0.3.13".findshlibs =
        (f.backtrace."0.3.13".findshlibs or false) ||
        (f.backtrace."0.3.13".gimli-symbolize or false) ||
        (backtrace."0.3.13"."gimli-symbolize" or false); }
      { "0.3.13".gimli =
        (f.backtrace."0.3.13".gimli or false) ||
        (f.backtrace."0.3.13".gimli-symbolize or false) ||
        (backtrace."0.3.13"."gimli-symbolize" or false); }
      { "0.3.13".libbacktrace =
        (f.backtrace."0.3.13".libbacktrace or false) ||
        (f.backtrace."0.3.13".default or false) ||
        (backtrace."0.3.13"."default" or false); }
      { "0.3.13".libunwind =
        (f.backtrace."0.3.13".libunwind or false) ||
        (f.backtrace."0.3.13".default or false) ||
        (backtrace."0.3.13"."default" or false); }
      { "0.3.13".memmap =
        (f.backtrace."0.3.13".memmap or false) ||
        (f.backtrace."0.3.13".gimli-symbolize or false) ||
        (backtrace."0.3.13"."gimli-symbolize" or false); }
      { "0.3.13".object =
        (f.backtrace."0.3.13".object or false) ||
        (f.backtrace."0.3.13".gimli-symbolize or false) ||
        (backtrace."0.3.13"."gimli-symbolize" or false); }
      { "0.3.13".rustc-serialize =
        (f.backtrace."0.3.13".rustc-serialize or false) ||
        (f.backtrace."0.3.13".serialize-rustc or false) ||
        (backtrace."0.3.13"."serialize-rustc" or false); }
      { "0.3.13".serde =
        (f.backtrace."0.3.13".serde or false) ||
        (f.backtrace."0.3.13".serialize-serde or false) ||
        (backtrace."0.3.13"."serialize-serde" or false); }
      { "0.3.13".serde_derive =
        (f.backtrace."0.3.13".serde_derive or false) ||
        (f.backtrace."0.3.13".serialize-serde or false) ||
        (backtrace."0.3.13"."serialize-serde" or false); }
      { "0.3.13".std =
        (f.backtrace."0.3.13".std or false) ||
        (f.backtrace."0.3.13".default or false) ||
        (backtrace."0.3.13"."default" or false) ||
        (f.backtrace."0.3.13".libbacktrace or false) ||
        (backtrace."0.3.13"."libbacktrace" or false); }
    ];
    backtrace_sys."${deps.backtrace."0.3.13".backtrace_sys}".default = true;
    cfg_if."${deps.backtrace."0.3.13".cfg_if}".default = true;
    libc."${deps.backtrace."0.3.13".libc}".default = (f.libc."${deps.backtrace."0.3.13".libc}".default or false);
    rustc_demangle."${deps.backtrace."0.3.13".rustc_demangle}".default = true;
    winapi = fold recursiveUpdate {} [
      { "${deps.backtrace."0.3.13".winapi}"."dbghelp" = true; }
      { "${deps.backtrace."0.3.13".winapi}"."minwindef" = true; }
      { "${deps.backtrace."0.3.13".winapi}"."processthreadsapi" = true; }
      { "${deps.backtrace."0.3.13".winapi}"."winnt" = true; }
      { "${deps.backtrace."0.3.13".winapi}".default = true; }
    ];
  }) [
    (features_.cfg_if."${deps."backtrace"."0.3.13"."cfg_if"}" deps)
    (features_.rustc_demangle."${deps."backtrace"."0.3.13"."rustc_demangle"}" deps)
    (features_.autocfg."${deps."backtrace"."0.3.13"."autocfg"}" deps)
    (features_.backtrace_sys."${deps."backtrace"."0.3.13"."backtrace_sys"}" deps)
    (features_.libc."${deps."backtrace"."0.3.13"."libc"}" deps)
    (features_.winapi."${deps."backtrace"."0.3.13"."winapi"}" deps)
  ];


# end
# backtrace-sys-0.1.26

  crates.backtrace_sys."0.1.26" = deps: { features?(features_.backtrace_sys."0.1.26" deps {}) }: buildRustCrate {
    crateName = "backtrace-sys";
    version = "0.1.26";
    authors = [ "Alex Crichton <alex@alexcrichton.com>" ];
    sha256 = "0imza92b0n6rjgbh7xqpiv6268vimxghrijyjlz144dspm4l8drr";
    build = "build.rs";
    dependencies = mapFeatures features ([
      (crates."libc"."${deps."backtrace_sys"."0.1.26"."libc"}" deps)
    ]);

    buildDependencies = mapFeatures features ([
      (crates."cc"."${deps."backtrace_sys"."0.1.26"."cc"}" deps)
    ]);
  };
  features_.backtrace_sys."0.1.26" = deps: f: updateFeatures f (rec {
    backtrace_sys."0.1.26".default = (f.backtrace_sys."0.1.26".default or true);
    cc."${deps.backtrace_sys."0.1.26".cc}".default = true;
    libc."${deps.backtrace_sys."0.1.26".libc}".default = (f.libc."${deps.backtrace_sys."0.1.26".libc}".default or false);
  }) [
    (features_.libc."${deps."backtrace_sys"."0.1.26"."libc"}" deps)
    (features_.cc."${deps."backtrace_sys"."0.1.26"."cc"}" deps)
  ];


# end
# bitflags-0.9.1

  crates.bitflags."0.9.1" = deps: { features?(features_.bitflags."0.9.1" deps {}) }: buildRustCrate {
    crateName = "bitflags";
    version = "0.9.1";
    authors = [ "The Rust Project Developers" ];
    sha256 = "18h073l5jd88rx4qdr95fjddr9rk79pb1aqnshzdnw16cfmb9rws";
    features = mkFeatures (features."bitflags"."0.9.1" or {});
  };
  features_.bitflags."0.9.1" = deps: f: updateFeatures f (rec {
    bitflags = fold recursiveUpdate {} [
      { "0.9.1".default = (f.bitflags."0.9.1".default or true); }
      { "0.9.1".example_generated =
        (f.bitflags."0.9.1".example_generated or false) ||
        (f.bitflags."0.9.1".default or false) ||
        (bitflags."0.9.1"."default" or false); }
    ];
  }) [];


# end
# bitflags-1.0.4

  crates.bitflags."1.0.4" = deps: { features?(features_.bitflags."1.0.4" deps {}) }: buildRustCrate {
    crateName = "bitflags";
    version = "1.0.4";
    authors = [ "The Rust Project Developers" ];
    sha256 = "1g1wmz2001qmfrd37dnd5qiss5njrw26aywmg6yhkmkbyrhjxb08";
    features = mkFeatures (features."bitflags"."1.0.4" or {});
  };
  features_.bitflags."1.0.4" = deps: f: updateFeatures f (rec {
    bitflags."1.0.4".default = (f.bitflags."1.0.4".default or true);
  }) [];


# end
# byteorder-1.2.7

  crates.byteorder."1.2.7" = deps: { features?(features_.byteorder."1.2.7" deps {}) }: buildRustCrate {
    crateName = "byteorder";
    version = "1.2.7";
    authors = [ "Andrew Gallant <jamslam@gmail.com>" ];
    sha256 = "0wsl8in6jk2v1n8s8jz0pjd99mjr2isbf981497pgavwg6i11q5h";
    features = mkFeatures (features."byteorder"."1.2.7" or {});
  };
  features_.byteorder."1.2.7" = deps: f: updateFeatures f (rec {
    byteorder = fold recursiveUpdate {} [
      { "1.2.7".default = (f.byteorder."1.2.7".default or true); }
      { "1.2.7".std =
        (f.byteorder."1.2.7".std or false) ||
        (f.byteorder."1.2.7".default or false) ||
        (byteorder."1.2.7"."default" or false); }
    ];
  }) [];


# end
# bytes-0.4.11

  crates.bytes."0.4.11" = deps: { features?(features_.bytes."0.4.11" deps {}) }: buildRustCrate {
    crateName = "bytes";
    version = "0.4.11";
    authors = [ "Carl Lerche <me@carllerche.com>" ];
    sha256 = "1lk8bnxcd8shiizarf0n6ljmj1542n90jw6lz6i270gxl7rzplmh";
    dependencies = mapFeatures features ([
      (crates."byteorder"."${deps."bytes"."0.4.11"."byteorder"}" deps)
      (crates."iovec"."${deps."bytes"."0.4.11"."iovec"}" deps)
    ]);
    features = mkFeatures (features."bytes"."0.4.11" or {});
  };
  features_.bytes."0.4.11" = deps: f: updateFeatures f (rec {
    byteorder = fold recursiveUpdate {} [
      { "${deps.bytes."0.4.11".byteorder}"."i128" =
        (f.byteorder."${deps.bytes."0.4.11".byteorder}"."i128" or false) ||
        (bytes."0.4.11"."i128" or false) ||
        (f."bytes"."0.4.11"."i128" or false); }
      { "${deps.bytes."0.4.11".byteorder}".default = true; }
    ];
    bytes."0.4.11".default = (f.bytes."0.4.11".default or true);
    iovec."${deps.bytes."0.4.11".iovec}".default = true;
  }) [
    (features_.byteorder."${deps."bytes"."0.4.11"."byteorder"}" deps)
    (features_.iovec."${deps."bytes"."0.4.11"."iovec"}" deps)
  ];


# end
# cc-1.0.26

  crates.cc."1.0.26" = deps: { features?(features_.cc."1.0.26" deps {}) }: buildRustCrate {
    crateName = "cc";
    version = "1.0.26";
    authors = [ "Alex Crichton <alex@alexcrichton.com>" ];
    sha256 = "0q6pamwpgk9hv65vhv8s9dp5d5wb298rcg2kyzpz3y9kzw0kzhj0";
    dependencies = mapFeatures features ([
]);
    features = mkFeatures (features."cc"."1.0.26" or {});
  };
  features_.cc."1.0.26" = deps: f: updateFeatures f (rec {
    cc = fold recursiveUpdate {} [
      { "1.0.26".default = (f.cc."1.0.26".default or true); }
      { "1.0.26".rayon =
        (f.cc."1.0.26".rayon or false) ||
        (f.cc."1.0.26".parallel or false) ||
        (cc."1.0.26"."parallel" or false); }
    ];
  }) [];


# end
# cfg-if-0.1.6

  crates.cfg_if."0.1.6" = deps: { features?(features_.cfg_if."0.1.6" deps {}) }: buildRustCrate {
    crateName = "cfg-if";
    version = "0.1.6";
    authors = [ "Alex Crichton <alex@alexcrichton.com>" ];
    sha256 = "11qrix06wagkplyk908i3423ps9m9np6c4vbcq81s9fyl244xv3n";
  };
  features_.cfg_if."0.1.6" = deps: f: updateFeatures f (rec {
    cfg_if."0.1.6".default = (f.cfg_if."0.1.6".default or true);
  }) [];


# end
# cloudabi-0.0.3

  crates.cloudabi."0.0.3" = deps: { features?(features_.cloudabi."0.0.3" deps {}) }: buildRustCrate {
    crateName = "cloudabi";
    version = "0.0.3";
    authors = [ "Nuxi (https://nuxi.nl/) and contributors" ];
    sha256 = "1z9lby5sr6vslfd14d6igk03s7awf91mxpsfmsp3prxbxlk0x7h5";
    libPath = "cloudabi.rs";
    dependencies = mapFeatures features ([
    ]
      ++ (if features.cloudabi."0.0.3".bitflags or false then [ (crates.bitflags."${deps."cloudabi"."0.0.3".bitflags}" deps) ] else []));
    features = mkFeatures (features."cloudabi"."0.0.3" or {});
  };
  features_.cloudabi."0.0.3" = deps: f: updateFeatures f (rec {
    bitflags."${deps.cloudabi."0.0.3".bitflags}".default = true;
    cloudabi = fold recursiveUpdate {} [
      { "0.0.3".bitflags =
        (f.cloudabi."0.0.3".bitflags or false) ||
        (f.cloudabi."0.0.3".default or false) ||
        (cloudabi."0.0.3"."default" or false); }
      { "0.0.3".default = (f.cloudabi."0.0.3".default or true); }
    ];
  }) [
    (features_.bitflags."${deps."cloudabi"."0.0.3"."bitflags"}" deps)
  ];


# end
# cmake-0.1.35

  crates.cmake."0.1.35" = deps: { features?(features_.cmake."0.1.35" deps {}) }: buildRustCrate {
    crateName = "cmake";
    version = "0.1.35";
    authors = [ "Alex Crichton <alex@alexcrichton.com>" ];
    sha256 = "0zbp2k5zjavyxx5zdx1viify9b76zqbn16l2wdw4b6hng6245bnc";
    dependencies = mapFeatures features ([
      (crates."cc"."${deps."cmake"."0.1.35"."cc"}" deps)
    ]);
  };
  features_.cmake."0.1.35" = deps: f: updateFeatures f (rec {
    cc."${deps.cmake."0.1.35".cc}".default = true;
    cmake."0.1.35".default = (f.cmake."0.1.35".default or true);
  }) [
    (features_.cc."${deps."cmake"."0.1.35"."cc"}" deps)
  ];


# end
# crossbeam-deque-0.6.3

  crates.crossbeam_deque."0.6.3" = deps: { features?(features_.crossbeam_deque."0.6.3" deps {}) }: buildRustCrate {
    crateName = "crossbeam-deque";
    version = "0.6.3";
    authors = [ "The Crossbeam Project Developers" ];
    sha256 = "07dahkh6rc09nzg7054rnmxhni263pi9arcyjyy822kg59c0lfz8";
    dependencies = mapFeatures features ([
      (crates."crossbeam_epoch"."${deps."crossbeam_deque"."0.6.3"."crossbeam_epoch"}" deps)
      (crates."crossbeam_utils"."${deps."crossbeam_deque"."0.6.3"."crossbeam_utils"}" deps)
    ]);
  };
  features_.crossbeam_deque."0.6.3" = deps: f: updateFeatures f (rec {
    crossbeam_deque."0.6.3".default = (f.crossbeam_deque."0.6.3".default or true);
    crossbeam_epoch."${deps.crossbeam_deque."0.6.3".crossbeam_epoch}".default = true;
    crossbeam_utils."${deps.crossbeam_deque."0.6.3".crossbeam_utils}".default = true;
  }) [
    (features_.crossbeam_epoch."${deps."crossbeam_deque"."0.6.3"."crossbeam_epoch"}" deps)
    (features_.crossbeam_utils."${deps."crossbeam_deque"."0.6.3"."crossbeam_utils"}" deps)
  ];


# end
# crossbeam-epoch-0.7.0

  crates.crossbeam_epoch."0.7.0" = deps: { features?(features_.crossbeam_epoch."0.7.0" deps {}) }: buildRustCrate {
    crateName = "crossbeam-epoch";
    version = "0.7.0";
    authors = [ "The Crossbeam Project Developers" ];
    sha256 = "1zs7yvgjrs1xv4fd27wdr23l4dcb23n45krqcnbfzd7yrw0mrwiz";
    dependencies = mapFeatures features ([
      (crates."arrayvec"."${deps."crossbeam_epoch"."0.7.0"."arrayvec"}" deps)
      (crates."cfg_if"."${deps."crossbeam_epoch"."0.7.0"."cfg_if"}" deps)
      (crates."crossbeam_utils"."${deps."crossbeam_epoch"."0.7.0"."crossbeam_utils"}" deps)
      (crates."memoffset"."${deps."crossbeam_epoch"."0.7.0"."memoffset"}" deps)
      (crates."scopeguard"."${deps."crossbeam_epoch"."0.7.0"."scopeguard"}" deps)
    ]
      ++ (if features.crossbeam_epoch."0.7.0".lazy_static or false then [ (crates.lazy_static."${deps."crossbeam_epoch"."0.7.0".lazy_static}" deps) ] else []));
    features = mkFeatures (features."crossbeam_epoch"."0.7.0" or {});
  };
  features_.crossbeam_epoch."0.7.0" = deps: f: updateFeatures f (rec {
    arrayvec = fold recursiveUpdate {} [
      { "${deps.crossbeam_epoch."0.7.0".arrayvec}"."use_union" =
        (f.arrayvec."${deps.crossbeam_epoch."0.7.0".arrayvec}"."use_union" or false) ||
        (crossbeam_epoch."0.7.0"."nightly" or false) ||
        (f."crossbeam_epoch"."0.7.0"."nightly" or false); }
      { "${deps.crossbeam_epoch."0.7.0".arrayvec}".default = (f.arrayvec."${deps.crossbeam_epoch."0.7.0".arrayvec}".default or false); }
    ];
    cfg_if."${deps.crossbeam_epoch."0.7.0".cfg_if}".default = true;
    crossbeam_epoch = fold recursiveUpdate {} [
      { "0.7.0".default = (f.crossbeam_epoch."0.7.0".default or true); }
      { "0.7.0".lazy_static =
        (f.crossbeam_epoch."0.7.0".lazy_static or false) ||
        (f.crossbeam_epoch."0.7.0".std or false) ||
        (crossbeam_epoch."0.7.0"."std" or false); }
      { "0.7.0".std =
        (f.crossbeam_epoch."0.7.0".std or false) ||
        (f.crossbeam_epoch."0.7.0".default or false) ||
        (crossbeam_epoch."0.7.0"."default" or false); }
    ];
    crossbeam_utils = fold recursiveUpdate {} [
      { "${deps.crossbeam_epoch."0.7.0".crossbeam_utils}"."nightly" =
        (f.crossbeam_utils."${deps.crossbeam_epoch."0.7.0".crossbeam_utils}"."nightly" or false) ||
        (crossbeam_epoch."0.7.0"."nightly" or false) ||
        (f."crossbeam_epoch"."0.7.0"."nightly" or false); }
      { "${deps.crossbeam_epoch."0.7.0".crossbeam_utils}"."std" =
        (f.crossbeam_utils."${deps.crossbeam_epoch."0.7.0".crossbeam_utils}"."std" or false) ||
        (crossbeam_epoch."0.7.0"."std" or false) ||
        (f."crossbeam_epoch"."0.7.0"."std" or false); }
      { "${deps.crossbeam_epoch."0.7.0".crossbeam_utils}".default = (f.crossbeam_utils."${deps.crossbeam_epoch."0.7.0".crossbeam_utils}".default or false); }
    ];
    lazy_static."${deps.crossbeam_epoch."0.7.0".lazy_static}".default = true;
    memoffset."${deps.crossbeam_epoch."0.7.0".memoffset}".default = true;
    scopeguard."${deps.crossbeam_epoch."0.7.0".scopeguard}".default = (f.scopeguard."${deps.crossbeam_epoch."0.7.0".scopeguard}".default or false);
  }) [
    (features_.arrayvec."${deps."crossbeam_epoch"."0.7.0"."arrayvec"}" deps)
    (features_.cfg_if."${deps."crossbeam_epoch"."0.7.0"."cfg_if"}" deps)
    (features_.crossbeam_utils."${deps."crossbeam_epoch"."0.7.0"."crossbeam_utils"}" deps)
    (features_.lazy_static."${deps."crossbeam_epoch"."0.7.0"."lazy_static"}" deps)
    (features_.memoffset."${deps."crossbeam_epoch"."0.7.0"."memoffset"}" deps)
    (features_.scopeguard."${deps."crossbeam_epoch"."0.7.0"."scopeguard"}" deps)
  ];


# end
# crossbeam-utils-0.6.3

  crates.crossbeam_utils."0.6.3" = deps: { features?(features_.crossbeam_utils."0.6.3" deps {}) }: buildRustCrate {
    crateName = "crossbeam-utils";
    version = "0.6.3";
    authors = [ "The Crossbeam Project Developers" ];
    sha256 = "1whyyx07hcfrgxxc6lrwb477r7skpb15ivgyifmm16wp9bmm6ddd";
    dependencies = mapFeatures features ([
      (crates."cfg_if"."${deps."crossbeam_utils"."0.6.3"."cfg_if"}" deps)
    ]);
    features = mkFeatures (features."crossbeam_utils"."0.6.3" or {});
  };
  features_.crossbeam_utils."0.6.3" = deps: f: updateFeatures f (rec {
    cfg_if."${deps.crossbeam_utils."0.6.3".cfg_if}".default = true;
    crossbeam_utils = fold recursiveUpdate {} [
      { "0.6.3".default = (f.crossbeam_utils."0.6.3".default or true); }
      { "0.6.3".std =
        (f.crossbeam_utils."0.6.3".std or false) ||
        (f.crossbeam_utils."0.6.3".default or false) ||
        (crossbeam_utils."0.6.3"."default" or false); }
    ];
  }) [
    (features_.cfg_if."${deps."crossbeam_utils"."0.6.3"."cfg_if"}" deps)
  ];


# end
# dtoa-0.4.3

  crates.dtoa."0.4.3" = deps: { features?(features_.dtoa."0.4.3" deps {}) }: buildRustCrate {
    crateName = "dtoa";
    version = "0.4.3";
    authors = [ "David Tolnay <dtolnay@gmail.com>" ];
    sha256 = "1xysdxdm24sk5ysim7lps4r2qaxfnj0sbakhmps4d42yssx30cw8";
  };
  features_.dtoa."0.4.3" = deps: f: updateFeatures f (rec {
    dtoa."0.4.3".default = (f.dtoa."0.4.3".default or true);
  }) [];


# end
# env_logger-0.6.0

  crates.env_logger."0.6.0" = deps: { features?(features_.env_logger."0.6.0" deps {}) }: buildRustCrate {
    crateName = "env_logger";
    version = "0.6.0";
    authors = [ "The Rust Project Developers" ];
    sha256 = "1k2v2wz2725c7rrxzc05x2jifw3frp0fnsr0p8r4n4jj9j12bkp9";
    dependencies = mapFeatures features ([
      (crates."log"."${deps."env_logger"."0.6.0"."log"}" deps)
    ]
      ++ (if features.env_logger."0.6.0".atty or false then [ (crates.atty."${deps."env_logger"."0.6.0".atty}" deps) ] else [])
      ++ (if features.env_logger."0.6.0".humantime or false then [ (crates.humantime."${deps."env_logger"."0.6.0".humantime}" deps) ] else [])
      ++ (if features.env_logger."0.6.0".regex or false then [ (crates.regex."${deps."env_logger"."0.6.0".regex}" deps) ] else [])
      ++ (if features.env_logger."0.6.0".termcolor or false then [ (crates.termcolor."${deps."env_logger"."0.6.0".termcolor}" deps) ] else []));
    features = mkFeatures (features."env_logger"."0.6.0" or {});
  };
  features_.env_logger."0.6.0" = deps: f: updateFeatures f (rec {
    atty."${deps.env_logger."0.6.0".atty}".default = true;
    env_logger = fold recursiveUpdate {} [
      { "0.6.0".atty =
        (f.env_logger."0.6.0".atty or false) ||
        (f.env_logger."0.6.0".default or false) ||
        (env_logger."0.6.0"."default" or false); }
      { "0.6.0".default = (f.env_logger."0.6.0".default or true); }
      { "0.6.0".humantime =
        (f.env_logger."0.6.0".humantime or false) ||
        (f.env_logger."0.6.0".default or false) ||
        (env_logger."0.6.0"."default" or false); }
      { "0.6.0".regex =
        (f.env_logger."0.6.0".regex or false) ||
        (f.env_logger."0.6.0".default or false) ||
        (env_logger."0.6.0"."default" or false); }
      { "0.6.0".termcolor =
        (f.env_logger."0.6.0".termcolor or false) ||
        (f.env_logger."0.6.0".default or false) ||
        (env_logger."0.6.0"."default" or false); }
    ];
    humantime."${deps.env_logger."0.6.0".humantime}".default = true;
    log = fold recursiveUpdate {} [
      { "${deps.env_logger."0.6.0".log}"."std" = true; }
      { "${deps.env_logger."0.6.0".log}".default = true; }
    ];
    regex."${deps.env_logger."0.6.0".regex}".default = true;
    termcolor."${deps.env_logger."0.6.0".termcolor}".default = true;
  }) [
    (features_.atty."${deps."env_logger"."0.6.0"."atty"}" deps)
    (features_.humantime."${deps."env_logger"."0.6.0"."humantime"}" deps)
    (features_.log."${deps."env_logger"."0.6.0"."log"}" deps)
    (features_.regex."${deps."env_logger"."0.6.0"."regex"}" deps)
    (features_.termcolor."${deps."env_logger"."0.6.0"."termcolor"}" deps)
  ];


# end
# failure-0.1.3

  crates.failure."0.1.3" = deps: { features?(features_.failure."0.1.3" deps {}) }: buildRustCrate {
    crateName = "failure";
    version = "0.1.3";
    authors = [ "Without Boats <boats@mozilla.com>" ];
    sha256 = "0cibp01z0clyxrvkl7v7kq6jszsgcg9vwv6d9l6d1drk9jqdss4s";
    dependencies = mapFeatures features ([
    ]
      ++ (if features.failure."0.1.3".backtrace or false then [ (crates.backtrace."${deps."failure"."0.1.3".backtrace}" deps) ] else [])
      ++ (if features.failure."0.1.3".failure_derive or false then [ (crates.failure_derive."${deps."failure"."0.1.3".failure_derive}" deps) ] else []));
    features = mkFeatures (features."failure"."0.1.3" or {});
  };
  features_.failure."0.1.3" = deps: f: updateFeatures f (rec {
    backtrace."${deps.failure."0.1.3".backtrace}".default = true;
    failure = fold recursiveUpdate {} [
      { "0.1.3".backtrace =
        (f.failure."0.1.3".backtrace or false) ||
        (f.failure."0.1.3".std or false) ||
        (failure."0.1.3"."std" or false); }
      { "0.1.3".default = (f.failure."0.1.3".default or true); }
      { "0.1.3".derive =
        (f.failure."0.1.3".derive or false) ||
        (f.failure."0.1.3".default or false) ||
        (failure."0.1.3"."default" or false); }
      { "0.1.3".failure_derive =
        (f.failure."0.1.3".failure_derive or false) ||
        (f.failure."0.1.3".derive or false) ||
        (failure."0.1.3"."derive" or false); }
      { "0.1.3".std =
        (f.failure."0.1.3".std or false) ||
        (f.failure."0.1.3".default or false) ||
        (failure."0.1.3"."default" or false); }
    ];
    failure_derive."${deps.failure."0.1.3".failure_derive}".default = true;
  }) [
    (features_.backtrace."${deps."failure"."0.1.3"."backtrace"}" deps)
    (features_.failure_derive."${deps."failure"."0.1.3"."failure_derive"}" deps)
  ];


# end
# failure_derive-0.1.3

  crates.failure_derive."0.1.3" = deps: { features?(features_.failure_derive."0.1.3" deps {}) }: buildRustCrate {
    crateName = "failure_derive";
    version = "0.1.3";
    authors = [ "Without Boats <woboats@gmail.com>" ];
    sha256 = "1mh7ad2d17f13g0k29bskp0f9faws0w1q4a5yfzlzi75bw9kidgm";
    procMacro = true;
    build = "build.rs";
    dependencies = mapFeatures features ([
      (crates."proc_macro2"."${deps."failure_derive"."0.1.3"."proc_macro2"}" deps)
      (crates."quote"."${deps."failure_derive"."0.1.3"."quote"}" deps)
      (crates."syn"."${deps."failure_derive"."0.1.3"."syn"}" deps)
      (crates."synstructure"."${deps."failure_derive"."0.1.3"."synstructure"}" deps)
    ]);
    features = mkFeatures (features."failure_derive"."0.1.3" or {});
  };
  features_.failure_derive."0.1.3" = deps: f: updateFeatures f (rec {
    failure_derive."0.1.3".default = (f.failure_derive."0.1.3".default or true);
    proc_macro2."${deps.failure_derive."0.1.3".proc_macro2}".default = true;
    quote."${deps.failure_derive."0.1.3".quote}".default = true;
    syn."${deps.failure_derive."0.1.3".syn}".default = true;
    synstructure."${deps.failure_derive."0.1.3".synstructure}".default = true;
  }) [
    (features_.proc_macro2."${deps."failure_derive"."0.1.3"."proc_macro2"}" deps)
    (features_.quote."${deps."failure_derive"."0.1.3"."quote"}" deps)
    (features_.syn."${deps."failure_derive"."0.1.3"."syn"}" deps)
    (features_.synstructure."${deps."failure_derive"."0.1.3"."synstructure"}" deps)
  ];


# end
# fuchsia-zircon-0.3.3

  crates.fuchsia_zircon."0.3.3" = deps: { features?(features_.fuchsia_zircon."0.3.3" deps {}) }: buildRustCrate {
    crateName = "fuchsia-zircon";
    version = "0.3.3";
    authors = [ "Raph Levien <raph@google.com>" ];
    sha256 = "0jrf4shb1699r4la8z358vri8318w4mdi6qzfqy30p2ymjlca4gk";
    dependencies = mapFeatures features ([
      (crates."bitflags"."${deps."fuchsia_zircon"."0.3.3"."bitflags"}" deps)
      (crates."fuchsia_zircon_sys"."${deps."fuchsia_zircon"."0.3.3"."fuchsia_zircon_sys"}" deps)
    ]);
  };
  features_.fuchsia_zircon."0.3.3" = deps: f: updateFeatures f (rec {
    bitflags."${deps.fuchsia_zircon."0.3.3".bitflags}".default = true;
    fuchsia_zircon."0.3.3".default = (f.fuchsia_zircon."0.3.3".default or true);
    fuchsia_zircon_sys."${deps.fuchsia_zircon."0.3.3".fuchsia_zircon_sys}".default = true;
  }) [
    (features_.bitflags."${deps."fuchsia_zircon"."0.3.3"."bitflags"}" deps)
    (features_.fuchsia_zircon_sys."${deps."fuchsia_zircon"."0.3.3"."fuchsia_zircon_sys"}" deps)
  ];


# end
# fuchsia-zircon-sys-0.3.3

  crates.fuchsia_zircon_sys."0.3.3" = deps: { features?(features_.fuchsia_zircon_sys."0.3.3" deps {}) }: buildRustCrate {
    crateName = "fuchsia-zircon-sys";
    version = "0.3.3";
    authors = [ "Raph Levien <raph@google.com>" ];
    sha256 = "08jp1zxrm9jbrr6l26bjal4dbm8bxfy57ickdgibsqxr1n9j3hf5";
  };
  features_.fuchsia_zircon_sys."0.3.3" = deps: f: updateFeatures f (rec {
    fuchsia_zircon_sys."0.3.3".default = (f.fuchsia_zircon_sys."0.3.3".default or true);
  }) [];


# end
# futures-0.1.25

  crates.futures."0.1.25" = deps: { features?(features_.futures."0.1.25" deps {}) }: buildRustCrate {
    crateName = "futures";
    version = "0.1.25";
    authors = [ "Alex Crichton <alex@alexcrichton.com>" ];
    sha256 = "1gdn9z3mi3jjzbxgvawqh90895130c3ydks55rshja0ncpn985q3";
    features = mkFeatures (features."futures"."0.1.25" or {});
  };
  features_.futures."0.1.25" = deps: f: updateFeatures f (rec {
    futures = fold recursiveUpdate {} [
      { "0.1.25".default = (f.futures."0.1.25".default or true); }
      { "0.1.25".use_std =
        (f.futures."0.1.25".use_std or false) ||
        (f.futures."0.1.25".default or false) ||
        (futures."0.1.25"."default" or false); }
      { "0.1.25".with-deprecated =
        (f.futures."0.1.25".with-deprecated or false) ||
        (f.futures."0.1.25".default or false) ||
        (futures."0.1.25"."default" or false); }
    ];
  }) [];


# end
# grpcio-0.4.1

  crates.grpcio."0.4.1" = deps: { features?(features_.grpcio."0.4.1" deps {}) }: buildRustCrate {
    crateName = "grpcio";
    version = "0.4.1";
    authors = [ "The TiKV Project Developers" ];
    sha256 = "0yclg3hvz4bl5n600xdsnqi7qxj6n8zcazmw8ijhrbkrglssqqz5";
    dependencies = mapFeatures features ([
      (crates."futures"."${deps."grpcio"."0.4.1"."futures"}" deps)
      (crates."grpcio_sys"."${deps."grpcio"."0.4.1"."grpcio_sys"}" deps)
      (crates."libc"."${deps."grpcio"."0.4.1"."libc"}" deps)
      (crates."log"."${deps."grpcio"."0.4.1"."log"}" deps)
    ]
      ++ (if features.grpcio."0.4.1".protobuf or false then [ (crates.protobuf."${deps."grpcio"."0.4.1".protobuf}" deps) ] else []));
    features = mkFeatures (features."grpcio"."0.4.1" or {});
  };
  features_.grpcio."0.4.1" = deps: f: updateFeatures f (rec {
    futures."${deps.grpcio."0.4.1".futures}".default = true;
    grpcio = fold recursiveUpdate {} [
      { "0.4.1".default = (f.grpcio."0.4.1".default or true); }
      { "0.4.1".protobuf =
        (f.grpcio."0.4.1".protobuf or false) ||
        (f.grpcio."0.4.1".protobuf-codec or false) ||
        (grpcio."0.4.1"."protobuf-codec" or false); }
      { "0.4.1".protobuf-codec =
        (f.grpcio."0.4.1".protobuf-codec or false) ||
        (f.grpcio."0.4.1".default or false) ||
        (grpcio."0.4.1"."default" or false); }
      { "0.4.1".secure =
        (f.grpcio."0.4.1".secure or false) ||
        (f.grpcio."0.4.1".default or false) ||
        (grpcio."0.4.1"."default" or false) ||
        (f.grpcio."0.4.1".openssl or false) ||
        (grpcio."0.4.1"."openssl" or false); }
    ];
    grpcio_sys = fold recursiveUpdate {} [
      { "${deps.grpcio."0.4.1".grpcio_sys}"."openssl" =
        (f.grpcio_sys."${deps.grpcio."0.4.1".grpcio_sys}"."openssl" or false) ||
        (grpcio."0.4.1"."openssl" or false) ||
        (f."grpcio"."0.4.1"."openssl" or false); }
      { "${deps.grpcio."0.4.1".grpcio_sys}"."secure" =
        (f.grpcio_sys."${deps.grpcio."0.4.1".grpcio_sys}"."secure" or false) ||
        (grpcio."0.4.1"."secure" or false) ||
        (f."grpcio"."0.4.1"."secure" or false); }
      { "${deps.grpcio."0.4.1".grpcio_sys}".default = true; }
    ];
    libc."${deps.grpcio."0.4.1".libc}".default = true;
    log."${deps.grpcio."0.4.1".log}".default = true;
    protobuf."${deps.grpcio."0.4.1".protobuf}".default = true;
  }) [
    (features_.futures."${deps."grpcio"."0.4.1"."futures"}" deps)
    (features_.grpcio_sys."${deps."grpcio"."0.4.1"."grpcio_sys"}" deps)
    (features_.libc."${deps."grpcio"."0.4.1"."libc"}" deps)
    (features_.log."${deps."grpcio"."0.4.1"."log"}" deps)
    (features_.protobuf."${deps."grpcio"."0.4.1"."protobuf"}" deps)
  ];


# end
# grpcio-compiler-0.4.1

  crates.grpcio_compiler."0.4.1" = deps: { features?(features_.grpcio_compiler."0.4.1" deps {}) }: buildRustCrate {
    crateName = "grpcio-compiler";
    version = "0.4.1";
    authors = [ "The TiKV Project Developers" ];
    sha256 = "0p8nysanm0n2av71cdjh72jxr8xk34chf7d3fp74rhdcb0kb6cik";
    crateBin =
      [{  name = "grpc_rust_plugin"; }];
    dependencies = mapFeatures features ([
      (crates."protobuf"."${deps."grpcio_compiler"."0.4.1"."protobuf"}" deps)
      (crates."protobuf_codegen"."${deps."grpcio_compiler"."0.4.1"."protobuf_codegen"}" deps)
    ]);
  };
  features_.grpcio_compiler."0.4.1" = deps: f: updateFeatures f (rec {
    grpcio_compiler."0.4.1".default = (f.grpcio_compiler."0.4.1".default or true);
    protobuf."${deps.grpcio_compiler."0.4.1".protobuf}".default = true;
    protobuf_codegen."${deps.grpcio_compiler."0.4.1".protobuf_codegen}".default = true;
  }) [
    (features_.protobuf."${deps."grpcio_compiler"."0.4.1"."protobuf"}" deps)
    (features_.protobuf_codegen."${deps."grpcio_compiler"."0.4.1"."protobuf_codegen"}" deps)
  ];


# end
# grpcio-sys-0.4.1

  crates.grpcio_sys."0.4.1" = deps: { features?(features_.grpcio_sys."0.4.1" deps {}) }: buildRustCrate {
    crateName = "grpcio-sys";
    version = "0.4.1";
    authors = [ "The TiKV Project Developers" ];
    sha256 = "043ppfdkl1vc1nw641bq7r1032lbidhnhkn9rm676a6advsbyxiv";
    build = "build.rs";
    dependencies = mapFeatures features ([
      (crates."libc"."${deps."grpcio_sys"."0.4.1"."libc"}" deps)
    ]);

    buildDependencies = mapFeatures features ([
      (crates."cc"."${deps."grpcio_sys"."0.4.1"."cc"}" deps)
      (crates."cmake"."${deps."grpcio_sys"."0.4.1"."cmake"}" deps)
      (crates."pkg_config"."${deps."grpcio_sys"."0.4.1"."pkg_config"}" deps)
    ]);
    features = mkFeatures (features."grpcio_sys"."0.4.1" or {});
  };
  features_.grpcio_sys."0.4.1" = deps: f: updateFeatures f (rec {
    cc."${deps.grpcio_sys."0.4.1".cc}".default = true;
    cmake."${deps.grpcio_sys."0.4.1".cmake}".default = true;
    grpcio_sys = fold recursiveUpdate {} [
      { "0.4.1".default = (f.grpcio_sys."0.4.1".default or true); }
      { "0.4.1".secure =
        (f.grpcio_sys."0.4.1".secure or false) ||
        (f.grpcio_sys."0.4.1".openssl or false) ||
        (grpcio_sys."0.4.1"."openssl" or false); }
    ];
    libc."${deps.grpcio_sys."0.4.1".libc}".default = true;
    pkg_config."${deps.grpcio_sys."0.4.1".pkg_config}".default = true;
  }) [
    (features_.libc."${deps."grpcio_sys"."0.4.1"."libc"}" deps)
    (features_.cc."${deps."grpcio_sys"."0.4.1"."cc"}" deps)
    (features_.cmake."${deps."grpcio_sys"."0.4.1"."cmake"}" deps)
    (features_.pkg_config."${deps."grpcio_sys"."0.4.1"."pkg_config"}" deps)
  ];


# end
# hostname-0.1.5

  crates.hostname."0.1.5" = deps: { features?(features_.hostname."0.1.5" deps {}) }: buildRustCrate {
    crateName = "hostname";
    version = "0.1.5";
    authors = [ "fengcen <fengcen.love@gmail.com>" ];
    sha256 = "1383lcnzmiqm0bz0i0h33rvbl5ma125ca5lfnx4qzx1dzdz0wl2a";
    libPath = "src/lib.rs";
    dependencies = (if (kernel == "linux" || kernel == "darwin") || kernel == "redox" then mapFeatures features ([
      (crates."libc"."${deps."hostname"."0.1.5"."libc"}" deps)
    ]) else [])
      ++ (if kernel == "windows" then mapFeatures features ([
      (crates."winutil"."${deps."hostname"."0.1.5"."winutil"}" deps)
    ]) else []);
    features = mkFeatures (features."hostname"."0.1.5" or {});
  };
  features_.hostname."0.1.5" = deps: f: updateFeatures f (rec {
    hostname."0.1.5".default = (f.hostname."0.1.5".default or true);
    libc."${deps.hostname."0.1.5".libc}".default = true;
    winutil."${deps.hostname."0.1.5".winutil}".default = true;
  }) [
    (features_.libc."${deps."hostname"."0.1.5"."libc"}" deps)
    (features_.winutil."${deps."hostname"."0.1.5"."winutil"}" deps)
  ];


# end
# hound-3.4.0

  crates.hound."3.4.0" = deps: { features?(features_.hound."3.4.0" deps {}) }: buildRustCrate {
    crateName = "hound";
    version = "3.4.0";
    authors = [ "Ruud van Asseldonk <dev@veniogames.com>" ];
    sha256 = "1jc1ykq1aayh50bl1jk3cywpw26m99jpgv8dc39492h5zifsjqzk";
  };
  features_.hound."3.4.0" = deps: f: updateFeatures f (rec {
    hound."3.4.0".default = (f.hound."3.4.0".default or true);
  }) [];


# end
# humantime-1.2.0

  crates.humantime."1.2.0" = deps: { features?(features_.humantime."1.2.0" deps {}) }: buildRustCrate {
    crateName = "humantime";
    version = "1.2.0";
    authors = [ "Paul Colomiets <paul@colomiets.name>" ];
    sha256 = "0wlcxzz2mhq0brkfbjb12hc6jm17bgm8m6pdgblw4qjwmf26aw28";
    libPath = "src/lib.rs";
    dependencies = mapFeatures features ([
      (crates."quick_error"."${deps."humantime"."1.2.0"."quick_error"}" deps)
    ]);
  };
  features_.humantime."1.2.0" = deps: f: updateFeatures f (rec {
    humantime."1.2.0".default = (f.humantime."1.2.0".default or true);
    quick_error."${deps.humantime."1.2.0".quick_error}".default = true;
  }) [
    (features_.quick_error."${deps."humantime"."1.2.0"."quick_error"}" deps)
  ];


# end
# iovec-0.1.2

  crates.iovec."0.1.2" = deps: { features?(features_.iovec."0.1.2" deps {}) }: buildRustCrate {
    crateName = "iovec";
    version = "0.1.2";
    authors = [ "Carl Lerche <me@carllerche.com>" ];
    sha256 = "0vjymmb7wj4v4kza5jjn48fcdb85j3k37y7msjl3ifz0p9yiyp2r";
    dependencies = (if (kernel == "linux" || kernel == "darwin") then mapFeatures features ([
      (crates."libc"."${deps."iovec"."0.1.2"."libc"}" deps)
    ]) else [])
      ++ (if kernel == "windows" then mapFeatures features ([
      (crates."winapi"."${deps."iovec"."0.1.2"."winapi"}" deps)
    ]) else []);
  };
  features_.iovec."0.1.2" = deps: f: updateFeatures f (rec {
    iovec."0.1.2".default = (f.iovec."0.1.2".default or true);
    libc."${deps.iovec."0.1.2".libc}".default = true;
    winapi."${deps.iovec."0.1.2".winapi}".default = true;
  }) [
    (features_.libc."${deps."iovec"."0.1.2"."libc"}" deps)
    (features_.winapi."${deps."iovec"."0.1.2"."winapi"}" deps)
  ];


# end
# kernel32-sys-0.2.2

  crates.kernel32_sys."0.2.2" = deps: { features?(features_.kernel32_sys."0.2.2" deps {}) }: buildRustCrate {
    crateName = "kernel32-sys";
    version = "0.2.2";
    authors = [ "Peter Atashian <retep998@gmail.com>" ];
    sha256 = "1lrw1hbinyvr6cp28g60z97w32w8vsk6pahk64pmrv2fmby8srfj";
    libName = "kernel32";
    build = "build.rs";
    dependencies = mapFeatures features ([
      (crates."winapi"."${deps."kernel32_sys"."0.2.2"."winapi"}" deps)
    ]);

    buildDependencies = mapFeatures features ([
      (crates."winapi_build"."${deps."kernel32_sys"."0.2.2"."winapi_build"}" deps)
    ]);
  };
  features_.kernel32_sys."0.2.2" = deps: f: updateFeatures f (rec {
    kernel32_sys."0.2.2".default = (f.kernel32_sys."0.2.2".default or true);
    winapi."${deps.kernel32_sys."0.2.2".winapi}".default = true;
    winapi_build."${deps.kernel32_sys."0.2.2".winapi_build}".default = true;
  }) [
    (features_.winapi."${deps."kernel32_sys"."0.2.2"."winapi"}" deps)
    (features_.winapi_build."${deps."kernel32_sys"."0.2.2"."winapi_build"}" deps)
  ];


# end
# lazy_static-1.2.0

  crates.lazy_static."1.2.0" = deps: { features?(features_.lazy_static."1.2.0" deps {}) }: buildRustCrate {
    crateName = "lazy_static";
    version = "1.2.0";
    authors = [ "Marvin Löbel <loebel.marvin@gmail.com>" ];
    sha256 = "07p3b30k2akyr6xw08ggd5qiz5nw3vd3agggj360fcc1njz7d0ss";
    dependencies = mapFeatures features ([
]);
    features = mkFeatures (features."lazy_static"."1.2.0" or {});
  };
  features_.lazy_static."1.2.0" = deps: f: updateFeatures f (rec {
    lazy_static = fold recursiveUpdate {} [
      { "1.2.0".default = (f.lazy_static."1.2.0".default or true); }
      { "1.2.0".spin =
        (f.lazy_static."1.2.0".spin or false) ||
        (f.lazy_static."1.2.0".spin_no_std or false) ||
        (lazy_static."1.2.0"."spin_no_std" or false); }
    ];
  }) [];


# end
# lazycell-1.2.1

  crates.lazycell."1.2.1" = deps: { features?(features_.lazycell."1.2.1" deps {}) }: buildRustCrate {
    crateName = "lazycell";
    version = "1.2.1";
    authors = [ "Alex Crichton <alex@alexcrichton.com>" "Nikita Pekin <contact@nikitapek.in>" ];
    sha256 = "1m4h2q9rgxrgc7xjnws1x81lrb68jll8w3pykx1a9bhr29q2mcwm";
    dependencies = mapFeatures features ([
]);
    features = mkFeatures (features."lazycell"."1.2.1" or {});
  };
  features_.lazycell."1.2.1" = deps: f: updateFeatures f (rec {
    lazycell = fold recursiveUpdate {} [
      { "1.2.1".clippy =
        (f.lazycell."1.2.1".clippy or false) ||
        (f.lazycell."1.2.1".nightly-testing or false) ||
        (lazycell."1.2.1"."nightly-testing" or false); }
      { "1.2.1".default = (f.lazycell."1.2.1".default or true); }
      { "1.2.1".nightly =
        (f.lazycell."1.2.1".nightly or false) ||
        (f.lazycell."1.2.1".nightly-testing or false) ||
        (lazycell."1.2.1"."nightly-testing" or false); }
    ];
  }) [];


# end
# libc-0.2.45

  crates.libc."0.2.45" = deps: { features?(features_.libc."0.2.45" deps {}) }: buildRustCrate {
    crateName = "libc";
    version = "0.2.45";
    authors = [ "The Rust Project Developers" ];
    sha256 = "0rfhz6blavdirj8nircki5fay3dlvpihdypbazx5lpy2xz6y0w10";
    build = "build.rs";
    dependencies = mapFeatures features ([
]);
    features = mkFeatures (features."libc"."0.2.45" or {});
  };
  features_.libc."0.2.45" = deps: f: updateFeatures f (rec {
    libc = fold recursiveUpdate {} [
      { "0.2.45".align =
        (f.libc."0.2.45".align or false) ||
        (f.libc."0.2.45".rustc-dep-of-std or false) ||
        (libc."0.2.45"."rustc-dep-of-std" or false); }
      { "0.2.45".default = (f.libc."0.2.45".default or true); }
      { "0.2.45".rustc-std-workspace-core =
        (f.libc."0.2.45".rustc-std-workspace-core or false) ||
        (f.libc."0.2.45".rustc-dep-of-std or false) ||
        (libc."0.2.45"."rustc-dep-of-std" or false); }
      { "0.2.45".use_std =
        (f.libc."0.2.45".use_std or false) ||
        (f.libc."0.2.45".default or false) ||
        (libc."0.2.45"."default" or false); }
    ];
  }) [];


# end
# linked-hash-map-0.5.1

  crates.linked_hash_map."0.5.1" = deps: { features?(features_.linked_hash_map."0.5.1" deps {}) }: buildRustCrate {
    crateName = "linked-hash-map";
    version = "0.5.1";
    authors = [ "Stepan Koltsov <stepan.koltsov@gmail.com>" "Andrew Paseltiner <apaseltiner@gmail.com>" ];
    sha256 = "1f29c7j53z7w5v0g115yii9dmmbsahr93ak375g48vi75v3p4030";
    dependencies = mapFeatures features ([
]);
    features = mkFeatures (features."linked_hash_map"."0.5.1" or {});
  };
  features_.linked_hash_map."0.5.1" = deps: f: updateFeatures f (rec {
    linked_hash_map = fold recursiveUpdate {} [
      { "0.5.1".default = (f.linked_hash_map."0.5.1".default or true); }
      { "0.5.1".heapsize =
        (f.linked_hash_map."0.5.1".heapsize or false) ||
        (f.linked_hash_map."0.5.1".heapsize_impl or false) ||
        (linked_hash_map."0.5.1"."heapsize_impl" or false); }
      { "0.5.1".serde =
        (f.linked_hash_map."0.5.1".serde or false) ||
        (f.linked_hash_map."0.5.1".serde_impl or false) ||
        (linked_hash_map."0.5.1"."serde_impl" or false); }
      { "0.5.1".serde_test =
        (f.linked_hash_map."0.5.1".serde_test or false) ||
        (f.linked_hash_map."0.5.1".serde_impl or false) ||
        (linked_hash_map."0.5.1"."serde_impl" or false); }
    ];
  }) [];


# end
# lock_api-0.1.5

  crates.lock_api."0.1.5" = deps: { features?(features_.lock_api."0.1.5" deps {}) }: buildRustCrate {
    crateName = "lock_api";
    version = "0.1.5";
    authors = [ "Amanieu d'Antras <amanieu@gmail.com>" ];
    sha256 = "132sidr5hvjfkaqm3l95zpcpi8yk5ddd0g79zf1ad4v65sxirqqm";
    dependencies = mapFeatures features ([
      (crates."scopeguard"."${deps."lock_api"."0.1.5"."scopeguard"}" deps)
    ]
      ++ (if features.lock_api."0.1.5".owning_ref or false then [ (crates.owning_ref."${deps."lock_api"."0.1.5".owning_ref}" deps) ] else []));
    features = mkFeatures (features."lock_api"."0.1.5" or {});
  };
  features_.lock_api."0.1.5" = deps: f: updateFeatures f (rec {
    lock_api."0.1.5".default = (f.lock_api."0.1.5".default or true);
    owning_ref."${deps.lock_api."0.1.5".owning_ref}".default = true;
    scopeguard."${deps.lock_api."0.1.5".scopeguard}".default = (f.scopeguard."${deps.lock_api."0.1.5".scopeguard}".default or false);
  }) [
    (features_.owning_ref."${deps."lock_api"."0.1.5"."owning_ref"}" deps)
    (features_.scopeguard."${deps."lock_api"."0.1.5"."scopeguard"}" deps)
  ];


# end
# log-0.4.6

  crates.log."0.4.6" = deps: { features?(features_.log."0.4.6" deps {}) }: buildRustCrate {
    crateName = "log";
    version = "0.4.6";
    authors = [ "The Rust Project Developers" ];
    sha256 = "1nd8dl9mvc9vd6fks5d4gsxaz990xi6rzlb8ymllshmwi153vngr";
    dependencies = mapFeatures features ([
      (crates."cfg_if"."${deps."log"."0.4.6"."cfg_if"}" deps)
    ]);
    features = mkFeatures (features."log"."0.4.6" or {});
  };
  features_.log."0.4.6" = deps: f: updateFeatures f (rec {
    cfg_if."${deps.log."0.4.6".cfg_if}".default = true;
    log."0.4.6".default = (f.log."0.4.6".default or true);
  }) [
    (features_.cfg_if."${deps."log"."0.4.6"."cfg_if"}" deps)
  ];


# end
# memchr-2.1.2

  crates.memchr."2.1.2" = deps: { features?(features_.memchr."2.1.2" deps {}) }: buildRustCrate {
    crateName = "memchr";
    version = "2.1.2";
    authors = [ "Andrew Gallant <jamslam@gmail.com>" "bluss" ];
    sha256 = "0vdwvcmn1j65qslsxlk7fjhm53nicd5cg5hvdmbg6kybyf1lnkv1";
    dependencies = mapFeatures features ([
      (crates."cfg_if"."${deps."memchr"."2.1.2"."cfg_if"}" deps)
    ]
      ++ (if features.memchr."2.1.2".libc or false then [ (crates.libc."${deps."memchr"."2.1.2".libc}" deps) ] else []));

    buildDependencies = mapFeatures features ([
      (crates."version_check"."${deps."memchr"."2.1.2"."version_check"}" deps)
    ]);
    features = mkFeatures (features."memchr"."2.1.2" or {});
  };
  features_.memchr."2.1.2" = deps: f: updateFeatures f (rec {
    cfg_if."${deps.memchr."2.1.2".cfg_if}".default = true;
    libc = fold recursiveUpdate {} [
      { "${deps.memchr."2.1.2".libc}"."use_std" =
        (f.libc."${deps.memchr."2.1.2".libc}"."use_std" or false) ||
        (memchr."2.1.2"."use_std" or false) ||
        (f."memchr"."2.1.2"."use_std" or false); }
      { "${deps.memchr."2.1.2".libc}".default = (f.libc."${deps.memchr."2.1.2".libc}".default or false); }
    ];
    memchr = fold recursiveUpdate {} [
      { "2.1.2".default = (f.memchr."2.1.2".default or true); }
      { "2.1.2".libc =
        (f.memchr."2.1.2".libc or false) ||
        (f.memchr."2.1.2".default or false) ||
        (memchr."2.1.2"."default" or false) ||
        (f.memchr."2.1.2".use_std or false) ||
        (memchr."2.1.2"."use_std" or false); }
      { "2.1.2".use_std =
        (f.memchr."2.1.2".use_std or false) ||
        (f.memchr."2.1.2".default or false) ||
        (memchr."2.1.2"."default" or false); }
    ];
    version_check."${deps.memchr."2.1.2".version_check}".default = true;
  }) [
    (features_.cfg_if."${deps."memchr"."2.1.2"."cfg_if"}" deps)
    (features_.libc."${deps."memchr"."2.1.2"."libc"}" deps)
    (features_.version_check."${deps."memchr"."2.1.2"."version_check"}" deps)
  ];


# end
# memoffset-0.2.1

  crates.memoffset."0.2.1" = deps: { features?(features_.memoffset."0.2.1" deps {}) }: buildRustCrate {
    crateName = "memoffset";
    version = "0.2.1";
    authors = [ "Gilad Naaman <gilad.naaman@gmail.com>" ];
    sha256 = "00vym01jk9slibq2nsiilgffp7n6k52a4q3n4dqp0xf5kzxvffcf";
  };
  features_.memoffset."0.2.1" = deps: f: updateFeatures f (rec {
    memoffset."0.2.1".default = (f.memoffset."0.2.1".default or true);
  }) [];


# end
# mio-0.6.16

  crates.mio."0.6.16" = deps: { features?(features_.mio."0.6.16" deps {}) }: buildRustCrate {
    crateName = "mio";
    version = "0.6.16";
    authors = [ "Carl Lerche <me@carllerche.com>" ];
    sha256 = "14vyrlmf0w984pi7ad9qvmlfj6vrb0wn6i8ik9j87w5za2r3rban";
    dependencies = mapFeatures features ([
      (crates."iovec"."${deps."mio"."0.6.16"."iovec"}" deps)
      (crates."lazycell"."${deps."mio"."0.6.16"."lazycell"}" deps)
      (crates."log"."${deps."mio"."0.6.16"."log"}" deps)
      (crates."net2"."${deps."mio"."0.6.16"."net2"}" deps)
      (crates."slab"."${deps."mio"."0.6.16"."slab"}" deps)
    ])
      ++ (if kernel == "fuchsia" then mapFeatures features ([
      (crates."fuchsia_zircon"."${deps."mio"."0.6.16"."fuchsia_zircon"}" deps)
      (crates."fuchsia_zircon_sys"."${deps."mio"."0.6.16"."fuchsia_zircon_sys"}" deps)
    ]) else [])
      ++ (if (kernel == "linux" || kernel == "darwin") then mapFeatures features ([
      (crates."libc"."${deps."mio"."0.6.16"."libc"}" deps)
    ]) else [])
      ++ (if kernel == "windows" then mapFeatures features ([
      (crates."kernel32_sys"."${deps."mio"."0.6.16"."kernel32_sys"}" deps)
      (crates."miow"."${deps."mio"."0.6.16"."miow"}" deps)
      (crates."winapi"."${deps."mio"."0.6.16"."winapi"}" deps)
    ]) else []);
    features = mkFeatures (features."mio"."0.6.16" or {});
  };
  features_.mio."0.6.16" = deps: f: updateFeatures f (rec {
    fuchsia_zircon."${deps.mio."0.6.16".fuchsia_zircon}".default = true;
    fuchsia_zircon_sys."${deps.mio."0.6.16".fuchsia_zircon_sys}".default = true;
    iovec."${deps.mio."0.6.16".iovec}".default = true;
    kernel32_sys."${deps.mio."0.6.16".kernel32_sys}".default = true;
    lazycell."${deps.mio."0.6.16".lazycell}".default = true;
    libc."${deps.mio."0.6.16".libc}".default = true;
    log."${deps.mio."0.6.16".log}".default = true;
    mio = fold recursiveUpdate {} [
      { "0.6.16".default = (f.mio."0.6.16".default or true); }
      { "0.6.16".with-deprecated =
        (f.mio."0.6.16".with-deprecated or false) ||
        (f.mio."0.6.16".default or false) ||
        (mio."0.6.16"."default" or false); }
    ];
    miow."${deps.mio."0.6.16".miow}".default = true;
    net2."${deps.mio."0.6.16".net2}".default = true;
    slab."${deps.mio."0.6.16".slab}".default = true;
    winapi."${deps.mio."0.6.16".winapi}".default = true;
  }) [
    (features_.iovec."${deps."mio"."0.6.16"."iovec"}" deps)
    (features_.lazycell."${deps."mio"."0.6.16"."lazycell"}" deps)
    (features_.log."${deps."mio"."0.6.16"."log"}" deps)
    (features_.net2."${deps."mio"."0.6.16"."net2"}" deps)
    (features_.slab."${deps."mio"."0.6.16"."slab"}" deps)
    (features_.fuchsia_zircon."${deps."mio"."0.6.16"."fuchsia_zircon"}" deps)
    (features_.fuchsia_zircon_sys."${deps."mio"."0.6.16"."fuchsia_zircon_sys"}" deps)
    (features_.libc."${deps."mio"."0.6.16"."libc"}" deps)
    (features_.kernel32_sys."${deps."mio"."0.6.16"."kernel32_sys"}" deps)
    (features_.miow."${deps."mio"."0.6.16"."miow"}" deps)
    (features_.winapi."${deps."mio"."0.6.16"."winapi"}" deps)
  ];


# end
# mio-named-pipes-0.1.6

  crates.mio_named_pipes."0.1.6" = deps: { features?(features_.mio_named_pipes."0.1.6" deps {}) }: buildRustCrate {
    crateName = "mio-named-pipes";
    version = "0.1.6";
    authors = [ "Alex Crichton <alex@alexcrichton.com>" ];
    sha256 = "016r9rjh8yq94rs8vn7z4jasx08z1q06jfwcvg39bihfyar4gsfx";
    dependencies = (if kernel == "windows" then mapFeatures features ([
      (crates."log"."${deps."mio_named_pipes"."0.1.6"."log"}" deps)
      (crates."mio"."${deps."mio_named_pipes"."0.1.6"."mio"}" deps)
      (crates."miow"."${deps."mio_named_pipes"."0.1.6"."miow"}" deps)
      (crates."winapi"."${deps."mio_named_pipes"."0.1.6"."winapi"}" deps)
    ]) else []);
  };
  features_.mio_named_pipes."0.1.6" = deps: f: updateFeatures f (rec {
    log."${deps.mio_named_pipes."0.1.6".log}".default = true;
    mio."${deps.mio_named_pipes."0.1.6".mio}".default = true;
    mio_named_pipes."0.1.6".default = (f.mio_named_pipes."0.1.6".default or true);
    miow."${deps.mio_named_pipes."0.1.6".miow}".default = true;
    winapi = fold recursiveUpdate {} [
      { "${deps.mio_named_pipes."0.1.6".winapi}"."ioapiset" = true; }
      { "${deps.mio_named_pipes."0.1.6".winapi}"."minwinbase" = true; }
      { "${deps.mio_named_pipes."0.1.6".winapi}"."winbase" = true; }
      { "${deps.mio_named_pipes."0.1.6".winapi}"."winerror" = true; }
      { "${deps.mio_named_pipes."0.1.6".winapi}".default = true; }
    ];
  }) [
    (features_.log."${deps."mio_named_pipes"."0.1.6"."log"}" deps)
    (features_.mio."${deps."mio_named_pipes"."0.1.6"."mio"}" deps)
    (features_.miow."${deps."mio_named_pipes"."0.1.6"."miow"}" deps)
    (features_.winapi."${deps."mio_named_pipes"."0.1.6"."winapi"}" deps)
  ];


# end
# mio-uds-0.6.7

  crates.mio_uds."0.6.7" = deps: { features?(features_.mio_uds."0.6.7" deps {}) }: buildRustCrate {
    crateName = "mio-uds";
    version = "0.6.7";
    authors = [ "Alex Crichton <alex@alexcrichton.com>" ];
    sha256 = "1gff9908pvvysv7zgxvyxy7x34fnhs088cr0j8mgwj8j24mswrhm";
    dependencies = (if (kernel == "linux" || kernel == "darwin") then mapFeatures features ([
      (crates."iovec"."${deps."mio_uds"."0.6.7"."iovec"}" deps)
      (crates."libc"."${deps."mio_uds"."0.6.7"."libc"}" deps)
      (crates."mio"."${deps."mio_uds"."0.6.7"."mio"}" deps)
    ]) else []);
  };
  features_.mio_uds."0.6.7" = deps: f: updateFeatures f (rec {
    iovec."${deps.mio_uds."0.6.7".iovec}".default = true;
    libc."${deps.mio_uds."0.6.7".libc}".default = true;
    mio."${deps.mio_uds."0.6.7".mio}".default = true;
    mio_uds."0.6.7".default = (f.mio_uds."0.6.7".default or true);
  }) [
    (features_.iovec."${deps."mio_uds"."0.6.7"."iovec"}" deps)
    (features_.libc."${deps."mio_uds"."0.6.7"."libc"}" deps)
    (features_.mio."${deps."mio_uds"."0.6.7"."mio"}" deps)
  ];


# end
# miow-0.2.1

  crates.miow."0.2.1" = deps: { features?(features_.miow."0.2.1" deps {}) }: buildRustCrate {
    crateName = "miow";
    version = "0.2.1";
    authors = [ "Alex Crichton <alex@alexcrichton.com>" ];
    sha256 = "14f8zkc6ix7mkyis1vsqnim8m29b6l55abkba3p2yz7j1ibcvrl0";
    dependencies = mapFeatures features ([
      (crates."kernel32_sys"."${deps."miow"."0.2.1"."kernel32_sys"}" deps)
      (crates."net2"."${deps."miow"."0.2.1"."net2"}" deps)
      (crates."winapi"."${deps."miow"."0.2.1"."winapi"}" deps)
      (crates."ws2_32_sys"."${deps."miow"."0.2.1"."ws2_32_sys"}" deps)
    ]);
  };
  features_.miow."0.2.1" = deps: f: updateFeatures f (rec {
    kernel32_sys."${deps.miow."0.2.1".kernel32_sys}".default = true;
    miow."0.2.1".default = (f.miow."0.2.1".default or true);
    net2."${deps.miow."0.2.1".net2}".default = (f.net2."${deps.miow."0.2.1".net2}".default or false);
    winapi."${deps.miow."0.2.1".winapi}".default = true;
    ws2_32_sys."${deps.miow."0.2.1".ws2_32_sys}".default = true;
  }) [
    (features_.kernel32_sys."${deps."miow"."0.2.1"."kernel32_sys"}" deps)
    (features_.net2."${deps."miow"."0.2.1"."net2"}" deps)
    (features_.winapi."${deps."miow"."0.2.1"."winapi"}" deps)
    (features_.ws2_32_sys."${deps."miow"."0.2.1"."ws2_32_sys"}" deps)
  ];


# end
# miow-0.3.3

  crates.miow."0.3.3" = deps: { features?(features_.miow."0.3.3" deps {}) }: buildRustCrate {
    crateName = "miow";
    version = "0.3.3";
    authors = [ "Alex Crichton <alex@alexcrichton.com>" ];
    sha256 = "1mlk5mn00cl6bmf8qlpc6r85dxf4l45vbkbzshsr1mrkb3hn1j57";
    dependencies = mapFeatures features ([
      (crates."socket2"."${deps."miow"."0.3.3"."socket2"}" deps)
      (crates."winapi"."${deps."miow"."0.3.3"."winapi"}" deps)
    ]);
  };
  features_.miow."0.3.3" = deps: f: updateFeatures f (rec {
    miow."0.3.3".default = (f.miow."0.3.3".default or true);
    socket2."${deps.miow."0.3.3".socket2}".default = true;
    winapi = fold recursiveUpdate {} [
      { "${deps.miow."0.3.3".winapi}"."fileapi" = true; }
      { "${deps.miow."0.3.3".winapi}"."handleapi" = true; }
      { "${deps.miow."0.3.3".winapi}"."ioapiset" = true; }
      { "${deps.miow."0.3.3".winapi}"."minwindef" = true; }
      { "${deps.miow."0.3.3".winapi}"."namedpipeapi" = true; }
      { "${deps.miow."0.3.3".winapi}"."ntdef" = true; }
      { "${deps.miow."0.3.3".winapi}"."std" = true; }
      { "${deps.miow."0.3.3".winapi}"."synchapi" = true; }
      { "${deps.miow."0.3.3".winapi}"."winerror" = true; }
      { "${deps.miow."0.3.3".winapi}"."winsock2" = true; }
      { "${deps.miow."0.3.3".winapi}"."ws2def" = true; }
      { "${deps.miow."0.3.3".winapi}"."ws2ipdef" = true; }
      { "${deps.miow."0.3.3".winapi}".default = true; }
    ];
  }) [
    (features_.socket2."${deps."miow"."0.3.3"."socket2"}" deps)
    (features_.winapi."${deps."miow"."0.3.3"."winapi"}" deps)
  ];


# end
# net2-0.2.33

  crates.net2."0.2.33" = deps: { features?(features_.net2."0.2.33" deps {}) }: buildRustCrate {
    crateName = "net2";
    version = "0.2.33";
    authors = [ "Alex Crichton <alex@alexcrichton.com>" ];
    sha256 = "1qnmajafgybj5wyxz9iffa8x5wgbwd2znfklmhqj7vl6lw1m65mq";
    dependencies = mapFeatures features ([
      (crates."cfg_if"."${deps."net2"."0.2.33"."cfg_if"}" deps)
    ])
      ++ (if kernel == "redox" || (kernel == "linux" || kernel == "darwin") then mapFeatures features ([
      (crates."libc"."${deps."net2"."0.2.33"."libc"}" deps)
    ]) else [])
      ++ (if kernel == "windows" then mapFeatures features ([
      (crates."winapi"."${deps."net2"."0.2.33"."winapi"}" deps)
    ]) else []);
    features = mkFeatures (features."net2"."0.2.33" or {});
  };
  features_.net2."0.2.33" = deps: f: updateFeatures f (rec {
    cfg_if."${deps.net2."0.2.33".cfg_if}".default = true;
    libc."${deps.net2."0.2.33".libc}".default = true;
    net2 = fold recursiveUpdate {} [
      { "0.2.33".default = (f.net2."0.2.33".default or true); }
      { "0.2.33".duration =
        (f.net2."0.2.33".duration or false) ||
        (f.net2."0.2.33".default or false) ||
        (net2."0.2.33"."default" or false); }
    ];
    winapi = fold recursiveUpdate {} [
      { "${deps.net2."0.2.33".winapi}"."handleapi" = true; }
      { "${deps.net2."0.2.33".winapi}"."winsock2" = true; }
      { "${deps.net2."0.2.33".winapi}"."ws2def" = true; }
      { "${deps.net2."0.2.33".winapi}"."ws2ipdef" = true; }
      { "${deps.net2."0.2.33".winapi}"."ws2tcpip" = true; }
      { "${deps.net2."0.2.33".winapi}".default = true; }
    ];
  }) [
    (features_.cfg_if."${deps."net2"."0.2.33"."cfg_if"}" deps)
    (features_.libc."${deps."net2"."0.2.33"."libc"}" deps)
    (features_.winapi."${deps."net2"."0.2.33"."winapi"}" deps)
  ];


# end
# nix-0.9.0

  crates.nix."0.9.0" = deps: { features?(features_.nix."0.9.0" deps {}) }: buildRustCrate {
    crateName = "nix";
    version = "0.9.0";
    authors = [ "The nix-rust Project Developers" ];
    sha256 = "00p63bphzwwn460rja5l2wcpgmv7ljf7illf6n95cppx63d180q0";
    dependencies = mapFeatures features ([
      (crates."bitflags"."${deps."nix"."0.9.0"."bitflags"}" deps)
      (crates."cfg_if"."${deps."nix"."0.9.0"."cfg_if"}" deps)
      (crates."libc"."${deps."nix"."0.9.0"."libc"}" deps)
      (crates."void"."${deps."nix"."0.9.0"."void"}" deps)
    ]);
  };
  features_.nix."0.9.0" = deps: f: updateFeatures f (rec {
    bitflags."${deps.nix."0.9.0".bitflags}".default = true;
    cfg_if."${deps.nix."0.9.0".cfg_if}".default = true;
    libc."${deps.nix."0.9.0".libc}".default = true;
    nix."0.9.0".default = (f.nix."0.9.0".default or true);
    void."${deps.nix."0.9.0".void}".default = true;
  }) [
    (features_.bitflags."${deps."nix"."0.9.0"."bitflags"}" deps)
    (features_.cfg_if."${deps."nix"."0.9.0"."cfg_if"}" deps)
    (features_.libc."${deps."nix"."0.9.0"."libc"}" deps)
    (features_.void."${deps."nix"."0.9.0"."void"}" deps)
  ];


# end
# nodrop-0.1.13

  crates.nodrop."0.1.13" = deps: { features?(features_.nodrop."0.1.13" deps {}) }: buildRustCrate {
    crateName = "nodrop";
    version = "0.1.13";
    authors = [ "bluss" ];
    sha256 = "0gkfx6wihr9z0m8nbdhma5pyvbipznjpkzny2d4zkc05b0vnhinb";
    dependencies = mapFeatures features ([
]);
    features = mkFeatures (features."nodrop"."0.1.13" or {});
  };
  features_.nodrop."0.1.13" = deps: f: updateFeatures f (rec {
    nodrop = fold recursiveUpdate {} [
      { "0.1.13".default = (f.nodrop."0.1.13".default or true); }
      { "0.1.13".nodrop-union =
        (f.nodrop."0.1.13".nodrop-union or false) ||
        (f.nodrop."0.1.13".use_union or false) ||
        (nodrop."0.1.13"."use_union" or false); }
      { "0.1.13".std =
        (f.nodrop."0.1.13".std or false) ||
        (f.nodrop."0.1.13".default or false) ||
        (nodrop."0.1.13"."default" or false); }
    ];
  }) [];


# end
# num_cpus-1.9.0

  crates.num_cpus."1.9.0" = deps: { features?(features_.num_cpus."1.9.0" deps {}) }: buildRustCrate {
    crateName = "num_cpus";
    version = "1.9.0";
    authors = [ "Sean McArthur <sean@seanmonstar.com>" ];
    sha256 = "0lv81a9sapkprfsi03rag1mygm9qxhdw2qscdvvx2yb62pc54pvi";
    dependencies = mapFeatures features ([
      (crates."libc"."${deps."num_cpus"."1.9.0"."libc"}" deps)
    ]);
  };
  features_.num_cpus."1.9.0" = deps: f: updateFeatures f (rec {
    libc."${deps.num_cpus."1.9.0".libc}".default = true;
    num_cpus."1.9.0".default = (f.num_cpus."1.9.0".default or true);
  }) [
    (features_.libc."${deps."num_cpus"."1.9.0"."libc"}" deps)
  ];


# end
# owning_ref-0.4.0

  crates.owning_ref."0.4.0" = deps: { features?(features_.owning_ref."0.4.0" deps {}) }: buildRustCrate {
    crateName = "owning_ref";
    version = "0.4.0";
    authors = [ "Marvin Löbel <loebel.marvin@gmail.com>" ];
    sha256 = "1m95qpc3hamkw9wlbfzqkzk7h6skyj40zr6sa3ps151slcfnnchm";
    dependencies = mapFeatures features ([
      (crates."stable_deref_trait"."${deps."owning_ref"."0.4.0"."stable_deref_trait"}" deps)
    ]);
  };
  features_.owning_ref."0.4.0" = deps: f: updateFeatures f (rec {
    owning_ref."0.4.0".default = (f.owning_ref."0.4.0".default or true);
    stable_deref_trait."${deps.owning_ref."0.4.0".stable_deref_trait}".default = true;
  }) [
    (features_.stable_deref_trait."${deps."owning_ref"."0.4.0"."stable_deref_trait"}" deps)
  ];


# end
# parking_lot-0.6.4

  crates.parking_lot."0.6.4" = deps: { features?(features_.parking_lot."0.6.4" deps {}) }: buildRustCrate {
    crateName = "parking_lot";
    version = "0.6.4";
    authors = [ "Amanieu d'Antras <amanieu@gmail.com>" ];
    sha256 = "0qwfysx8zfkj72sfcrqvd6pp7lgjmklyixsi3y0g6xjspw876rax";
    dependencies = mapFeatures features ([
      (crates."lock_api"."${deps."parking_lot"."0.6.4"."lock_api"}" deps)
      (crates."parking_lot_core"."${deps."parking_lot"."0.6.4"."parking_lot_core"}" deps)
    ]);
    features = mkFeatures (features."parking_lot"."0.6.4" or {});
  };
  features_.parking_lot."0.6.4" = deps: f: updateFeatures f (rec {
    lock_api = fold recursiveUpdate {} [
      { "${deps.parking_lot."0.6.4".lock_api}"."nightly" =
        (f.lock_api."${deps.parking_lot."0.6.4".lock_api}"."nightly" or false) ||
        (parking_lot."0.6.4"."nightly" or false) ||
        (f."parking_lot"."0.6.4"."nightly" or false); }
      { "${deps.parking_lot."0.6.4".lock_api}"."owning_ref" =
        (f.lock_api."${deps.parking_lot."0.6.4".lock_api}"."owning_ref" or false) ||
        (parking_lot."0.6.4"."owning_ref" or false) ||
        (f."parking_lot"."0.6.4"."owning_ref" or false); }
      { "${deps.parking_lot."0.6.4".lock_api}".default = true; }
    ];
    parking_lot = fold recursiveUpdate {} [
      { "0.6.4".default = (f.parking_lot."0.6.4".default or true); }
      { "0.6.4".owning_ref =
        (f.parking_lot."0.6.4".owning_ref or false) ||
        (f.parking_lot."0.6.4".default or false) ||
        (parking_lot."0.6.4"."default" or false); }
    ];
    parking_lot_core = fold recursiveUpdate {} [
      { "${deps.parking_lot."0.6.4".parking_lot_core}"."deadlock_detection" =
        (f.parking_lot_core."${deps.parking_lot."0.6.4".parking_lot_core}"."deadlock_detection" or false) ||
        (parking_lot."0.6.4"."deadlock_detection" or false) ||
        (f."parking_lot"."0.6.4"."deadlock_detection" or false); }
      { "${deps.parking_lot."0.6.4".parking_lot_core}"."nightly" =
        (f.parking_lot_core."${deps.parking_lot."0.6.4".parking_lot_core}"."nightly" or false) ||
        (parking_lot."0.6.4"."nightly" or false) ||
        (f."parking_lot"."0.6.4"."nightly" or false); }
      { "${deps.parking_lot."0.6.4".parking_lot_core}".default = true; }
    ];
  }) [
    (features_.lock_api."${deps."parking_lot"."0.6.4"."lock_api"}" deps)
    (features_.parking_lot_core."${deps."parking_lot"."0.6.4"."parking_lot_core"}" deps)
  ];


# end
# parking_lot_core-0.3.1

  crates.parking_lot_core."0.3.1" = deps: { features?(features_.parking_lot_core."0.3.1" deps {}) }: buildRustCrate {
    crateName = "parking_lot_core";
    version = "0.3.1";
    authors = [ "Amanieu d'Antras <amanieu@gmail.com>" ];
    sha256 = "0h5p7dys8cx9y6ii4i57ampf7qdr8zmkpn543kd3h7nkhml8bw72";
    dependencies = mapFeatures features ([
      (crates."rand"."${deps."parking_lot_core"."0.3.1"."rand"}" deps)
      (crates."smallvec"."${deps."parking_lot_core"."0.3.1"."smallvec"}" deps)
    ])
      ++ (if (kernel == "linux" || kernel == "darwin") then mapFeatures features ([
      (crates."libc"."${deps."parking_lot_core"."0.3.1"."libc"}" deps)
    ]) else [])
      ++ (if kernel == "windows" then mapFeatures features ([
      (crates."winapi"."${deps."parking_lot_core"."0.3.1"."winapi"}" deps)
    ]) else []);

    buildDependencies = mapFeatures features ([
      (crates."rustc_version"."${deps."parking_lot_core"."0.3.1"."rustc_version"}" deps)
    ]);
    features = mkFeatures (features."parking_lot_core"."0.3.1" or {});
  };
  features_.parking_lot_core."0.3.1" = deps: f: updateFeatures f (rec {
    libc."${deps.parking_lot_core."0.3.1".libc}".default = true;
    parking_lot_core = fold recursiveUpdate {} [
      { "0.3.1".backtrace =
        (f.parking_lot_core."0.3.1".backtrace or false) ||
        (f.parking_lot_core."0.3.1".deadlock_detection or false) ||
        (parking_lot_core."0.3.1"."deadlock_detection" or false); }
      { "0.3.1".default = (f.parking_lot_core."0.3.1".default or true); }
      { "0.3.1".petgraph =
        (f.parking_lot_core."0.3.1".petgraph or false) ||
        (f.parking_lot_core."0.3.1".deadlock_detection or false) ||
        (parking_lot_core."0.3.1"."deadlock_detection" or false); }
      { "0.3.1".thread-id =
        (f.parking_lot_core."0.3.1".thread-id or false) ||
        (f.parking_lot_core."0.3.1".deadlock_detection or false) ||
        (parking_lot_core."0.3.1"."deadlock_detection" or false); }
    ];
    rand."${deps.parking_lot_core."0.3.1".rand}".default = true;
    rustc_version."${deps.parking_lot_core."0.3.1".rustc_version}".default = true;
    smallvec."${deps.parking_lot_core."0.3.1".smallvec}".default = true;
    winapi = fold recursiveUpdate {} [
      { "${deps.parking_lot_core."0.3.1".winapi}"."errhandlingapi" = true; }
      { "${deps.parking_lot_core."0.3.1".winapi}"."handleapi" = true; }
      { "${deps.parking_lot_core."0.3.1".winapi}"."minwindef" = true; }
      { "${deps.parking_lot_core."0.3.1".winapi}"."ntstatus" = true; }
      { "${deps.parking_lot_core."0.3.1".winapi}"."winbase" = true; }
      { "${deps.parking_lot_core."0.3.1".winapi}"."winerror" = true; }
      { "${deps.parking_lot_core."0.3.1".winapi}"."winnt" = true; }
      { "${deps.parking_lot_core."0.3.1".winapi}".default = true; }
    ];
  }) [
    (features_.rand."${deps."parking_lot_core"."0.3.1"."rand"}" deps)
    (features_.smallvec."${deps."parking_lot_core"."0.3.1"."smallvec"}" deps)
    (features_.rustc_version."${deps."parking_lot_core"."0.3.1"."rustc_version"}" deps)
    (features_.libc."${deps."parking_lot_core"."0.3.1"."libc"}" deps)
    (features_.winapi."${deps."parking_lot_core"."0.3.1"."winapi"}" deps)
  ];


# end
# pkg-config-0.3.14

  crates.pkg_config."0.3.14" = deps: { features?(features_.pkg_config."0.3.14" deps {}) }: buildRustCrate {
    crateName = "pkg-config";
    version = "0.3.14";
    authors = [ "Alex Crichton <alex@alexcrichton.com>" ];
    sha256 = "0207fsarrm412j0dh87lfcas72n8mxar7q3mgflsbsrqnb140sv6";
  };
  features_.pkg_config."0.3.14" = deps: f: updateFeatures f (rec {
    pkg_config."0.3.14".default = (f.pkg_config."0.3.14".default or true);
  }) [];


# end
# proc-macro2-0.4.24

  crates.proc_macro2."0.4.24" = deps: { features?(features_.proc_macro2."0.4.24" deps {}) }: buildRustCrate {
    crateName = "proc-macro2";
    version = "0.4.24";
    authors = [ "Alex Crichton <alex@alexcrichton.com>" ];
    sha256 = "0ra2z9j3h0bbfq40p8mfwf28shnbxqryb45pfzg47xaszf85ylv2";
    build = "build.rs";
    dependencies = mapFeatures features ([
      (crates."unicode_xid"."${deps."proc_macro2"."0.4.24"."unicode_xid"}" deps)
    ]);
    features = mkFeatures (features."proc_macro2"."0.4.24" or {});
  };
  features_.proc_macro2."0.4.24" = deps: f: updateFeatures f (rec {
    proc_macro2 = fold recursiveUpdate {} [
      { "0.4.24".default = (f.proc_macro2."0.4.24".default or true); }
      { "0.4.24".proc-macro =
        (f.proc_macro2."0.4.24".proc-macro or false) ||
        (f.proc_macro2."0.4.24".default or false) ||
        (proc_macro2."0.4.24"."default" or false) ||
        (f.proc_macro2."0.4.24".nightly or false) ||
        (proc_macro2."0.4.24"."nightly" or false); }
    ];
    unicode_xid."${deps.proc_macro2."0.4.24".unicode_xid}".default = true;
  }) [
    (features_.unicode_xid."${deps."proc_macro2"."0.4.24"."unicode_xid"}" deps)
  ];


# end
# protobuf-2.0.5

  crates.protobuf."2.0.5" = deps: { features?(features_.protobuf."2.0.5" deps {}) }: buildRustCrate {
    crateName = "protobuf";
    version = "2.0.5";
    authors = [ "Stepan Koltsov <stepan.koltsov@gmail.com>" ];
    sha256 = "1r08fsraq16qbsvgw49yx351i1zwrmaydsvw5jmlpzvqgzchp701";
    dependencies = mapFeatures features ([
]);
    features = mkFeatures (features."protobuf"."2.0.5" or {});
  };
  features_.protobuf."2.0.5" = deps: f: updateFeatures f (rec {
    protobuf = fold recursiveUpdate {} [
      { "2.0.5".bytes =
        (f.protobuf."2.0.5".bytes or false) ||
        (f.protobuf."2.0.5".with-bytes or false) ||
        (protobuf."2.0.5"."with-bytes" or false); }
      { "2.0.5".default = (f.protobuf."2.0.5".default or true); }
    ];
  }) [];


# end
# protobuf-codegen-2.0.5

  crates.protobuf_codegen."2.0.5" = deps: { features?(features_.protobuf_codegen."2.0.5" deps {}) }: buildRustCrate {
    crateName = "protobuf-codegen";
    version = "2.0.5";
    authors = [ "Stepan Koltsov <stepan.koltsov@gmail.com>" ];
    sha256 = "04g1gn8lgyxjb0q5r03krrxi7dmjmsn02kih8f35j0zrsh542zpy";
    crateBin =
      [{  name = "protoc-gen-rust";  path = "src/bin/protoc-gen-rust.rs"; }] ++
      [{  name = "protobuf-bin-gen-rust-do-not-use";  path = "src/bin/protobuf-bin-gen-rust-do-not-use.rs"; }];
    dependencies = mapFeatures features ([
      (crates."protobuf"."${deps."protobuf_codegen"."2.0.5"."protobuf"}" deps)
    ]);
  };
  features_.protobuf_codegen."2.0.5" = deps: f: updateFeatures f (rec {
    protobuf."${deps.protobuf_codegen."2.0.5".protobuf}".default = true;
    protobuf_codegen."2.0.5".default = (f.protobuf_codegen."2.0.5".default or true);
  }) [
    (features_.protobuf."${deps."protobuf_codegen"."2.0.5"."protobuf"}" deps)
  ];


# end
# protoc-2.2.0

  crates.protoc."2.2.0" = deps: { features?(features_.protoc."2.2.0" deps {}) }: buildRustCrate {
    crateName = "protoc";
    version = "2.2.0";
    authors = [ "Stepan Koltsov <stepan.koltsov@gmail.com>" ];
    sha256 = "0ak4gjc4zyhb75cbxkhhvcq6i08x40mkjv82f2i58znqnfzars0z";
    dependencies = mapFeatures features ([
      (crates."log"."${deps."protoc"."2.2.0"."log"}" deps)
    ]);
  };
  features_.protoc."2.2.0" = deps: f: updateFeatures f (rec {
    log."${deps.protoc."2.2.0".log}".default = true;
    protoc."2.2.0".default = (f.protoc."2.2.0".default or true);
  }) [
    (features_.log."${deps."protoc"."2.2.0"."log"}" deps)
  ];


# end
# protoc-grpcio-0.3.1

  crates.protoc_grpcio."0.3.1" = deps: { features?(features_.protoc_grpcio."0.3.1" deps {}) }: buildRustCrate {
    crateName = "protoc-grpcio";
    version = "0.3.1";
    authors = [ "Matt Pelland <matt@pelland.io>" ];
    sha256 = "1dg4vbdbs88gqi8djc78x4rlai4khwm2nvpf2kysrzrsvv2gzzb8";
    dependencies = mapFeatures features ([
      (crates."failure"."${deps."protoc_grpcio"."0.3.1"."failure"}" deps)
      (crates."grpcio_compiler"."${deps."protoc_grpcio"."0.3.1"."grpcio_compiler"}" deps)
      (crates."protobuf"."${deps."protoc_grpcio"."0.3.1"."protobuf"}" deps)
      (crates."protobuf_codegen"."${deps."protoc_grpcio"."0.3.1"."protobuf_codegen"}" deps)
      (crates."protoc"."${deps."protoc_grpcio"."0.3.1"."protoc"}" deps)
      (crates."tempfile"."${deps."protoc_grpcio"."0.3.1"."tempfile"}" deps)
    ]);
  };
  features_.protoc_grpcio."0.3.1" = deps: f: updateFeatures f (rec {
    failure."${deps.protoc_grpcio."0.3.1".failure}".default = true;
    grpcio_compiler."${deps.protoc_grpcio."0.3.1".grpcio_compiler}".default = true;
    protobuf."${deps.protoc_grpcio."0.3.1".protobuf}".default = true;
    protobuf_codegen."${deps.protoc_grpcio."0.3.1".protobuf_codegen}".default = true;
    protoc."${deps.protoc_grpcio."0.3.1".protoc}".default = true;
    protoc_grpcio."0.3.1".default = (f.protoc_grpcio."0.3.1".default or true);
    tempfile."${deps.protoc_grpcio."0.3.1".tempfile}".default = true;
  }) [
    (features_.failure."${deps."protoc_grpcio"."0.3.1"."failure"}" deps)
    (features_.grpcio_compiler."${deps."protoc_grpcio"."0.3.1"."grpcio_compiler"}" deps)
    (features_.protobuf."${deps."protoc_grpcio"."0.3.1"."protobuf"}" deps)
    (features_.protobuf_codegen."${deps."protoc_grpcio"."0.3.1"."protobuf_codegen"}" deps)
    (features_.protoc."${deps."protoc_grpcio"."0.3.1"."protoc"}" deps)
    (features_.tempfile."${deps."protoc_grpcio"."0.3.1"."tempfile"}" deps)
  ];


# end
# quick-error-1.2.2

  crates.quick_error."1.2.2" = deps: { features?(features_.quick_error."1.2.2" deps {}) }: buildRustCrate {
    crateName = "quick-error";
    version = "1.2.2";
    authors = [ "Paul Colomiets <paul@colomiets.name>" "Colin Kiegel <kiegel@gmx.de>" ];
    sha256 = "192a3adc5phgpibgqblsdx1b421l5yg9bjbmv552qqq9f37h60k5";
  };
  features_.quick_error."1.2.2" = deps: f: updateFeatures f (rec {
    quick_error."1.2.2".default = (f.quick_error."1.2.2".default or true);
  }) [];


# end
# quote-0.6.10

  crates.quote."0.6.10" = deps: { features?(features_.quote."0.6.10" deps {}) }: buildRustCrate {
    crateName = "quote";
    version = "0.6.10";
    authors = [ "David Tolnay <dtolnay@gmail.com>" ];
    sha256 = "0q5dlhk9hz795872fsf02vlbazx691393j7q426q590vdqcgj0qx";
    dependencies = mapFeatures features ([
      (crates."proc_macro2"."${deps."quote"."0.6.10"."proc_macro2"}" deps)
    ]);
    features = mkFeatures (features."quote"."0.6.10" or {});
  };
  features_.quote."0.6.10" = deps: f: updateFeatures f (rec {
    proc_macro2 = fold recursiveUpdate {} [
      { "${deps.quote."0.6.10".proc_macro2}"."proc-macro" =
        (f.proc_macro2."${deps.quote."0.6.10".proc_macro2}"."proc-macro" or false) ||
        (quote."0.6.10"."proc-macro" or false) ||
        (f."quote"."0.6.10"."proc-macro" or false); }
      { "${deps.quote."0.6.10".proc_macro2}".default = (f.proc_macro2."${deps.quote."0.6.10".proc_macro2}".default or false); }
    ];
    quote = fold recursiveUpdate {} [
      { "0.6.10".default = (f.quote."0.6.10".default or true); }
      { "0.6.10".proc-macro =
        (f.quote."0.6.10".proc-macro or false) ||
        (f.quote."0.6.10".default or false) ||
        (quote."0.6.10"."default" or false); }
    ];
  }) [
    (features_.proc_macro2."${deps."quote"."0.6.10"."proc_macro2"}" deps)
  ];


# end
# rand-0.5.5

  crates.rand."0.5.5" = deps: { features?(features_.rand."0.5.5" deps {}) }: buildRustCrate {
    crateName = "rand";
    version = "0.5.5";
    authors = [ "The Rust Project Developers" ];
    sha256 = "0d7pnsh57qxhz1ghrzk113ddkn13kf2g758ffnbxq4nhwjfzhlc9";
    dependencies = mapFeatures features ([
      (crates."rand_core"."${deps."rand"."0.5.5"."rand_core"}" deps)
    ])
      ++ (if kernel == "cloudabi" then mapFeatures features ([
    ]
      ++ (if features.rand."0.5.5".cloudabi or false then [ (crates.cloudabi."${deps."rand"."0.5.5".cloudabi}" deps) ] else [])) else [])
      ++ (if kernel == "fuchsia" then mapFeatures features ([
    ]
      ++ (if features.rand."0.5.5".fuchsia-zircon or false then [ (crates.fuchsia_zircon."${deps."rand"."0.5.5".fuchsia_zircon}" deps) ] else [])) else [])
      ++ (if (kernel == "linux" || kernel == "darwin") then mapFeatures features ([
    ]
      ++ (if features.rand."0.5.5".libc or false then [ (crates.libc."${deps."rand"."0.5.5".libc}" deps) ] else [])) else [])
      ++ (if kernel == "windows" then mapFeatures features ([
    ]
      ++ (if features.rand."0.5.5".winapi or false then [ (crates.winapi."${deps."rand"."0.5.5".winapi}" deps) ] else [])) else [])
      ++ (if kernel == "wasm32-unknown-unknown" then mapFeatures features ([
]) else []);
    features = mkFeatures (features."rand"."0.5.5" or {});
  };
  features_.rand."0.5.5" = deps: f: updateFeatures f (rec {
    cloudabi."${deps.rand."0.5.5".cloudabi}".default = true;
    fuchsia_zircon."${deps.rand."0.5.5".fuchsia_zircon}".default = true;
    libc."${deps.rand."0.5.5".libc}".default = true;
    rand = fold recursiveUpdate {} [
      { "0.5.5".alloc =
        (f.rand."0.5.5".alloc or false) ||
        (f.rand."0.5.5".std or false) ||
        (rand."0.5.5"."std" or false); }
      { "0.5.5".cloudabi =
        (f.rand."0.5.5".cloudabi or false) ||
        (f.rand."0.5.5".std or false) ||
        (rand."0.5.5"."std" or false); }
      { "0.5.5".default = (f.rand."0.5.5".default or true); }
      { "0.5.5".fuchsia-zircon =
        (f.rand."0.5.5".fuchsia-zircon or false) ||
        (f.rand."0.5.5".std or false) ||
        (rand."0.5.5"."std" or false); }
      { "0.5.5".i128_support =
        (f.rand."0.5.5".i128_support or false) ||
        (f.rand."0.5.5".nightly or false) ||
        (rand."0.5.5"."nightly" or false); }
      { "0.5.5".libc =
        (f.rand."0.5.5".libc or false) ||
        (f.rand."0.5.5".std or false) ||
        (rand."0.5.5"."std" or false); }
      { "0.5.5".serde =
        (f.rand."0.5.5".serde or false) ||
        (f.rand."0.5.5".serde1 or false) ||
        (rand."0.5.5"."serde1" or false); }
      { "0.5.5".serde_derive =
        (f.rand."0.5.5".serde_derive or false) ||
        (f.rand."0.5.5".serde1 or false) ||
        (rand."0.5.5"."serde1" or false); }
      { "0.5.5".std =
        (f.rand."0.5.5".std or false) ||
        (f.rand."0.5.5".default or false) ||
        (rand."0.5.5"."default" or false); }
      { "0.5.5".winapi =
        (f.rand."0.5.5".winapi or false) ||
        (f.rand."0.5.5".std or false) ||
        (rand."0.5.5"."std" or false); }
    ];
    rand_core = fold recursiveUpdate {} [
      { "${deps.rand."0.5.5".rand_core}"."alloc" =
        (f.rand_core."${deps.rand."0.5.5".rand_core}"."alloc" or false) ||
        (rand."0.5.5"."alloc" or false) ||
        (f."rand"."0.5.5"."alloc" or false); }
      { "${deps.rand."0.5.5".rand_core}"."serde1" =
        (f.rand_core."${deps.rand."0.5.5".rand_core}"."serde1" or false) ||
        (rand."0.5.5"."serde1" or false) ||
        (f."rand"."0.5.5"."serde1" or false); }
      { "${deps.rand."0.5.5".rand_core}"."std" =
        (f.rand_core."${deps.rand."0.5.5".rand_core}"."std" or false) ||
        (rand."0.5.5"."std" or false) ||
        (f."rand"."0.5.5"."std" or false); }
      { "${deps.rand."0.5.5".rand_core}".default = (f.rand_core."${deps.rand."0.5.5".rand_core}".default or false); }
    ];
    winapi = fold recursiveUpdate {} [
      { "${deps.rand."0.5.5".winapi}"."minwindef" = true; }
      { "${deps.rand."0.5.5".winapi}"."ntsecapi" = true; }
      { "${deps.rand."0.5.5".winapi}"."profileapi" = true; }
      { "${deps.rand."0.5.5".winapi}"."winnt" = true; }
      { "${deps.rand."0.5.5".winapi}".default = true; }
    ];
  }) [
    (features_.rand_core."${deps."rand"."0.5.5"."rand_core"}" deps)
    (features_.cloudabi."${deps."rand"."0.5.5"."cloudabi"}" deps)
    (features_.fuchsia_zircon."${deps."rand"."0.5.5"."fuchsia_zircon"}" deps)
    (features_.libc."${deps."rand"."0.5.5"."libc"}" deps)
    (features_.winapi."${deps."rand"."0.5.5"."winapi"}" deps)
  ];


# end
# rand-0.6.1

  crates.rand."0.6.1" = deps: { features?(features_.rand."0.6.1" deps {}) }: buildRustCrate {
    crateName = "rand";
    version = "0.6.1";
    authors = [ "The Rand Project Developers" "The Rust Project Developers" ];
    sha256 = "123s3w165iiifmf475lisqkd0kbr7nwnn3k4b1zg2cwap5v9m9bz";
    build = "build.rs";
    dependencies = mapFeatures features ([
      (crates."rand_chacha"."${deps."rand"."0.6.1"."rand_chacha"}" deps)
      (crates."rand_core"."${deps."rand"."0.6.1"."rand_core"}" deps)
      (crates."rand_hc"."${deps."rand"."0.6.1"."rand_hc"}" deps)
      (crates."rand_isaac"."${deps."rand"."0.6.1"."rand_isaac"}" deps)
      (crates."rand_pcg"."${deps."rand"."0.6.1"."rand_pcg"}" deps)
      (crates."rand_xorshift"."${deps."rand"."0.6.1"."rand_xorshift"}" deps)
    ])
      ++ (if kernel == "cloudabi" then mapFeatures features ([
    ]
      ++ (if features.rand."0.6.1".cloudabi or false then [ (crates.cloudabi."${deps."rand"."0.6.1".cloudabi}" deps) ] else [])) else [])
      ++ (if kernel == "fuchsia" then mapFeatures features ([
    ]
      ++ (if features.rand."0.6.1".fuchsia-zircon or false then [ (crates.fuchsia_zircon."${deps."rand"."0.6.1".fuchsia_zircon}" deps) ] else [])) else [])
      ++ (if (kernel == "linux" || kernel == "darwin") then mapFeatures features ([
    ]
      ++ (if features.rand."0.6.1".libc or false then [ (crates.libc."${deps."rand"."0.6.1".libc}" deps) ] else [])) else [])
      ++ (if kernel == "windows" then mapFeatures features ([
    ]
      ++ (if features.rand."0.6.1".winapi or false then [ (crates.winapi."${deps."rand"."0.6.1".winapi}" deps) ] else [])) else [])
      ++ (if kernel == "wasm32-unknown-unknown" then mapFeatures features ([
]) else []);

    buildDependencies = mapFeatures features ([
      (crates."rustc_version"."${deps."rand"."0.6.1"."rustc_version"}" deps)
    ]);
    features = mkFeatures (features."rand"."0.6.1" or {});
  };
  features_.rand."0.6.1" = deps: f: updateFeatures f (rec {
    cloudabi."${deps.rand."0.6.1".cloudabi}".default = true;
    fuchsia_zircon."${deps.rand."0.6.1".fuchsia_zircon}".default = true;
    libc."${deps.rand."0.6.1".libc}".default = (f.libc."${deps.rand."0.6.1".libc}".default or false);
    rand = fold recursiveUpdate {} [
      { "0.6.1".alloc =
        (f.rand."0.6.1".alloc or false) ||
        (f.rand."0.6.1".std or false) ||
        (rand."0.6.1"."std" or false); }
      { "0.6.1".cloudabi =
        (f.rand."0.6.1".cloudabi or false) ||
        (f.rand."0.6.1".std or false) ||
        (rand."0.6.1"."std" or false); }
      { "0.6.1".default = (f.rand."0.6.1".default or true); }
      { "0.6.1".fuchsia-zircon =
        (f.rand."0.6.1".fuchsia-zircon or false) ||
        (f.rand."0.6.1".std or false) ||
        (rand."0.6.1"."std" or false); }
      { "0.6.1".libc =
        (f.rand."0.6.1".libc or false) ||
        (f.rand."0.6.1".std or false) ||
        (rand."0.6.1"."std" or false); }
      { "0.6.1".packed_simd =
        (f.rand."0.6.1".packed_simd or false) ||
        (f.rand."0.6.1".simd_support or false) ||
        (rand."0.6.1"."simd_support" or false); }
      { "0.6.1".simd_support =
        (f.rand."0.6.1".simd_support or false) ||
        (f.rand."0.6.1".nightly or false) ||
        (rand."0.6.1"."nightly" or false); }
      { "0.6.1".std =
        (f.rand."0.6.1".std or false) ||
        (f.rand."0.6.1".default or false) ||
        (rand."0.6.1"."default" or false); }
      { "0.6.1".winapi =
        (f.rand."0.6.1".winapi or false) ||
        (f.rand."0.6.1".std or false) ||
        (rand."0.6.1"."std" or false); }
    ];
    rand_chacha."${deps.rand."0.6.1".rand_chacha}".default = true;
    rand_core = fold recursiveUpdate {} [
      { "${deps.rand."0.6.1".rand_core}"."alloc" =
        (f.rand_core."${deps.rand."0.6.1".rand_core}"."alloc" or false) ||
        (rand."0.6.1"."alloc" or false) ||
        (f."rand"."0.6.1"."alloc" or false); }
      { "${deps.rand."0.6.1".rand_core}"."serde1" =
        (f.rand_core."${deps.rand."0.6.1".rand_core}"."serde1" or false) ||
        (rand."0.6.1"."serde1" or false) ||
        (f."rand"."0.6.1"."serde1" or false); }
      { "${deps.rand."0.6.1".rand_core}"."std" =
        (f.rand_core."${deps.rand."0.6.1".rand_core}"."std" or false) ||
        (rand."0.6.1"."std" or false) ||
        (f."rand"."0.6.1"."std" or false); }
      { "${deps.rand."0.6.1".rand_core}".default = (f.rand_core."${deps.rand."0.6.1".rand_core}".default or false); }
    ];
    rand_hc."${deps.rand."0.6.1".rand_hc}".default = true;
    rand_isaac = fold recursiveUpdate {} [
      { "${deps.rand."0.6.1".rand_isaac}"."serde1" =
        (f.rand_isaac."${deps.rand."0.6.1".rand_isaac}"."serde1" or false) ||
        (rand."0.6.1"."serde1" or false) ||
        (f."rand"."0.6.1"."serde1" or false); }
      { "${deps.rand."0.6.1".rand_isaac}".default = true; }
    ];
    rand_pcg."${deps.rand."0.6.1".rand_pcg}".default = true;
    rand_xorshift = fold recursiveUpdate {} [
      { "${deps.rand."0.6.1".rand_xorshift}"."serde1" =
        (f.rand_xorshift."${deps.rand."0.6.1".rand_xorshift}"."serde1" or false) ||
        (rand."0.6.1"."serde1" or false) ||
        (f."rand"."0.6.1"."serde1" or false); }
      { "${deps.rand."0.6.1".rand_xorshift}".default = true; }
    ];
    rustc_version."${deps.rand."0.6.1".rustc_version}".default = true;
    winapi = fold recursiveUpdate {} [
      { "${deps.rand."0.6.1".winapi}"."minwindef" = true; }
      { "${deps.rand."0.6.1".winapi}"."ntsecapi" = true; }
      { "${deps.rand."0.6.1".winapi}"."profileapi" = true; }
      { "${deps.rand."0.6.1".winapi}"."winnt" = true; }
      { "${deps.rand."0.6.1".winapi}".default = true; }
    ];
  }) [
    (features_.rand_chacha."${deps."rand"."0.6.1"."rand_chacha"}" deps)
    (features_.rand_core."${deps."rand"."0.6.1"."rand_core"}" deps)
    (features_.rand_hc."${deps."rand"."0.6.1"."rand_hc"}" deps)
    (features_.rand_isaac."${deps."rand"."0.6.1"."rand_isaac"}" deps)
    (features_.rand_pcg."${deps."rand"."0.6.1"."rand_pcg"}" deps)
    (features_.rand_xorshift."${deps."rand"."0.6.1"."rand_xorshift"}" deps)
    (features_.rustc_version."${deps."rand"."0.6.1"."rustc_version"}" deps)
    (features_.cloudabi."${deps."rand"."0.6.1"."cloudabi"}" deps)
    (features_.fuchsia_zircon."${deps."rand"."0.6.1"."fuchsia_zircon"}" deps)
    (features_.libc."${deps."rand"."0.6.1"."libc"}" deps)
    (features_.winapi."${deps."rand"."0.6.1"."winapi"}" deps)
  ];


# end
# rand_chacha-0.1.0

  crates.rand_chacha."0.1.0" = deps: { features?(features_.rand_chacha."0.1.0" deps {}) }: buildRustCrate {
    crateName = "rand_chacha";
    version = "0.1.0";
    authors = [ "The Rand Project Developers" "The Rust Project Developers" ];
    sha256 = "0q5pq34cqv1mnibgzd1cmx9q49vkr2lvalkkvizmlld217jmlqc6";
    build = "build.rs";
    dependencies = mapFeatures features ([
      (crates."rand_core"."${deps."rand_chacha"."0.1.0"."rand_core"}" deps)
    ]);

    buildDependencies = mapFeatures features ([
      (crates."rustc_version"."${deps."rand_chacha"."0.1.0"."rustc_version"}" deps)
    ]);
  };
  features_.rand_chacha."0.1.0" = deps: f: updateFeatures f (rec {
    rand_chacha."0.1.0".default = (f.rand_chacha."0.1.0".default or true);
    rand_core."${deps.rand_chacha."0.1.0".rand_core}".default = (f.rand_core."${deps.rand_chacha."0.1.0".rand_core}".default or false);
    rustc_version."${deps.rand_chacha."0.1.0".rustc_version}".default = true;
  }) [
    (features_.rand_core."${deps."rand_chacha"."0.1.0"."rand_core"}" deps)
    (features_.rustc_version."${deps."rand_chacha"."0.1.0"."rustc_version"}" deps)
  ];


# end
# rand_core-0.2.2

  crates.rand_core."0.2.2" = deps: { features?(features_.rand_core."0.2.2" deps {}) }: buildRustCrate {
    crateName = "rand_core";
    version = "0.2.2";
    authors = [ "The Rust Project Developers" ];
    sha256 = "1cxnaxmsirz2wxsajsjkd1wk6lqfqbcprqkha4bq3didznrl22sc";
    dependencies = mapFeatures features ([
      (crates."rand_core"."${deps."rand_core"."0.2.2"."rand_core"}" deps)
    ]);
    features = mkFeatures (features."rand_core"."0.2.2" or {});
  };
  features_.rand_core."0.2.2" = deps: f: updateFeatures f (rec {
    rand_core = fold recursiveUpdate {} [
      { "${deps.rand_core."0.2.2".rand_core}"."alloc" =
        (f.rand_core."${deps.rand_core."0.2.2".rand_core}"."alloc" or false) ||
        (rand_core."0.2.2"."alloc" or false) ||
        (f."rand_core"."0.2.2"."alloc" or false); }
      { "${deps.rand_core."0.2.2".rand_core}"."serde1" =
        (f.rand_core."${deps.rand_core."0.2.2".rand_core}"."serde1" or false) ||
        (rand_core."0.2.2"."serde1" or false) ||
        (f."rand_core"."0.2.2"."serde1" or false); }
      { "${deps.rand_core."0.2.2".rand_core}"."std" =
        (f.rand_core."${deps.rand_core."0.2.2".rand_core}"."std" or false) ||
        (rand_core."0.2.2"."std" or false) ||
        (f."rand_core"."0.2.2"."std" or false); }
      { "${deps.rand_core."0.2.2".rand_core}".default = (f.rand_core."${deps.rand_core."0.2.2".rand_core}".default or false); }
      { "0.2.2".default = (f.rand_core."0.2.2".default or true); }
    ];
  }) [
    (features_.rand_core."${deps."rand_core"."0.2.2"."rand_core"}" deps)
  ];


# end
# rand_core-0.3.0

  crates.rand_core."0.3.0" = deps: { features?(features_.rand_core."0.3.0" deps {}) }: buildRustCrate {
    crateName = "rand_core";
    version = "0.3.0";
    authors = [ "The Rust Project Developers" ];
    sha256 = "1vafw316apjys9va3j987s02djhqp7y21v671v3ix0p5j9bjq339";
    dependencies = mapFeatures features ([
]);
    features = mkFeatures (features."rand_core"."0.3.0" or {});
  };
  features_.rand_core."0.3.0" = deps: f: updateFeatures f (rec {
    rand_core = fold recursiveUpdate {} [
      { "0.3.0".alloc =
        (f.rand_core."0.3.0".alloc or false) ||
        (f.rand_core."0.3.0".std or false) ||
        (rand_core."0.3.0"."std" or false); }
      { "0.3.0".default = (f.rand_core."0.3.0".default or true); }
      { "0.3.0".serde =
        (f.rand_core."0.3.0".serde or false) ||
        (f.rand_core."0.3.0".serde1 or false) ||
        (rand_core."0.3.0"."serde1" or false); }
      { "0.3.0".serde_derive =
        (f.rand_core."0.3.0".serde_derive or false) ||
        (f.rand_core."0.3.0".serde1 or false) ||
        (rand_core."0.3.0"."serde1" or false); }
      { "0.3.0".std =
        (f.rand_core."0.3.0".std or false) ||
        (f.rand_core."0.3.0".default or false) ||
        (rand_core."0.3.0"."default" or false); }
    ];
  }) [];


# end
# rand_hc-0.1.0

  crates.rand_hc."0.1.0" = deps: { features?(features_.rand_hc."0.1.0" deps {}) }: buildRustCrate {
    crateName = "rand_hc";
    version = "0.1.0";
    authors = [ "The Rand Project Developers" ];
    sha256 = "05agb75j87yp7y1zk8yf7bpm66hc0673r3dlypn0kazynr6fdgkz";
    dependencies = mapFeatures features ([
      (crates."rand_core"."${deps."rand_hc"."0.1.0"."rand_core"}" deps)
    ]);
  };
  features_.rand_hc."0.1.0" = deps: f: updateFeatures f (rec {
    rand_core."${deps.rand_hc."0.1.0".rand_core}".default = (f.rand_core."${deps.rand_hc."0.1.0".rand_core}".default or false);
    rand_hc."0.1.0".default = (f.rand_hc."0.1.0".default or true);
  }) [
    (features_.rand_core."${deps."rand_hc"."0.1.0"."rand_core"}" deps)
  ];


# end
# rand_isaac-0.1.1

  crates.rand_isaac."0.1.1" = deps: { features?(features_.rand_isaac."0.1.1" deps {}) }: buildRustCrate {
    crateName = "rand_isaac";
    version = "0.1.1";
    authors = [ "The Rand Project Developers" "The Rust Project Developers" ];
    sha256 = "10hhdh5b5sa03s6b63y9bafm956jwilx41s71jbrzl63ccx8lxdq";
    dependencies = mapFeatures features ([
      (crates."rand_core"."${deps."rand_isaac"."0.1.1"."rand_core"}" deps)
    ]);
    features = mkFeatures (features."rand_isaac"."0.1.1" or {});
  };
  features_.rand_isaac."0.1.1" = deps: f: updateFeatures f (rec {
    rand_core = fold recursiveUpdate {} [
      { "${deps.rand_isaac."0.1.1".rand_core}"."serde1" =
        (f.rand_core."${deps.rand_isaac."0.1.1".rand_core}"."serde1" or false) ||
        (rand_isaac."0.1.1"."serde1" or false) ||
        (f."rand_isaac"."0.1.1"."serde1" or false); }
      { "${deps.rand_isaac."0.1.1".rand_core}".default = (f.rand_core."${deps.rand_isaac."0.1.1".rand_core}".default or false); }
    ];
    rand_isaac = fold recursiveUpdate {} [
      { "0.1.1".default = (f.rand_isaac."0.1.1".default or true); }
      { "0.1.1".serde =
        (f.rand_isaac."0.1.1".serde or false) ||
        (f.rand_isaac."0.1.1".serde1 or false) ||
        (rand_isaac."0.1.1"."serde1" or false); }
      { "0.1.1".serde_derive =
        (f.rand_isaac."0.1.1".serde_derive or false) ||
        (f.rand_isaac."0.1.1".serde1 or false) ||
        (rand_isaac."0.1.1"."serde1" or false); }
    ];
  }) [
    (features_.rand_core."${deps."rand_isaac"."0.1.1"."rand_core"}" deps)
  ];


# end
# rand_pcg-0.1.1

  crates.rand_pcg."0.1.1" = deps: { features?(features_.rand_pcg."0.1.1" deps {}) }: buildRustCrate {
    crateName = "rand_pcg";
    version = "0.1.1";
    authors = [ "The Rand Project Developers" ];
    sha256 = "0x6pzldj0c8c7gmr67ni5i7w2f7n7idvs3ckx0fc3wkhwl7wrbza";
    build = "build.rs";
    dependencies = mapFeatures features ([
      (crates."rand_core"."${deps."rand_pcg"."0.1.1"."rand_core"}" deps)
    ]);

    buildDependencies = mapFeatures features ([
      (crates."rustc_version"."${deps."rand_pcg"."0.1.1"."rustc_version"}" deps)
    ]);
    features = mkFeatures (features."rand_pcg"."0.1.1" or {});
  };
  features_.rand_pcg."0.1.1" = deps: f: updateFeatures f (rec {
    rand_core."${deps.rand_pcg."0.1.1".rand_core}".default = (f.rand_core."${deps.rand_pcg."0.1.1".rand_core}".default or false);
    rand_pcg = fold recursiveUpdate {} [
      { "0.1.1".default = (f.rand_pcg."0.1.1".default or true); }
      { "0.1.1".serde =
        (f.rand_pcg."0.1.1".serde or false) ||
        (f.rand_pcg."0.1.1".serde1 or false) ||
        (rand_pcg."0.1.1"."serde1" or false); }
      { "0.1.1".serde_derive =
        (f.rand_pcg."0.1.1".serde_derive or false) ||
        (f.rand_pcg."0.1.1".serde1 or false) ||
        (rand_pcg."0.1.1"."serde1" or false); }
    ];
    rustc_version."${deps.rand_pcg."0.1.1".rustc_version}".default = true;
  }) [
    (features_.rand_core."${deps."rand_pcg"."0.1.1"."rand_core"}" deps)
    (features_.rustc_version."${deps."rand_pcg"."0.1.1"."rustc_version"}" deps)
  ];


# end
# rand_xorshift-0.1.0

  crates.rand_xorshift."0.1.0" = deps: { features?(features_.rand_xorshift."0.1.0" deps {}) }: buildRustCrate {
    crateName = "rand_xorshift";
    version = "0.1.0";
    authors = [ "The Rand Project Developers" "The Rust Project Developers" ];
    sha256 = "063vxb678ki8gq4rx9w7yg5f9i29ig1zwykl67mfsxn0kxlkv2ih";
    dependencies = mapFeatures features ([
      (crates."rand_core"."${deps."rand_xorshift"."0.1.0"."rand_core"}" deps)
    ]);
    features = mkFeatures (features."rand_xorshift"."0.1.0" or {});
  };
  features_.rand_xorshift."0.1.0" = deps: f: updateFeatures f (rec {
    rand_core."${deps.rand_xorshift."0.1.0".rand_core}".default = (f.rand_core."${deps.rand_xorshift."0.1.0".rand_core}".default or false);
    rand_xorshift = fold recursiveUpdate {} [
      { "0.1.0".default = (f.rand_xorshift."0.1.0".default or true); }
      { "0.1.0".serde =
        (f.rand_xorshift."0.1.0".serde or false) ||
        (f.rand_xorshift."0.1.0".serde1 or false) ||
        (rand_xorshift."0.1.0"."serde1" or false); }
      { "0.1.0".serde_derive =
        (f.rand_xorshift."0.1.0".serde_derive or false) ||
        (f.rand_xorshift."0.1.0".serde1 or false) ||
        (rand_xorshift."0.1.0"."serde1" or false); }
    ];
  }) [
    (features_.rand_core."${deps."rand_xorshift"."0.1.0"."rand_core"}" deps)
  ];


# end
# redox_syscall-0.1.44

  crates.redox_syscall."0.1.44" = deps: { features?(features_.redox_syscall."0.1.44" deps {}) }: buildRustCrate {
    crateName = "redox_syscall";
    version = "0.1.44";
    authors = [ "Jeremy Soller <jackpot51@gmail.com>" ];
    sha256 = "1scnkyq2wlms5cmarw0jgqckj7sl9llb7ammmmxhlm328v9jamiy";
    libName = "syscall";
  };
  features_.redox_syscall."0.1.44" = deps: f: updateFeatures f (rec {
    redox_syscall."0.1.44".default = (f.redox_syscall."0.1.44".default or true);
  }) [];


# end
# redox_termios-0.1.1

  crates.redox_termios."0.1.1" = deps: { features?(features_.redox_termios."0.1.1" deps {}) }: buildRustCrate {
    crateName = "redox_termios";
    version = "0.1.1";
    authors = [ "Jeremy Soller <jackpot51@gmail.com>" ];
    sha256 = "04s6yyzjca552hdaqlvqhp3vw0zqbc304md5czyd3axh56iry8wh";
    libPath = "src/lib.rs";
    dependencies = mapFeatures features ([
      (crates."redox_syscall"."${deps."redox_termios"."0.1.1"."redox_syscall"}" deps)
    ]);
  };
  features_.redox_termios."0.1.1" = deps: f: updateFeatures f (rec {
    redox_syscall."${deps.redox_termios."0.1.1".redox_syscall}".default = true;
    redox_termios."0.1.1".default = (f.redox_termios."0.1.1".default or true);
  }) [
    (features_.redox_syscall."${deps."redox_termios"."0.1.1"."redox_syscall"}" deps)
  ];


# end
# regex-1.1.0

  crates.regex."1.1.0" = deps: { features?(features_.regex."1.1.0" deps {}) }: buildRustCrate {
    crateName = "regex";
    version = "1.1.0";
    authors = [ "The Rust Project Developers" ];
    sha256 = "1myzfgs1yp6vs2rxyg6arn6ab05j6c2m922w3b4iv6zix1rl7z0n";
    dependencies = mapFeatures features ([
      (crates."aho_corasick"."${deps."regex"."1.1.0"."aho_corasick"}" deps)
      (crates."memchr"."${deps."regex"."1.1.0"."memchr"}" deps)
      (crates."regex_syntax"."${deps."regex"."1.1.0"."regex_syntax"}" deps)
      (crates."thread_local"."${deps."regex"."1.1.0"."thread_local"}" deps)
      (crates."utf8_ranges"."${deps."regex"."1.1.0"."utf8_ranges"}" deps)
    ]);
    features = mkFeatures (features."regex"."1.1.0" or {});
  };
  features_.regex."1.1.0" = deps: f: updateFeatures f (rec {
    aho_corasick."${deps.regex."1.1.0".aho_corasick}".default = true;
    memchr."${deps.regex."1.1.0".memchr}".default = true;
    regex = fold recursiveUpdate {} [
      { "1.1.0".default = (f.regex."1.1.0".default or true); }
      { "1.1.0".pattern =
        (f.regex."1.1.0".pattern or false) ||
        (f.regex."1.1.0".unstable or false) ||
        (regex."1.1.0"."unstable" or false); }
      { "1.1.0".use_std =
        (f.regex."1.1.0".use_std or false) ||
        (f.regex."1.1.0".default or false) ||
        (regex."1.1.0"."default" or false); }
    ];
    regex_syntax."${deps.regex."1.1.0".regex_syntax}".default = true;
    thread_local."${deps.regex."1.1.0".thread_local}".default = true;
    utf8_ranges."${deps.regex."1.1.0".utf8_ranges}".default = true;
  }) [
    (features_.aho_corasick."${deps."regex"."1.1.0"."aho_corasick"}" deps)
    (features_.memchr."${deps."regex"."1.1.0"."memchr"}" deps)
    (features_.regex_syntax."${deps."regex"."1.1.0"."regex_syntax"}" deps)
    (features_.thread_local."${deps."regex"."1.1.0"."thread_local"}" deps)
    (features_.utf8_ranges."${deps."regex"."1.1.0"."utf8_ranges"}" deps)
  ];


# end
# regex-syntax-0.6.4

  crates.regex_syntax."0.6.4" = deps: { features?(features_.regex_syntax."0.6.4" deps {}) }: buildRustCrate {
    crateName = "regex-syntax";
    version = "0.6.4";
    authors = [ "The Rust Project Developers" ];
    sha256 = "073qklf4dfq00jxj919y4abnnh8vwn42x1bms82634sfb9s47pfc";
    dependencies = mapFeatures features ([
      (crates."ucd_util"."${deps."regex_syntax"."0.6.4"."ucd_util"}" deps)
    ]);
  };
  features_.regex_syntax."0.6.4" = deps: f: updateFeatures f (rec {
    regex_syntax."0.6.4".default = (f.regex_syntax."0.6.4".default or true);
    ucd_util."${deps.regex_syntax."0.6.4".ucd_util}".default = true;
  }) [
    (features_.ucd_util."${deps."regex_syntax"."0.6.4"."ucd_util"}" deps)
  ];


# end
# remove_dir_all-0.5.1

  crates.remove_dir_all."0.5.1" = deps: { features?(features_.remove_dir_all."0.5.1" deps {}) }: buildRustCrate {
    crateName = "remove_dir_all";
    version = "0.5.1";
    authors = [ "Aaronepower <theaaronepower@gmail.com>" ];
    sha256 = "1chx3yvfbj46xjz4bzsvps208l46hfbcy0sm98gpiya454n4rrl7";
    dependencies = (if kernel == "windows" then mapFeatures features ([
      (crates."winapi"."${deps."remove_dir_all"."0.5.1"."winapi"}" deps)
    ]) else []);
  };
  features_.remove_dir_all."0.5.1" = deps: f: updateFeatures f (rec {
    remove_dir_all."0.5.1".default = (f.remove_dir_all."0.5.1".default or true);
    winapi = fold recursiveUpdate {} [
      { "${deps.remove_dir_all."0.5.1".winapi}"."errhandlingapi" = true; }
      { "${deps.remove_dir_all."0.5.1".winapi}"."fileapi" = true; }
      { "${deps.remove_dir_all."0.5.1".winapi}"."std" = true; }
      { "${deps.remove_dir_all."0.5.1".winapi}"."winbase" = true; }
      { "${deps.remove_dir_all."0.5.1".winapi}"."winerror" = true; }
      { "${deps.remove_dir_all."0.5.1".winapi}".default = true; }
    ];
  }) [
    (features_.winapi."${deps."remove_dir_all"."0.5.1"."winapi"}" deps)
  ];


# end
# rustc-demangle-0.1.11

  crates.rustc_demangle."0.1.11" = deps: { features?(features_.rustc_demangle."0.1.11" deps {}) }: buildRustCrate {
    crateName = "rustc-demangle";
    version = "0.1.11";
    authors = [ "Alex Crichton <alex@alexcrichton.com>" ];
    sha256 = "1l886vrs030wb1mfcrw2lqwbxbfc9scwkfhidwfnvj9ljrk2qsrc";
  };
  features_.rustc_demangle."0.1.11" = deps: f: updateFeatures f (rec {
    rustc_demangle."0.1.11".default = (f.rustc_demangle."0.1.11".default or true);
  }) [];


# end
# rustc_version-0.2.3

  crates.rustc_version."0.2.3" = deps: { features?(features_.rustc_version."0.2.3" deps {}) }: buildRustCrate {
    crateName = "rustc_version";
    version = "0.2.3";
    authors = [ "Marvin Löbel <loebel.marvin@gmail.com>" ];
    sha256 = "0rgwzbgs3i9fqjm1p4ra3n7frafmpwl29c8lw85kv1rxn7n2zaa7";
    dependencies = mapFeatures features ([
      (crates."semver"."${deps."rustc_version"."0.2.3"."semver"}" deps)
    ]);
  };
  features_.rustc_version."0.2.3" = deps: f: updateFeatures f (rec {
    rustc_version."0.2.3".default = (f.rustc_version."0.2.3".default or true);
    semver."${deps.rustc_version."0.2.3".semver}".default = true;
  }) [
    (features_.semver."${deps."rustc_version"."0.2.3"."semver"}" deps)
  ];


# end
# scopeguard-0.3.3

  crates.scopeguard."0.3.3" = deps: { features?(features_.scopeguard."0.3.3" deps {}) }: buildRustCrate {
    crateName = "scopeguard";
    version = "0.3.3";
    authors = [ "bluss" ];
    sha256 = "0i1l013csrqzfz6c68pr5pi01hg5v5yahq8fsdmaxy6p8ygsjf3r";
    features = mkFeatures (features."scopeguard"."0.3.3" or {});
  };
  features_.scopeguard."0.3.3" = deps: f: updateFeatures f (rec {
    scopeguard = fold recursiveUpdate {} [
      { "0.3.3".default = (f.scopeguard."0.3.3".default or true); }
      { "0.3.3".use_std =
        (f.scopeguard."0.3.3".use_std or false) ||
        (f.scopeguard."0.3.3".default or false) ||
        (scopeguard."0.3.3"."default" or false); }
    ];
  }) [];


# end
# semver-0.9.0

  crates.semver."0.9.0" = deps: { features?(features_.semver."0.9.0" deps {}) }: buildRustCrate {
    crateName = "semver";
    version = "0.9.0";
    authors = [ "Steve Klabnik <steve@steveklabnik.com>" "The Rust Project Developers" ];
    sha256 = "0azak2lb2wc36s3x15az886kck7rpnksrw14lalm157rg9sc9z63";
    dependencies = mapFeatures features ([
      (crates."semver_parser"."${deps."semver"."0.9.0"."semver_parser"}" deps)
    ]);
    features = mkFeatures (features."semver"."0.9.0" or {});
  };
  features_.semver."0.9.0" = deps: f: updateFeatures f (rec {
    semver = fold recursiveUpdate {} [
      { "0.9.0".default = (f.semver."0.9.0".default or true); }
      { "0.9.0".serde =
        (f.semver."0.9.0".serde or false) ||
        (f.semver."0.9.0".ci or false) ||
        (semver."0.9.0"."ci" or false); }
    ];
    semver_parser."${deps.semver."0.9.0".semver_parser}".default = true;
  }) [
    (features_.semver_parser."${deps."semver"."0.9.0"."semver_parser"}" deps)
  ];


# end
# semver-parser-0.7.0

  crates.semver_parser."0.7.0" = deps: { features?(features_.semver_parser."0.7.0" deps {}) }: buildRustCrate {
    crateName = "semver-parser";
    version = "0.7.0";
    authors = [ "Steve Klabnik <steve@steveklabnik.com>" ];
    sha256 = "1da66c8413yakx0y15k8c055yna5lyb6fr0fw9318kdwkrk5k12h";
  };
  features_.semver_parser."0.7.0" = deps: f: updateFeatures f (rec {
    semver_parser."0.7.0".default = (f.semver_parser."0.7.0".default or true);
  }) [];


# end
# serde-1.0.82

  crates.serde."1.0.82" = deps: { features?(features_.serde."1.0.82" deps {}) }: buildRustCrate {
    crateName = "serde";
    version = "1.0.82";
    authors = [ "Erick Tryzelaar <erick.tryzelaar@gmail.com>" "David Tolnay <dtolnay@gmail.com>" ];
    sha256 = "0wi4lar06p506w34rnan7a7h03i0badx753016gxacvsg8pd8wmp";
    build = "build.rs";
    dependencies = mapFeatures features ([
]);
    features = mkFeatures (features."serde"."1.0.82" or {});
  };
  features_.serde."1.0.82" = deps: f: updateFeatures f (rec {
    serde = fold recursiveUpdate {} [
      { "1.0.82".default = (f.serde."1.0.82".default or true); }
      { "1.0.82".serde_derive =
        (f.serde."1.0.82".serde_derive or false) ||
        (f.serde."1.0.82".derive or false) ||
        (serde."1.0.82"."derive" or false); }
      { "1.0.82".std =
        (f.serde."1.0.82".std or false) ||
        (f.serde."1.0.82".default or false) ||
        (serde."1.0.82"."default" or false); }
      { "1.0.82".unstable =
        (f.serde."1.0.82".unstable or false) ||
        (f.serde."1.0.82".alloc or false) ||
        (serde."1.0.82"."alloc" or false); }
    ];
  }) [];


# end
# serde_derive-1.0.82

  crates.serde_derive."1.0.82" = deps: { features?(features_.serde_derive."1.0.82" deps {}) }: buildRustCrate {
    crateName = "serde_derive";
    version = "1.0.82";
    authors = [ "Erick Tryzelaar <erick.tryzelaar@gmail.com>" "David Tolnay <dtolnay@gmail.com>" ];
    sha256 = "0wd8hhgljjqf90425rak89j2k80wfrqqln9mndgajvdmxfmg5j4n";
    procMacro = true;
    dependencies = mapFeatures features ([
      (crates."proc_macro2"."${deps."serde_derive"."1.0.82"."proc_macro2"}" deps)
      (crates."quote"."${deps."serde_derive"."1.0.82"."quote"}" deps)
      (crates."syn"."${deps."serde_derive"."1.0.82"."syn"}" deps)
    ]);
    features = mkFeatures (features."serde_derive"."1.0.82" or {});
  };
  features_.serde_derive."1.0.82" = deps: f: updateFeatures f (rec {
    proc_macro2."${deps.serde_derive."1.0.82".proc_macro2}".default = true;
    quote."${deps.serde_derive."1.0.82".quote}".default = true;
    serde_derive."1.0.82".default = (f.serde_derive."1.0.82".default or true);
    syn = fold recursiveUpdate {} [
      { "${deps.serde_derive."1.0.82".syn}"."visit" = true; }
      { "${deps.serde_derive."1.0.82".syn}".default = true; }
    ];
  }) [
    (features_.proc_macro2."${deps."serde_derive"."1.0.82"."proc_macro2"}" deps)
    (features_.quote."${deps."serde_derive"."1.0.82"."quote"}" deps)
    (features_.syn."${deps."serde_derive"."1.0.82"."syn"}" deps)
  ];


# end
# serde_yaml-0.8.8

  crates.serde_yaml."0.8.8" = deps: { features?(features_.serde_yaml."0.8.8" deps {}) }: buildRustCrate {
    crateName = "serde_yaml";
    version = "0.8.8";
    authors = [ "David Tolnay <dtolnay@gmail.com>" ];
    sha256 = "0gpydv1vvfnnzb842wp881rmzjc4lgz3saxvci8v8kiawnb78394";
    dependencies = mapFeatures features ([
      (crates."dtoa"."${deps."serde_yaml"."0.8.8"."dtoa"}" deps)
      (crates."linked_hash_map"."${deps."serde_yaml"."0.8.8"."linked_hash_map"}" deps)
      (crates."serde"."${deps."serde_yaml"."0.8.8"."serde"}" deps)
      (crates."yaml_rust"."${deps."serde_yaml"."0.8.8"."yaml_rust"}" deps)
    ]);
  };
  features_.serde_yaml."0.8.8" = deps: f: updateFeatures f (rec {
    dtoa."${deps.serde_yaml."0.8.8".dtoa}".default = true;
    linked_hash_map."${deps.serde_yaml."0.8.8".linked_hash_map}".default = true;
    serde."${deps.serde_yaml."0.8.8".serde}".default = true;
    serde_yaml."0.8.8".default = (f.serde_yaml."0.8.8".default or true);
    yaml_rust."${deps.serde_yaml."0.8.8".yaml_rust}".default = true;
  }) [
    (features_.dtoa."${deps."serde_yaml"."0.8.8"."dtoa"}" deps)
    (features_.linked_hash_map."${deps."serde_yaml"."0.8.8"."linked_hash_map"}" deps)
    (features_.serde."${deps."serde_yaml"."0.8.8"."serde"}" deps)
    (features_.yaml_rust."${deps."serde_yaml"."0.8.8"."yaml_rust"}" deps)
  ];


# end
# signal-hook-0.1.6

  crates.signal_hook."0.1.6" = deps: { features?(features_.signal_hook."0.1.6" deps {}) }: buildRustCrate {
    crateName = "signal-hook";
    version = "0.1.6";
    authors = [ "Michal 'vorner' Vaner <vorner@vorner.cz>" ];
    sha256 = "110mpvffirz22q3iyfvww4q1nwsbsqbp6azqcnp5xvz95gxjfbaq";
    dependencies = mapFeatures features ([
      (crates."arc_swap"."${deps."signal_hook"."0.1.6"."arc_swap"}" deps)
      (crates."libc"."${deps."signal_hook"."0.1.6"."libc"}" deps)
    ]);
    features = mkFeatures (features."signal_hook"."0.1.6" or {});
  };
  features_.signal_hook."0.1.6" = deps: f: updateFeatures f (rec {
    arc_swap."${deps.signal_hook."0.1.6".arc_swap}".default = true;
    libc."${deps.signal_hook."0.1.6".libc}".default = true;
    signal_hook = fold recursiveUpdate {} [
      { "0.1.6".default = (f.signal_hook."0.1.6".default or true); }
      { "0.1.6".futures =
        (f.signal_hook."0.1.6".futures or false) ||
        (f.signal_hook."0.1.6".tokio-support or false) ||
        (signal_hook."0.1.6"."tokio-support" or false); }
      { "0.1.6".mio =
        (f.signal_hook."0.1.6".mio or false) ||
        (f.signal_hook."0.1.6".mio-support or false) ||
        (signal_hook."0.1.6"."mio-support" or false); }
      { "0.1.6".mio-support =
        (f.signal_hook."0.1.6".mio-support or false) ||
        (f.signal_hook."0.1.6".tokio-support or false) ||
        (signal_hook."0.1.6"."tokio-support" or false); }
      { "0.1.6".mio-uds =
        (f.signal_hook."0.1.6".mio-uds or false) ||
        (f.signal_hook."0.1.6".mio-support or false) ||
        (signal_hook."0.1.6"."mio-support" or false); }
      { "0.1.6".tokio-reactor =
        (f.signal_hook."0.1.6".tokio-reactor or false) ||
        (f.signal_hook."0.1.6".tokio-support or false) ||
        (signal_hook."0.1.6"."tokio-support" or false); }
    ];
  }) [
    (features_.arc_swap."${deps."signal_hook"."0.1.6"."arc_swap"}" deps)
    (features_.libc."${deps."signal_hook"."0.1.6"."libc"}" deps)
  ];


# end
# slab-0.4.1

  crates.slab."0.4.1" = deps: { features?(features_.slab."0.4.1" deps {}) }: buildRustCrate {
    crateName = "slab";
    version = "0.4.1";
    authors = [ "Carl Lerche <me@carllerche.com>" ];
    sha256 = "0njmznhcjp4aiznybxm7wacnb4q49ch98wizyf4lpn3rg6sjrak4";
  };
  features_.slab."0.4.1" = deps: f: updateFeatures f (rec {
    slab."0.4.1".default = (f.slab."0.4.1".default or true);
  }) [];


# end
# smallvec-0.6.7

  crates.smallvec."0.6.7" = deps: { features?(features_.smallvec."0.6.7" deps {}) }: buildRustCrate {
    crateName = "smallvec";
    version = "0.6.7";
    authors = [ "Simon Sapin <simon.sapin@exyr.org>" ];
    sha256 = "08ql2yi7ry08cqjl9n6vpb6x6zgqzwllzzk9pxj1143xwg503qcx";
    libPath = "lib.rs";
    dependencies = mapFeatures features ([
      (crates."unreachable"."${deps."smallvec"."0.6.7"."unreachable"}" deps)
    ]);
    features = mkFeatures (features."smallvec"."0.6.7" or {});
  };
  features_.smallvec."0.6.7" = deps: f: updateFeatures f (rec {
    smallvec = fold recursiveUpdate {} [
      { "0.6.7".default = (f.smallvec."0.6.7".default or true); }
      { "0.6.7".std =
        (f.smallvec."0.6.7".std or false) ||
        (f.smallvec."0.6.7".default or false) ||
        (smallvec."0.6.7"."default" or false); }
    ];
    unreachable."${deps.smallvec."0.6.7".unreachable}".default = true;
  }) [
    (features_.unreachable."${deps."smallvec"."0.6.7"."unreachable"}" deps)
  ];


# end
# socket2-0.3.8

  crates.socket2."0.3.8" = deps: { features?(features_.socket2."0.3.8" deps {}) }: buildRustCrate {
    crateName = "socket2";
    version = "0.3.8";
    authors = [ "Alex Crichton <alex@alexcrichton.com>" ];
    sha256 = "1a71m20jxmf9kqqinksphc7wj1j7q672q29cpza7p9siyzyfx598";
    dependencies = (if (kernel == "linux" || kernel == "darwin") || kernel == "redox" then mapFeatures features ([
      (crates."cfg_if"."${deps."socket2"."0.3.8"."cfg_if"}" deps)
      (crates."libc"."${deps."socket2"."0.3.8"."libc"}" deps)
    ]) else [])
      ++ (if kernel == "redox" then mapFeatures features ([
      (crates."redox_syscall"."${deps."socket2"."0.3.8"."redox_syscall"}" deps)
    ]) else [])
      ++ (if kernel == "windows" then mapFeatures features ([
      (crates."winapi"."${deps."socket2"."0.3.8"."winapi"}" deps)
    ]) else []);
    features = mkFeatures (features."socket2"."0.3.8" or {});
  };
  features_.socket2."0.3.8" = deps: f: updateFeatures f (rec {
    cfg_if."${deps.socket2."0.3.8".cfg_if}".default = true;
    libc."${deps.socket2."0.3.8".libc}".default = true;
    redox_syscall."${deps.socket2."0.3.8".redox_syscall}".default = true;
    socket2."0.3.8".default = (f.socket2."0.3.8".default or true);
    winapi = fold recursiveUpdate {} [
      { "${deps.socket2."0.3.8".winapi}"."handleapi" = true; }
      { "${deps.socket2."0.3.8".winapi}"."minwindef" = true; }
      { "${deps.socket2."0.3.8".winapi}"."ws2def" = true; }
      { "${deps.socket2."0.3.8".winapi}"."ws2ipdef" = true; }
      { "${deps.socket2."0.3.8".winapi}"."ws2tcpip" = true; }
      { "${deps.socket2."0.3.8".winapi}".default = true; }
    ];
  }) [
    (features_.cfg_if."${deps."socket2"."0.3.8"."cfg_if"}" deps)
    (features_.libc."${deps."socket2"."0.3.8"."libc"}" deps)
    (features_.redox_syscall."${deps."socket2"."0.3.8"."redox_syscall"}" deps)
    (features_.winapi."${deps."socket2"."0.3.8"."winapi"}" deps)
  ];


# end
# stable_deref_trait-1.1.1

  crates.stable_deref_trait."1.1.1" = deps: { features?(features_.stable_deref_trait."1.1.1" deps {}) }: buildRustCrate {
    crateName = "stable_deref_trait";
    version = "1.1.1";
    authors = [ "Robert Grosse <n210241048576@gmail.com>" ];
    sha256 = "1xy9slzslrzr31nlnw52sl1d820b09y61b7f13lqgsn8n7y0l4g8";
    features = mkFeatures (features."stable_deref_trait"."1.1.1" or {});
  };
  features_.stable_deref_trait."1.1.1" = deps: f: updateFeatures f (rec {
    stable_deref_trait = fold recursiveUpdate {} [
      { "1.1.1".default = (f.stable_deref_trait."1.1.1".default or true); }
      { "1.1.1".std =
        (f.stable_deref_trait."1.1.1".std or false) ||
        (f.stable_deref_trait."1.1.1".default or false) ||
        (stable_deref_trait."1.1.1"."default" or false); }
    ];
  }) [];


# end
# syn-0.15.23

  crates.syn."0.15.23" = deps: { features?(features_.syn."0.15.23" deps {}) }: buildRustCrate {
    crateName = "syn";
    version = "0.15.23";
    authors = [ "David Tolnay <dtolnay@gmail.com>" ];
    sha256 = "0ybqj4vv16s16lshn464rx24v95yx4s41jq5ir004n62zksz77a1";
    dependencies = mapFeatures features ([
      (crates."proc_macro2"."${deps."syn"."0.15.23"."proc_macro2"}" deps)
      (crates."unicode_xid"."${deps."syn"."0.15.23"."unicode_xid"}" deps)
    ]
      ++ (if features.syn."0.15.23".quote or false then [ (crates.quote."${deps."syn"."0.15.23".quote}" deps) ] else []));
    features = mkFeatures (features."syn"."0.15.23" or {});
  };
  features_.syn."0.15.23" = deps: f: updateFeatures f (rec {
    proc_macro2 = fold recursiveUpdate {} [
      { "${deps.syn."0.15.23".proc_macro2}"."proc-macro" =
        (f.proc_macro2."${deps.syn."0.15.23".proc_macro2}"."proc-macro" or false) ||
        (syn."0.15.23"."proc-macro" or false) ||
        (f."syn"."0.15.23"."proc-macro" or false); }
      { "${deps.syn."0.15.23".proc_macro2}".default = (f.proc_macro2."${deps.syn."0.15.23".proc_macro2}".default or false); }
    ];
    quote = fold recursiveUpdate {} [
      { "${deps.syn."0.15.23".quote}"."proc-macro" =
        (f.quote."${deps.syn."0.15.23".quote}"."proc-macro" or false) ||
        (syn."0.15.23"."proc-macro" or false) ||
        (f."syn"."0.15.23"."proc-macro" or false); }
      { "${deps.syn."0.15.23".quote}".default = (f.quote."${deps.syn."0.15.23".quote}".default or false); }
    ];
    syn = fold recursiveUpdate {} [
      { "0.15.23".clone-impls =
        (f.syn."0.15.23".clone-impls or false) ||
        (f.syn."0.15.23".default or false) ||
        (syn."0.15.23"."default" or false); }
      { "0.15.23".default = (f.syn."0.15.23".default or true); }
      { "0.15.23".derive =
        (f.syn."0.15.23".derive or false) ||
        (f.syn."0.15.23".default or false) ||
        (syn."0.15.23"."default" or false); }
      { "0.15.23".parsing =
        (f.syn."0.15.23".parsing or false) ||
        (f.syn."0.15.23".default or false) ||
        (syn."0.15.23"."default" or false); }
      { "0.15.23".printing =
        (f.syn."0.15.23".printing or false) ||
        (f.syn."0.15.23".default or false) ||
        (syn."0.15.23"."default" or false); }
      { "0.15.23".proc-macro =
        (f.syn."0.15.23".proc-macro or false) ||
        (f.syn."0.15.23".default or false) ||
        (syn."0.15.23"."default" or false); }
      { "0.15.23".quote =
        (f.syn."0.15.23".quote or false) ||
        (f.syn."0.15.23".printing or false) ||
        (syn."0.15.23"."printing" or false); }
    ];
    unicode_xid."${deps.syn."0.15.23".unicode_xid}".default = true;
  }) [
    (features_.proc_macro2."${deps."syn"."0.15.23"."proc_macro2"}" deps)
    (features_.quote."${deps."syn"."0.15.23"."quote"}" deps)
    (features_.unicode_xid."${deps."syn"."0.15.23"."unicode_xid"}" deps)
  ];


# end
# synstructure-0.10.1

  crates.synstructure."0.10.1" = deps: { features?(features_.synstructure."0.10.1" deps {}) }: buildRustCrate {
    crateName = "synstructure";
    version = "0.10.1";
    authors = [ "Nika Layzell <nika@thelayzells.com>" ];
    sha256 = "0mx2vwd0d0f7hanz15nkp0ikkfjsx9rfkph7pynxyfbj45ank4g3";
    dependencies = mapFeatures features ([
      (crates."proc_macro2"."${deps."synstructure"."0.10.1"."proc_macro2"}" deps)
      (crates."quote"."${deps."synstructure"."0.10.1"."quote"}" deps)
      (crates."syn"."${deps."synstructure"."0.10.1"."syn"}" deps)
      (crates."unicode_xid"."${deps."synstructure"."0.10.1"."unicode_xid"}" deps)
    ]);
    features = mkFeatures (features."synstructure"."0.10.1" or {});
  };
  features_.synstructure."0.10.1" = deps: f: updateFeatures f (rec {
    proc_macro2."${deps.synstructure."0.10.1".proc_macro2}".default = true;
    quote."${deps.synstructure."0.10.1".quote}".default = true;
    syn = fold recursiveUpdate {} [
      { "${deps.synstructure."0.10.1".syn}"."extra-traits" = true; }
      { "${deps.synstructure."0.10.1".syn}"."visit" = true; }
      { "${deps.synstructure."0.10.1".syn}".default = true; }
    ];
    synstructure."0.10.1".default = (f.synstructure."0.10.1".default or true);
    unicode_xid."${deps.synstructure."0.10.1".unicode_xid}".default = true;
  }) [
    (features_.proc_macro2."${deps."synstructure"."0.10.1"."proc_macro2"}" deps)
    (features_.quote."${deps."synstructure"."0.10.1"."quote"}" deps)
    (features_.syn."${deps."synstructure"."0.10.1"."syn"}" deps)
    (features_.unicode_xid."${deps."synstructure"."0.10.1"."unicode_xid"}" deps)
  ];


# end
# tempfile-3.0.5

  crates.tempfile."3.0.5" = deps: { features?(features_.tempfile."3.0.5" deps {}) }: buildRustCrate {
    crateName = "tempfile";
    version = "3.0.5";
    authors = [ "Steven Allen <steven@stebalien.com>" "The Rust Project Developers" "Ashley Mannix <ashleymannix@live.com.au>" "Jason White <jasonaw0@gmail.com>" ];
    sha256 = "11xc89br78ypk4g27v51lm2baz57gp6v555i3sxhrj9qlas2iqfl";
    dependencies = mapFeatures features ([
      (crates."cfg_if"."${deps."tempfile"."3.0.5"."cfg_if"}" deps)
      (crates."rand"."${deps."tempfile"."3.0.5"."rand"}" deps)
      (crates."remove_dir_all"."${deps."tempfile"."3.0.5"."remove_dir_all"}" deps)
    ])
      ++ (if kernel == "redox" then mapFeatures features ([
      (crates."redox_syscall"."${deps."tempfile"."3.0.5"."redox_syscall"}" deps)
    ]) else [])
      ++ (if (kernel == "linux" || kernel == "darwin") then mapFeatures features ([
      (crates."libc"."${deps."tempfile"."3.0.5"."libc"}" deps)
    ]) else [])
      ++ (if kernel == "windows" then mapFeatures features ([
      (crates."winapi"."${deps."tempfile"."3.0.5"."winapi"}" deps)
    ]) else []);
  };
  features_.tempfile."3.0.5" = deps: f: updateFeatures f (rec {
    cfg_if."${deps.tempfile."3.0.5".cfg_if}".default = true;
    libc."${deps.tempfile."3.0.5".libc}".default = true;
    rand."${deps.tempfile."3.0.5".rand}".default = true;
    redox_syscall."${deps.tempfile."3.0.5".redox_syscall}".default = true;
    remove_dir_all."${deps.tempfile."3.0.5".remove_dir_all}".default = true;
    tempfile."3.0.5".default = (f.tempfile."3.0.5".default or true);
    winapi = fold recursiveUpdate {} [
      { "${deps.tempfile."3.0.5".winapi}"."fileapi" = true; }
      { "${deps.tempfile."3.0.5".winapi}"."handleapi" = true; }
      { "${deps.tempfile."3.0.5".winapi}"."winbase" = true; }
      { "${deps.tempfile."3.0.5".winapi}".default = true; }
    ];
  }) [
    (features_.cfg_if."${deps."tempfile"."3.0.5"."cfg_if"}" deps)
    (features_.rand."${deps."tempfile"."3.0.5"."rand"}" deps)
    (features_.remove_dir_all."${deps."tempfile"."3.0.5"."remove_dir_all"}" deps)
    (features_.redox_syscall."${deps."tempfile"."3.0.5"."redox_syscall"}" deps)
    (features_.libc."${deps."tempfile"."3.0.5"."libc"}" deps)
    (features_.winapi."${deps."tempfile"."3.0.5"."winapi"}" deps)
  ];


# end
# termcolor-1.0.4

  crates.termcolor."1.0.4" = deps: { features?(features_.termcolor."1.0.4" deps {}) }: buildRustCrate {
    crateName = "termcolor";
    version = "1.0.4";
    authors = [ "Andrew Gallant <jamslam@gmail.com>" ];
    sha256 = "0xydrjc0bxg08llcbcmkka29szdrfklk4vh6l6mdd67ajifqw1mv";
    dependencies = (if kernel == "windows" then mapFeatures features ([
      (crates."wincolor"."${deps."termcolor"."1.0.4"."wincolor"}" deps)
    ]) else []);
  };
  features_.termcolor."1.0.4" = deps: f: updateFeatures f (rec {
    termcolor."1.0.4".default = (f.termcolor."1.0.4".default or true);
    wincolor."${deps.termcolor."1.0.4".wincolor}".default = true;
  }) [
    (features_.wincolor."${deps."termcolor"."1.0.4"."wincolor"}" deps)
  ];


# end
# termion-1.5.1

  crates.termion."1.5.1" = deps: { features?(features_.termion."1.5.1" deps {}) }: buildRustCrate {
    crateName = "termion";
    version = "1.5.1";
    authors = [ "ticki <Ticki@users.noreply.github.com>" "gycos <alexandre.bury@gmail.com>" "IGI-111 <igi-111@protonmail.com>" ];
    sha256 = "02gq4vd8iws1f3gjrgrgpajsk2bk43nds5acbbb4s8dvrdvr8nf1";
    dependencies = (if !(kernel == "redox") then mapFeatures features ([
      (crates."libc"."${deps."termion"."1.5.1"."libc"}" deps)
    ]) else [])
      ++ (if kernel == "redox" then mapFeatures features ([
      (crates."redox_syscall"."${deps."termion"."1.5.1"."redox_syscall"}" deps)
      (crates."redox_termios"."${deps."termion"."1.5.1"."redox_termios"}" deps)
    ]) else []);
  };
  features_.termion."1.5.1" = deps: f: updateFeatures f (rec {
    libc."${deps.termion."1.5.1".libc}".default = true;
    redox_syscall."${deps.termion."1.5.1".redox_syscall}".default = true;
    redox_termios."${deps.termion."1.5.1".redox_termios}".default = true;
    termion."1.5.1".default = (f.termion."1.5.1".default or true);
  }) [
    (features_.libc."${deps."termion"."1.5.1"."libc"}" deps)
    (features_.redox_syscall."${deps."termion"."1.5.1"."redox_syscall"}" deps)
    (features_.redox_termios."${deps."termion"."1.5.1"."redox_termios"}" deps)
  ];


# end
# thread_local-0.3.6

  crates.thread_local."0.3.6" = deps: { features?(features_.thread_local."0.3.6" deps {}) }: buildRustCrate {
    crateName = "thread_local";
    version = "0.3.6";
    authors = [ "Amanieu d'Antras <amanieu@gmail.com>" ];
    sha256 = "02rksdwjmz2pw9bmgbb4c0bgkbq5z6nvg510sq1s6y2j1gam0c7i";
    dependencies = mapFeatures features ([
      (crates."lazy_static"."${deps."thread_local"."0.3.6"."lazy_static"}" deps)
    ]);
  };
  features_.thread_local."0.3.6" = deps: f: updateFeatures f (rec {
    lazy_static."${deps.thread_local."0.3.6".lazy_static}".default = true;
    thread_local."0.3.6".default = (f.thread_local."0.3.6".default or true);
  }) [
    (features_.lazy_static."${deps."thread_local"."0.3.6"."lazy_static"}" deps)
  ];


# end
# tokio-0.1.13

  crates.tokio."0.1.13" = deps: { features?(features_.tokio."0.1.13" deps {}) }: buildRustCrate {
    crateName = "tokio";
    version = "0.1.13";
    authors = [ "Carl Lerche <me@carllerche.com>" ];
    sha256 = "0jm7qky8f39ya6kbdl1m38s5vlih40w41v6bizdrva0n695cmqf2";
    dependencies = mapFeatures features ([
      (crates."bytes"."${deps."tokio"."0.1.13"."bytes"}" deps)
      (crates."futures"."${deps."tokio"."0.1.13"."futures"}" deps)
      (crates."mio"."${deps."tokio"."0.1.13"."mio"}" deps)
      (crates."num_cpus"."${deps."tokio"."0.1.13"."num_cpus"}" deps)
      (crates."tokio_codec"."${deps."tokio"."0.1.13"."tokio_codec"}" deps)
      (crates."tokio_current_thread"."${deps."tokio"."0.1.13"."tokio_current_thread"}" deps)
      (crates."tokio_executor"."${deps."tokio"."0.1.13"."tokio_executor"}" deps)
      (crates."tokio_fs"."${deps."tokio"."0.1.13"."tokio_fs"}" deps)
      (crates."tokio_io"."${deps."tokio"."0.1.13"."tokio_io"}" deps)
      (crates."tokio_reactor"."${deps."tokio"."0.1.13"."tokio_reactor"}" deps)
      (crates."tokio_tcp"."${deps."tokio"."0.1.13"."tokio_tcp"}" deps)
      (crates."tokio_threadpool"."${deps."tokio"."0.1.13"."tokio_threadpool"}" deps)
      (crates."tokio_timer"."${deps."tokio"."0.1.13"."tokio_timer"}" deps)
      (crates."tokio_udp"."${deps."tokio"."0.1.13"."tokio_udp"}" deps)
    ])
      ++ (if (kernel == "linux" || kernel == "darwin") then mapFeatures features ([
      (crates."tokio_uds"."${deps."tokio"."0.1.13"."tokio_uds"}" deps)
    ]) else []);
    features = mkFeatures (features."tokio"."0.1.13" or {});
  };
  features_.tokio."0.1.13" = deps: f: updateFeatures f (rec {
    bytes."${deps.tokio."0.1.13".bytes}".default = true;
    futures."${deps.tokio."0.1.13".futures}".default = true;
    mio."${deps.tokio."0.1.13".mio}".default = true;
    num_cpus."${deps.tokio."0.1.13".num_cpus}".default = true;
    tokio."0.1.13".default = (f.tokio."0.1.13".default or true);
    tokio_codec."${deps.tokio."0.1.13".tokio_codec}".default = true;
    tokio_current_thread."${deps.tokio."0.1.13".tokio_current_thread}".default = true;
    tokio_executor."${deps.tokio."0.1.13".tokio_executor}".default = true;
    tokio_fs."${deps.tokio."0.1.13".tokio_fs}".default = true;
    tokio_io."${deps.tokio."0.1.13".tokio_io}".default = true;
    tokio_reactor."${deps.tokio."0.1.13".tokio_reactor}".default = true;
    tokio_tcp."${deps.tokio."0.1.13".tokio_tcp}".default = true;
    tokio_threadpool."${deps.tokio."0.1.13".tokio_threadpool}".default = true;
    tokio_timer."${deps.tokio."0.1.13".tokio_timer}".default = true;
    tokio_udp."${deps.tokio."0.1.13".tokio_udp}".default = true;
    tokio_uds."${deps.tokio."0.1.13".tokio_uds}".default = true;
  }) [
    (features_.bytes."${deps."tokio"."0.1.13"."bytes"}" deps)
    (features_.futures."${deps."tokio"."0.1.13"."futures"}" deps)
    (features_.mio."${deps."tokio"."0.1.13"."mio"}" deps)
    (features_.num_cpus."${deps."tokio"."0.1.13"."num_cpus"}" deps)
    (features_.tokio_codec."${deps."tokio"."0.1.13"."tokio_codec"}" deps)
    (features_.tokio_current_thread."${deps."tokio"."0.1.13"."tokio_current_thread"}" deps)
    (features_.tokio_executor."${deps."tokio"."0.1.13"."tokio_executor"}" deps)
    (features_.tokio_fs."${deps."tokio"."0.1.13"."tokio_fs"}" deps)
    (features_.tokio_io."${deps."tokio"."0.1.13"."tokio_io"}" deps)
    (features_.tokio_reactor."${deps."tokio"."0.1.13"."tokio_reactor"}" deps)
    (features_.tokio_tcp."${deps."tokio"."0.1.13"."tokio_tcp"}" deps)
    (features_.tokio_threadpool."${deps."tokio"."0.1.13"."tokio_threadpool"}" deps)
    (features_.tokio_timer."${deps."tokio"."0.1.13"."tokio_timer"}" deps)
    (features_.tokio_udp."${deps."tokio"."0.1.13"."tokio_udp"}" deps)
    (features_.tokio_uds."${deps."tokio"."0.1.13"."tokio_uds"}" deps)
  ];


# end
# tokio-codec-0.1.1

  crates.tokio_codec."0.1.1" = deps: { features?(features_.tokio_codec."0.1.1" deps {}) }: buildRustCrate {
    crateName = "tokio-codec";
    version = "0.1.1";
    authors = [ "Carl Lerche <me@carllerche.com>" "Bryan Burgers <bryan@burgers.io>" ];
    sha256 = "0jc9lik540zyj4chbygg1rjh37m3zax8pd4bwcrwjmi1v56qwi4h";
    dependencies = mapFeatures features ([
      (crates."bytes"."${deps."tokio_codec"."0.1.1"."bytes"}" deps)
      (crates."futures"."${deps."tokio_codec"."0.1.1"."futures"}" deps)
      (crates."tokio_io"."${deps."tokio_codec"."0.1.1"."tokio_io"}" deps)
    ]);
  };
  features_.tokio_codec."0.1.1" = deps: f: updateFeatures f (rec {
    bytes."${deps.tokio_codec."0.1.1".bytes}".default = true;
    futures."${deps.tokio_codec."0.1.1".futures}".default = true;
    tokio_codec."0.1.1".default = (f.tokio_codec."0.1.1".default or true);
    tokio_io."${deps.tokio_codec."0.1.1".tokio_io}".default = true;
  }) [
    (features_.bytes."${deps."tokio_codec"."0.1.1"."bytes"}" deps)
    (features_.futures."${deps."tokio_codec"."0.1.1"."futures"}" deps)
    (features_.tokio_io."${deps."tokio_codec"."0.1.1"."tokio_io"}" deps)
  ];


# end
# tokio-current-thread-0.1.4

  crates.tokio_current_thread."0.1.4" = deps: { features?(features_.tokio_current_thread."0.1.4" deps {}) }: buildRustCrate {
    crateName = "tokio-current-thread";
    version = "0.1.4";
    authors = [ "Carl Lerche <me@carllerche.com>" ];
    sha256 = "1c92j6pwb7xq4pl9wg2xh4ngms0n59mf575h4x6mlp1jlj3sn2vb";
    dependencies = mapFeatures features ([
      (crates."futures"."${deps."tokio_current_thread"."0.1.4"."futures"}" deps)
      (crates."tokio_executor"."${deps."tokio_current_thread"."0.1.4"."tokio_executor"}" deps)
    ]);
  };
  features_.tokio_current_thread."0.1.4" = deps: f: updateFeatures f (rec {
    futures."${deps.tokio_current_thread."0.1.4".futures}".default = true;
    tokio_current_thread."0.1.4".default = (f.tokio_current_thread."0.1.4".default or true);
    tokio_executor."${deps.tokio_current_thread."0.1.4".tokio_executor}".default = true;
  }) [
    (features_.futures."${deps."tokio_current_thread"."0.1.4"."futures"}" deps)
    (features_.tokio_executor."${deps."tokio_current_thread"."0.1.4"."tokio_executor"}" deps)
  ];


# end
# tokio-executor-0.1.5

  crates.tokio_executor."0.1.5" = deps: { features?(features_.tokio_executor."0.1.5" deps {}) }: buildRustCrate {
    crateName = "tokio-executor";
    version = "0.1.5";
    authors = [ "Carl Lerche <me@carllerche.com>" ];
    sha256 = "15j2ybs8w38gncgbxkvp2qsp6wl62ibi3rns0vlwggx7svmx4bf3";
    dependencies = mapFeatures features ([
      (crates."futures"."${deps."tokio_executor"."0.1.5"."futures"}" deps)
    ]);
  };
  features_.tokio_executor."0.1.5" = deps: f: updateFeatures f (rec {
    futures."${deps.tokio_executor."0.1.5".futures}".default = true;
    tokio_executor."0.1.5".default = (f.tokio_executor."0.1.5".default or true);
  }) [
    (features_.futures."${deps."tokio_executor"."0.1.5"."futures"}" deps)
  ];


# end
# tokio-fs-0.1.4

  crates.tokio_fs."0.1.4" = deps: { features?(features_.tokio_fs."0.1.4" deps {}) }: buildRustCrate {
    crateName = "tokio-fs";
    version = "0.1.4";
    authors = [ "Carl Lerche <me@carllerche.com>" ];
    sha256 = "05bpc1p1apb4jfw18i84agwwar57zn07d7smqvslpzagd9b3sd31";
    dependencies = mapFeatures features ([
      (crates."futures"."${deps."tokio_fs"."0.1.4"."futures"}" deps)
      (crates."tokio_io"."${deps."tokio_fs"."0.1.4"."tokio_io"}" deps)
      (crates."tokio_threadpool"."${deps."tokio_fs"."0.1.4"."tokio_threadpool"}" deps)
    ]);
  };
  features_.tokio_fs."0.1.4" = deps: f: updateFeatures f (rec {
    futures."${deps.tokio_fs."0.1.4".futures}".default = true;
    tokio_fs."0.1.4".default = (f.tokio_fs."0.1.4".default or true);
    tokio_io."${deps.tokio_fs."0.1.4".tokio_io}".default = true;
    tokio_threadpool."${deps.tokio_fs."0.1.4".tokio_threadpool}".default = true;
  }) [
    (features_.futures."${deps."tokio_fs"."0.1.4"."futures"}" deps)
    (features_.tokio_io."${deps."tokio_fs"."0.1.4"."tokio_io"}" deps)
    (features_.tokio_threadpool."${deps."tokio_fs"."0.1.4"."tokio_threadpool"}" deps)
  ];


# end
# tokio-io-0.1.10

  crates.tokio_io."0.1.10" = deps: { features?(features_.tokio_io."0.1.10" deps {}) }: buildRustCrate {
    crateName = "tokio-io";
    version = "0.1.10";
    authors = [ "Carl Lerche <me@carllerche.com>" ];
    sha256 = "14d65rqa5rb2msgkz2xn40cavs4m7f4qyi7vnfv98v7f10l9wlay";
    dependencies = mapFeatures features ([
      (crates."bytes"."${deps."tokio_io"."0.1.10"."bytes"}" deps)
      (crates."futures"."${deps."tokio_io"."0.1.10"."futures"}" deps)
      (crates."log"."${deps."tokio_io"."0.1.10"."log"}" deps)
    ]);
  };
  features_.tokio_io."0.1.10" = deps: f: updateFeatures f (rec {
    bytes."${deps.tokio_io."0.1.10".bytes}".default = true;
    futures."${deps.tokio_io."0.1.10".futures}".default = true;
    log."${deps.tokio_io."0.1.10".log}".default = true;
    tokio_io."0.1.10".default = (f.tokio_io."0.1.10".default or true);
  }) [
    (features_.bytes."${deps."tokio_io"."0.1.10"."bytes"}" deps)
    (features_.futures."${deps."tokio_io"."0.1.10"."futures"}" deps)
    (features_.log."${deps."tokio_io"."0.1.10"."log"}" deps)
  ];


# end
# tokio-process-0.2.3

  crates.tokio_process."0.2.3" = deps: { features?(features_.tokio_process."0.2.3" deps {}) }: buildRustCrate {
    crateName = "tokio-process";
    version = "0.2.3";
    authors = [ "Alex Crichton <alex@alexcrichton.com>" ];
    sha256 = "0jxzkxmg3jxg1gm2q7snv8cwdibynhlbn619pz5k6qf9dq0qg0m3";
    dependencies = mapFeatures features ([
      (crates."futures"."${deps."tokio_process"."0.2.3"."futures"}" deps)
      (crates."mio"."${deps."tokio_process"."0.2.3"."mio"}" deps)
      (crates."tokio_io"."${deps."tokio_process"."0.2.3"."tokio_io"}" deps)
      (crates."tokio_reactor"."${deps."tokio_process"."0.2.3"."tokio_reactor"}" deps)
    ])
      ++ (if (kernel == "linux" || kernel == "darwin") then mapFeatures features ([
      (crates."libc"."${deps."tokio_process"."0.2.3"."libc"}" deps)
      (crates."tokio_signal"."${deps."tokio_process"."0.2.3"."tokio_signal"}" deps)
    ]) else [])
      ++ (if kernel == "windows" then mapFeatures features ([
      (crates."mio_named_pipes"."${deps."tokio_process"."0.2.3"."mio_named_pipes"}" deps)
      (crates."winapi"."${deps."tokio_process"."0.2.3"."winapi"}" deps)
    ]) else []);
  };
  features_.tokio_process."0.2.3" = deps: f: updateFeatures f (rec {
    futures."${deps.tokio_process."0.2.3".futures}".default = true;
    libc."${deps.tokio_process."0.2.3".libc}".default = true;
    mio."${deps.tokio_process."0.2.3".mio}".default = true;
    mio_named_pipes."${deps.tokio_process."0.2.3".mio_named_pipes}".default = true;
    tokio_io."${deps.tokio_process."0.2.3".tokio_io}".default = true;
    tokio_process."0.2.3".default = (f.tokio_process."0.2.3".default or true);
    tokio_reactor."${deps.tokio_process."0.2.3".tokio_reactor}".default = true;
    tokio_signal."${deps.tokio_process."0.2.3".tokio_signal}".default = true;
    winapi = fold recursiveUpdate {} [
      { "${deps.tokio_process."0.2.3".winapi}"."handleapi" = true; }
      { "${deps.tokio_process."0.2.3".winapi}"."minwindef" = true; }
      { "${deps.tokio_process."0.2.3".winapi}"."processthreadsapi" = true; }
      { "${deps.tokio_process."0.2.3".winapi}"."synchapi" = true; }
      { "${deps.tokio_process."0.2.3".winapi}"."threadpoollegacyapiset" = true; }
      { "${deps.tokio_process."0.2.3".winapi}"."winbase" = true; }
      { "${deps.tokio_process."0.2.3".winapi}"."winerror" = true; }
      { "${deps.tokio_process."0.2.3".winapi}"."winnt" = true; }
      { "${deps.tokio_process."0.2.3".winapi}".default = true; }
    ];
  }) [
    (features_.futures."${deps."tokio_process"."0.2.3"."futures"}" deps)
    (features_.mio."${deps."tokio_process"."0.2.3"."mio"}" deps)
    (features_.tokio_io."${deps."tokio_process"."0.2.3"."tokio_io"}" deps)
    (features_.tokio_reactor."${deps."tokio_process"."0.2.3"."tokio_reactor"}" deps)
    (features_.libc."${deps."tokio_process"."0.2.3"."libc"}" deps)
    (features_.tokio_signal."${deps."tokio_process"."0.2.3"."tokio_signal"}" deps)
    (features_.mio_named_pipes."${deps."tokio_process"."0.2.3"."mio_named_pipes"}" deps)
    (features_.winapi."${deps."tokio_process"."0.2.3"."winapi"}" deps)
  ];


# end
# tokio-reactor-0.1.7

  crates.tokio_reactor."0.1.7" = deps: { features?(features_.tokio_reactor."0.1.7" deps {}) }: buildRustCrate {
    crateName = "tokio-reactor";
    version = "0.1.7";
    authors = [ "Carl Lerche <me@carllerche.com>" ];
    sha256 = "1ssrc6gic43lachv7jk97jxzw609sgcsrkwi7chf96sn7nqrhj0z";
    dependencies = mapFeatures features ([
      (crates."crossbeam_utils"."${deps."tokio_reactor"."0.1.7"."crossbeam_utils"}" deps)
      (crates."futures"."${deps."tokio_reactor"."0.1.7"."futures"}" deps)
      (crates."lazy_static"."${deps."tokio_reactor"."0.1.7"."lazy_static"}" deps)
      (crates."log"."${deps."tokio_reactor"."0.1.7"."log"}" deps)
      (crates."mio"."${deps."tokio_reactor"."0.1.7"."mio"}" deps)
      (crates."num_cpus"."${deps."tokio_reactor"."0.1.7"."num_cpus"}" deps)
      (crates."parking_lot"."${deps."tokio_reactor"."0.1.7"."parking_lot"}" deps)
      (crates."slab"."${deps."tokio_reactor"."0.1.7"."slab"}" deps)
      (crates."tokio_executor"."${deps."tokio_reactor"."0.1.7"."tokio_executor"}" deps)
      (crates."tokio_io"."${deps."tokio_reactor"."0.1.7"."tokio_io"}" deps)
    ]);
  };
  features_.tokio_reactor."0.1.7" = deps: f: updateFeatures f (rec {
    crossbeam_utils."${deps.tokio_reactor."0.1.7".crossbeam_utils}".default = true;
    futures."${deps.tokio_reactor."0.1.7".futures}".default = true;
    lazy_static."${deps.tokio_reactor."0.1.7".lazy_static}".default = true;
    log."${deps.tokio_reactor."0.1.7".log}".default = true;
    mio."${deps.tokio_reactor."0.1.7".mio}".default = true;
    num_cpus."${deps.tokio_reactor."0.1.7".num_cpus}".default = true;
    parking_lot."${deps.tokio_reactor."0.1.7".parking_lot}".default = true;
    slab."${deps.tokio_reactor."0.1.7".slab}".default = true;
    tokio_executor."${deps.tokio_reactor."0.1.7".tokio_executor}".default = true;
    tokio_io."${deps.tokio_reactor."0.1.7".tokio_io}".default = true;
    tokio_reactor."0.1.7".default = (f.tokio_reactor."0.1.7".default or true);
  }) [
    (features_.crossbeam_utils."${deps."tokio_reactor"."0.1.7"."crossbeam_utils"}" deps)
    (features_.futures."${deps."tokio_reactor"."0.1.7"."futures"}" deps)
    (features_.lazy_static."${deps."tokio_reactor"."0.1.7"."lazy_static"}" deps)
    (features_.log."${deps."tokio_reactor"."0.1.7"."log"}" deps)
    (features_.mio."${deps."tokio_reactor"."0.1.7"."mio"}" deps)
    (features_.num_cpus."${deps."tokio_reactor"."0.1.7"."num_cpus"}" deps)
    (features_.parking_lot."${deps."tokio_reactor"."0.1.7"."parking_lot"}" deps)
    (features_.slab."${deps."tokio_reactor"."0.1.7"."slab"}" deps)
    (features_.tokio_executor."${deps."tokio_reactor"."0.1.7"."tokio_executor"}" deps)
    (features_.tokio_io."${deps."tokio_reactor"."0.1.7"."tokio_io"}" deps)
  ];


# end
# tokio-signal-0.2.7

  crates.tokio_signal."0.2.7" = deps: { features?(features_.tokio_signal."0.2.7" deps {}) }: buildRustCrate {
    crateName = "tokio-signal";
    version = "0.2.7";
    authors = [ "Alex Crichton <alex@alexcrichton.com>" ];
    sha256 = "14fkmzjsqrk2k1f0hay1qf09nz2l4f8xvr8m2vgmlg867fjbvg32";
    dependencies = mapFeatures features ([
      (crates."futures"."${deps."tokio_signal"."0.2.7"."futures"}" deps)
      (crates."mio"."${deps."tokio_signal"."0.2.7"."mio"}" deps)
      (crates."tokio_executor"."${deps."tokio_signal"."0.2.7"."tokio_executor"}" deps)
      (crates."tokio_io"."${deps."tokio_signal"."0.2.7"."tokio_io"}" deps)
      (crates."tokio_reactor"."${deps."tokio_signal"."0.2.7"."tokio_reactor"}" deps)
    ])
      ++ (if (kernel == "linux" || kernel == "darwin") then mapFeatures features ([
      (crates."libc"."${deps."tokio_signal"."0.2.7"."libc"}" deps)
      (crates."mio_uds"."${deps."tokio_signal"."0.2.7"."mio_uds"}" deps)
      (crates."signal_hook"."${deps."tokio_signal"."0.2.7"."signal_hook"}" deps)
    ]) else [])
      ++ (if kernel == "windows" then mapFeatures features ([
      (crates."winapi"."${deps."tokio_signal"."0.2.7"."winapi"}" deps)
    ]) else []);
  };
  features_.tokio_signal."0.2.7" = deps: f: updateFeatures f (rec {
    futures."${deps.tokio_signal."0.2.7".futures}".default = true;
    libc."${deps.tokio_signal."0.2.7".libc}".default = true;
    mio."${deps.tokio_signal."0.2.7".mio}".default = true;
    mio_uds."${deps.tokio_signal."0.2.7".mio_uds}".default = true;
    signal_hook."${deps.tokio_signal."0.2.7".signal_hook}".default = true;
    tokio_executor."${deps.tokio_signal."0.2.7".tokio_executor}".default = true;
    tokio_io."${deps.tokio_signal."0.2.7".tokio_io}".default = true;
    tokio_reactor."${deps.tokio_signal."0.2.7".tokio_reactor}".default = true;
    tokio_signal."0.2.7".default = (f.tokio_signal."0.2.7".default or true);
    winapi = fold recursiveUpdate {} [
      { "${deps.tokio_signal."0.2.7".winapi}"."minwindef" = true; }
      { "${deps.tokio_signal."0.2.7".winapi}"."wincon" = true; }
      { "${deps.tokio_signal."0.2.7".winapi}".default = true; }
    ];
  }) [
    (features_.futures."${deps."tokio_signal"."0.2.7"."futures"}" deps)
    (features_.mio."${deps."tokio_signal"."0.2.7"."mio"}" deps)
    (features_.tokio_executor."${deps."tokio_signal"."0.2.7"."tokio_executor"}" deps)
    (features_.tokio_io."${deps."tokio_signal"."0.2.7"."tokio_io"}" deps)
    (features_.tokio_reactor."${deps."tokio_signal"."0.2.7"."tokio_reactor"}" deps)
    (features_.libc."${deps."tokio_signal"."0.2.7"."libc"}" deps)
    (features_.mio_uds."${deps."tokio_signal"."0.2.7"."mio_uds"}" deps)
    (features_.signal_hook."${deps."tokio_signal"."0.2.7"."signal_hook"}" deps)
    (features_.winapi."${deps."tokio_signal"."0.2.7"."winapi"}" deps)
  ];


# end
# tokio-tcp-0.1.2

  crates.tokio_tcp."0.1.2" = deps: { features?(features_.tokio_tcp."0.1.2" deps {}) }: buildRustCrate {
    crateName = "tokio-tcp";
    version = "0.1.2";
    authors = [ "Carl Lerche <me@carllerche.com>" ];
    sha256 = "0yvfwybqnyca24aj9as8rgydamjq0wrd9xbxxkjcasvsdmsv6z1d";
    dependencies = mapFeatures features ([
      (crates."bytes"."${deps."tokio_tcp"."0.1.2"."bytes"}" deps)
      (crates."futures"."${deps."tokio_tcp"."0.1.2"."futures"}" deps)
      (crates."iovec"."${deps."tokio_tcp"."0.1.2"."iovec"}" deps)
      (crates."mio"."${deps."tokio_tcp"."0.1.2"."mio"}" deps)
      (crates."tokio_io"."${deps."tokio_tcp"."0.1.2"."tokio_io"}" deps)
      (crates."tokio_reactor"."${deps."tokio_tcp"."0.1.2"."tokio_reactor"}" deps)
    ]);
  };
  features_.tokio_tcp."0.1.2" = deps: f: updateFeatures f (rec {
    bytes."${deps.tokio_tcp."0.1.2".bytes}".default = true;
    futures."${deps.tokio_tcp."0.1.2".futures}".default = true;
    iovec."${deps.tokio_tcp."0.1.2".iovec}".default = true;
    mio."${deps.tokio_tcp."0.1.2".mio}".default = true;
    tokio_io."${deps.tokio_tcp."0.1.2".tokio_io}".default = true;
    tokio_reactor."${deps.tokio_tcp."0.1.2".tokio_reactor}".default = true;
    tokio_tcp."0.1.2".default = (f.tokio_tcp."0.1.2".default or true);
  }) [
    (features_.bytes."${deps."tokio_tcp"."0.1.2"."bytes"}" deps)
    (features_.futures."${deps."tokio_tcp"."0.1.2"."futures"}" deps)
    (features_.iovec."${deps."tokio_tcp"."0.1.2"."iovec"}" deps)
    (features_.mio."${deps."tokio_tcp"."0.1.2"."mio"}" deps)
    (features_.tokio_io."${deps."tokio_tcp"."0.1.2"."tokio_io"}" deps)
    (features_.tokio_reactor."${deps."tokio_tcp"."0.1.2"."tokio_reactor"}" deps)
  ];


# end
# tokio-threadpool-0.1.9

  crates.tokio_threadpool."0.1.9" = deps: { features?(features_.tokio_threadpool."0.1.9" deps {}) }: buildRustCrate {
    crateName = "tokio-threadpool";
    version = "0.1.9";
    authors = [ "Carl Lerche <me@carllerche.com>" ];
    sha256 = "0ipr0j79mhjjsvc0ma95sj07m0aiyq6rkwgvlalqwhinivl5d39g";
    dependencies = mapFeatures features ([
      (crates."crossbeam_deque"."${deps."tokio_threadpool"."0.1.9"."crossbeam_deque"}" deps)
      (crates."crossbeam_utils"."${deps."tokio_threadpool"."0.1.9"."crossbeam_utils"}" deps)
      (crates."futures"."${deps."tokio_threadpool"."0.1.9"."futures"}" deps)
      (crates."log"."${deps."tokio_threadpool"."0.1.9"."log"}" deps)
      (crates."num_cpus"."${deps."tokio_threadpool"."0.1.9"."num_cpus"}" deps)
      (crates."rand"."${deps."tokio_threadpool"."0.1.9"."rand"}" deps)
      (crates."tokio_executor"."${deps."tokio_threadpool"."0.1.9"."tokio_executor"}" deps)
    ]);
  };
  features_.tokio_threadpool."0.1.9" = deps: f: updateFeatures f (rec {
    crossbeam_deque."${deps.tokio_threadpool."0.1.9".crossbeam_deque}".default = true;
    crossbeam_utils."${deps.tokio_threadpool."0.1.9".crossbeam_utils}".default = true;
    futures."${deps.tokio_threadpool."0.1.9".futures}".default = true;
    log."${deps.tokio_threadpool."0.1.9".log}".default = true;
    num_cpus."${deps.tokio_threadpool."0.1.9".num_cpus}".default = true;
    rand."${deps.tokio_threadpool."0.1.9".rand}".default = true;
    tokio_executor."${deps.tokio_threadpool."0.1.9".tokio_executor}".default = true;
    tokio_threadpool."0.1.9".default = (f.tokio_threadpool."0.1.9".default or true);
  }) [
    (features_.crossbeam_deque."${deps."tokio_threadpool"."0.1.9"."crossbeam_deque"}" deps)
    (features_.crossbeam_utils."${deps."tokio_threadpool"."0.1.9"."crossbeam_utils"}" deps)
    (features_.futures."${deps."tokio_threadpool"."0.1.9"."futures"}" deps)
    (features_.log."${deps."tokio_threadpool"."0.1.9"."log"}" deps)
    (features_.num_cpus."${deps."tokio_threadpool"."0.1.9"."num_cpus"}" deps)
    (features_.rand."${deps."tokio_threadpool"."0.1.9"."rand"}" deps)
    (features_.tokio_executor."${deps."tokio_threadpool"."0.1.9"."tokio_executor"}" deps)
  ];


# end
# tokio-timer-0.2.8

  crates.tokio_timer."0.2.8" = deps: { features?(features_.tokio_timer."0.2.8" deps {}) }: buildRustCrate {
    crateName = "tokio-timer";
    version = "0.2.8";
    authors = [ "Carl Lerche <me@carllerche.com>" ];
    sha256 = "1iqdg6d9780r12n99a8f9q8yrj1sp0l82ly2iza9hx4vxx2dipxv";
    dependencies = mapFeatures features ([
      (crates."crossbeam_utils"."${deps."tokio_timer"."0.2.8"."crossbeam_utils"}" deps)
      (crates."futures"."${deps."tokio_timer"."0.2.8"."futures"}" deps)
      (crates."slab"."${deps."tokio_timer"."0.2.8"."slab"}" deps)
      (crates."tokio_executor"."${deps."tokio_timer"."0.2.8"."tokio_executor"}" deps)
    ]);
  };
  features_.tokio_timer."0.2.8" = deps: f: updateFeatures f (rec {
    crossbeam_utils."${deps.tokio_timer."0.2.8".crossbeam_utils}".default = true;
    futures."${deps.tokio_timer."0.2.8".futures}".default = true;
    slab."${deps.tokio_timer."0.2.8".slab}".default = true;
    tokio_executor."${deps.tokio_timer."0.2.8".tokio_executor}".default = true;
    tokio_timer."0.2.8".default = (f.tokio_timer."0.2.8".default or true);
  }) [
    (features_.crossbeam_utils."${deps."tokio_timer"."0.2.8"."crossbeam_utils"}" deps)
    (features_.futures."${deps."tokio_timer"."0.2.8"."futures"}" deps)
    (features_.slab."${deps."tokio_timer"."0.2.8"."slab"}" deps)
    (features_.tokio_executor."${deps."tokio_timer"."0.2.8"."tokio_executor"}" deps)
  ];


# end
# tokio-udp-0.1.3

  crates.tokio_udp."0.1.3" = deps: { features?(features_.tokio_udp."0.1.3" deps {}) }: buildRustCrate {
    crateName = "tokio-udp";
    version = "0.1.3";
    authors = [ "Carl Lerche <me@carllerche.com>" ];
    sha256 = "1g1x499vqvzwy7xfccr32vwymlx25zpmkx8ppqgifzqwrjnncajf";
    dependencies = mapFeatures features ([
      (crates."bytes"."${deps."tokio_udp"."0.1.3"."bytes"}" deps)
      (crates."futures"."${deps."tokio_udp"."0.1.3"."futures"}" deps)
      (crates."log"."${deps."tokio_udp"."0.1.3"."log"}" deps)
      (crates."mio"."${deps."tokio_udp"."0.1.3"."mio"}" deps)
      (crates."tokio_codec"."${deps."tokio_udp"."0.1.3"."tokio_codec"}" deps)
      (crates."tokio_io"."${deps."tokio_udp"."0.1.3"."tokio_io"}" deps)
      (crates."tokio_reactor"."${deps."tokio_udp"."0.1.3"."tokio_reactor"}" deps)
    ]);
  };
  features_.tokio_udp."0.1.3" = deps: f: updateFeatures f (rec {
    bytes."${deps.tokio_udp."0.1.3".bytes}".default = true;
    futures."${deps.tokio_udp."0.1.3".futures}".default = true;
    log."${deps.tokio_udp."0.1.3".log}".default = true;
    mio."${deps.tokio_udp."0.1.3".mio}".default = true;
    tokio_codec."${deps.tokio_udp."0.1.3".tokio_codec}".default = true;
    tokio_io."${deps.tokio_udp."0.1.3".tokio_io}".default = true;
    tokio_reactor."${deps.tokio_udp."0.1.3".tokio_reactor}".default = true;
    tokio_udp."0.1.3".default = (f.tokio_udp."0.1.3".default or true);
  }) [
    (features_.bytes."${deps."tokio_udp"."0.1.3"."bytes"}" deps)
    (features_.futures."${deps."tokio_udp"."0.1.3"."futures"}" deps)
    (features_.log."${deps."tokio_udp"."0.1.3"."log"}" deps)
    (features_.mio."${deps."tokio_udp"."0.1.3"."mio"}" deps)
    (features_.tokio_codec."${deps."tokio_udp"."0.1.3"."tokio_codec"}" deps)
    (features_.tokio_io."${deps."tokio_udp"."0.1.3"."tokio_io"}" deps)
    (features_.tokio_reactor."${deps."tokio_udp"."0.1.3"."tokio_reactor"}" deps)
  ];


# end
# tokio-uds-0.2.4

  crates.tokio_uds."0.2.4" = deps: { features?(features_.tokio_uds."0.2.4" deps {}) }: buildRustCrate {
    crateName = "tokio-uds";
    version = "0.2.4";
    authors = [ "Carl Lerche <me@carllerche.com>" ];
    sha256 = "16cs6wnkm14wzsbn2s5y2skiavw7drjyga5h34w4ffb3ih230vp3";
    dependencies = mapFeatures features ([
      (crates."bytes"."${deps."tokio_uds"."0.2.4"."bytes"}" deps)
      (crates."futures"."${deps."tokio_uds"."0.2.4"."futures"}" deps)
      (crates."iovec"."${deps."tokio_uds"."0.2.4"."iovec"}" deps)
      (crates."libc"."${deps."tokio_uds"."0.2.4"."libc"}" deps)
      (crates."log"."${deps."tokio_uds"."0.2.4"."log"}" deps)
      (crates."mio"."${deps."tokio_uds"."0.2.4"."mio"}" deps)
      (crates."mio_uds"."${deps."tokio_uds"."0.2.4"."mio_uds"}" deps)
      (crates."tokio_codec"."${deps."tokio_uds"."0.2.4"."tokio_codec"}" deps)
      (crates."tokio_io"."${deps."tokio_uds"."0.2.4"."tokio_io"}" deps)
      (crates."tokio_reactor"."${deps."tokio_uds"."0.2.4"."tokio_reactor"}" deps)
    ]);
  };
  features_.tokio_uds."0.2.4" = deps: f: updateFeatures f (rec {
    bytes."${deps.tokio_uds."0.2.4".bytes}".default = true;
    futures."${deps.tokio_uds."0.2.4".futures}".default = true;
    iovec."${deps.tokio_uds."0.2.4".iovec}".default = true;
    libc."${deps.tokio_uds."0.2.4".libc}".default = true;
    log."${deps.tokio_uds."0.2.4".log}".default = true;
    mio."${deps.tokio_uds."0.2.4".mio}".default = true;
    mio_uds."${deps.tokio_uds."0.2.4".mio_uds}".default = true;
    tokio_codec."${deps.tokio_uds."0.2.4".tokio_codec}".default = true;
    tokio_io."${deps.tokio_uds."0.2.4".tokio_io}".default = true;
    tokio_reactor."${deps.tokio_uds."0.2.4".tokio_reactor}".default = true;
    tokio_uds."0.2.4".default = (f.tokio_uds."0.2.4".default or true);
  }) [
    (features_.bytes."${deps."tokio_uds"."0.2.4"."bytes"}" deps)
    (features_.futures."${deps."tokio_uds"."0.2.4"."futures"}" deps)
    (features_.iovec."${deps."tokio_uds"."0.2.4"."iovec"}" deps)
    (features_.libc."${deps."tokio_uds"."0.2.4"."libc"}" deps)
    (features_.log."${deps."tokio_uds"."0.2.4"."log"}" deps)
    (features_.mio."${deps."tokio_uds"."0.2.4"."mio"}" deps)
    (features_.mio_uds."${deps."tokio_uds"."0.2.4"."mio_uds"}" deps)
    (features_.tokio_codec."${deps."tokio_uds"."0.2.4"."tokio_codec"}" deps)
    (features_.tokio_io."${deps."tokio_uds"."0.2.4"."tokio_io"}" deps)
    (features_.tokio_reactor."${deps."tokio_uds"."0.2.4"."tokio_reactor"}" deps)
  ];


# end
# ucd-util-0.1.3

  crates.ucd_util."0.1.3" = deps: { features?(features_.ucd_util."0.1.3" deps {}) }: buildRustCrate {
    crateName = "ucd-util";
    version = "0.1.3";
    authors = [ "Andrew Gallant <jamslam@gmail.com>" ];
    sha256 = "1n1qi3jywq5syq90z9qd8qzbn58pcjgv1sx4sdmipm4jf9zanz15";
  };
  features_.ucd_util."0.1.3" = deps: f: updateFeatures f (rec {
    ucd_util."0.1.3".default = (f.ucd_util."0.1.3".default or true);
  }) [];


# end
# unicode-xid-0.1.0

  crates.unicode_xid."0.1.0" = deps: { features?(features_.unicode_xid."0.1.0" deps {}) }: buildRustCrate {
    crateName = "unicode-xid";
    version = "0.1.0";
    authors = [ "erick.tryzelaar <erick.tryzelaar@gmail.com>" "kwantam <kwantam@gmail.com>" ];
    sha256 = "05wdmwlfzxhq3nhsxn6wx4q8dhxzzfb9szsz6wiw092m1rjj01zj";
    features = mkFeatures (features."unicode_xid"."0.1.0" or {});
  };
  features_.unicode_xid."0.1.0" = deps: f: updateFeatures f (rec {
    unicode_xid."0.1.0".default = (f.unicode_xid."0.1.0".default or true);
  }) [];


# end
# unreachable-1.0.0

  crates.unreachable."1.0.0" = deps: { features?(features_.unreachable."1.0.0" deps {}) }: buildRustCrate {
    crateName = "unreachable";
    version = "1.0.0";
    authors = [ "Jonathan Reem <jonathan.reem@gmail.com>" ];
    sha256 = "1am8czbk5wwr25gbp2zr007744fxjshhdqjz9liz7wl4pnv3whcf";
    dependencies = mapFeatures features ([
      (crates."void"."${deps."unreachable"."1.0.0"."void"}" deps)
    ]);
  };
  features_.unreachable."1.0.0" = deps: f: updateFeatures f (rec {
    unreachable."1.0.0".default = (f.unreachable."1.0.0".default or true);
    void."${deps.unreachable."1.0.0".void}".default = (f.void."${deps.unreachable."1.0.0".void}".default or false);
  }) [
    (features_.void."${deps."unreachable"."1.0.0"."void"}" deps)
  ];


# end
# utf8-ranges-1.0.2

  crates.utf8_ranges."1.0.2" = deps: { features?(features_.utf8_ranges."1.0.2" deps {}) }: buildRustCrate {
    crateName = "utf8-ranges";
    version = "1.0.2";
    authors = [ "Andrew Gallant <jamslam@gmail.com>" ];
    sha256 = "1my02laqsgnd8ib4dvjgd4rilprqjad6pb9jj9vi67csi5qs2281";
  };
  features_.utf8_ranges."1.0.2" = deps: f: updateFeatures f (rec {
    utf8_ranges."1.0.2".default = (f.utf8_ranges."1.0.2".default or true);
  }) [];


# end
# version_check-0.1.5

  crates.version_check."0.1.5" = deps: { features?(features_.version_check."0.1.5" deps {}) }: buildRustCrate {
    crateName = "version_check";
    version = "0.1.5";
    authors = [ "Sergio Benitez <sb@sergio.bz>" ];
    sha256 = "1yrx9xblmwbafw2firxyqbj8f771kkzfd24n3q7xgwiqyhi0y8qd";
  };
  features_.version_check."0.1.5" = deps: f: updateFeatures f (rec {
    version_check."0.1.5".default = (f.version_check."0.1.5".default or true);
  }) [];


# end
# void-1.0.2

  crates.void."1.0.2" = deps: { features?(features_.void."1.0.2" deps {}) }: buildRustCrate {
    crateName = "void";
    version = "1.0.2";
    authors = [ "Jonathan Reem <jonathan.reem@gmail.com>" ];
    sha256 = "0h1dm0dx8dhf56a83k68mijyxigqhizpskwxfdrs1drwv2cdclv3";
    features = mkFeatures (features."void"."1.0.2" or {});
  };
  features_.void."1.0.2" = deps: f: updateFeatures f (rec {
    void = fold recursiveUpdate {} [
      { "1.0.2".default = (f.void."1.0.2".default or true); }
      { "1.0.2".std =
        (f.void."1.0.2".std or false) ||
        (f.void."1.0.2".default or false) ||
        (void."1.0.2"."default" or false); }
    ];
  }) [];


# end
# winapi-0.2.8

  crates.winapi."0.2.8" = deps: { features?(features_.winapi."0.2.8" deps {}) }: buildRustCrate {
    crateName = "winapi";
    version = "0.2.8";
    authors = [ "Peter Atashian <retep998@gmail.com>" ];
    sha256 = "0a45b58ywf12vb7gvj6h3j264nydynmzyqz8d8rqxsj6icqv82as";
  };
  features_.winapi."0.2.8" = deps: f: updateFeatures f (rec {
    winapi."0.2.8".default = (f.winapi."0.2.8".default or true);
  }) [];


# end
# winapi-0.3.6

  crates.winapi."0.3.6" = deps: { features?(features_.winapi."0.3.6" deps {}) }: buildRustCrate {
    crateName = "winapi";
    version = "0.3.6";
    authors = [ "Peter Atashian <retep998@gmail.com>" ];
    sha256 = "1d9jfp4cjd82sr1q4dgdlrkvm33zhhav9d7ihr0nivqbncr059m4";
    build = "build.rs";
    dependencies = (if kernel == "i686-pc-windows-gnu" then mapFeatures features ([
      (crates."winapi_i686_pc_windows_gnu"."${deps."winapi"."0.3.6"."winapi_i686_pc_windows_gnu"}" deps)
    ]) else [])
      ++ (if kernel == "x86_64-pc-windows-gnu" then mapFeatures features ([
      (crates."winapi_x86_64_pc_windows_gnu"."${deps."winapi"."0.3.6"."winapi_x86_64_pc_windows_gnu"}" deps)
    ]) else []);
    features = mkFeatures (features."winapi"."0.3.6" or {});
  };
  features_.winapi."0.3.6" = deps: f: updateFeatures f (rec {
    winapi."0.3.6".default = (f.winapi."0.3.6".default or true);
    winapi_i686_pc_windows_gnu."${deps.winapi."0.3.6".winapi_i686_pc_windows_gnu}".default = true;
    winapi_x86_64_pc_windows_gnu."${deps.winapi."0.3.6".winapi_x86_64_pc_windows_gnu}".default = true;
  }) [
    (features_.winapi_i686_pc_windows_gnu."${deps."winapi"."0.3.6"."winapi_i686_pc_windows_gnu"}" deps)
    (features_.winapi_x86_64_pc_windows_gnu."${deps."winapi"."0.3.6"."winapi_x86_64_pc_windows_gnu"}" deps)
  ];


# end
# winapi-build-0.1.1

  crates.winapi_build."0.1.1" = deps: { features?(features_.winapi_build."0.1.1" deps {}) }: buildRustCrate {
    crateName = "winapi-build";
    version = "0.1.1";
    authors = [ "Peter Atashian <retep998@gmail.com>" ];
    sha256 = "1lxlpi87rkhxcwp2ykf1ldw3p108hwm24nywf3jfrvmff4rjhqga";
    libName = "build";
  };
  features_.winapi_build."0.1.1" = deps: f: updateFeatures f (rec {
    winapi_build."0.1.1".default = (f.winapi_build."0.1.1".default or true);
  }) [];


# end
# winapi-i686-pc-windows-gnu-0.4.0

  crates.winapi_i686_pc_windows_gnu."0.4.0" = deps: { features?(features_.winapi_i686_pc_windows_gnu."0.4.0" deps {}) }: buildRustCrate {
    crateName = "winapi-i686-pc-windows-gnu";
    version = "0.4.0";
    authors = [ "Peter Atashian <retep998@gmail.com>" ];
    sha256 = "05ihkij18r4gamjpxj4gra24514can762imjzlmak5wlzidplzrp";
    build = "build.rs";
  };
  features_.winapi_i686_pc_windows_gnu."0.4.0" = deps: f: updateFeatures f (rec {
    winapi_i686_pc_windows_gnu."0.4.0".default = (f.winapi_i686_pc_windows_gnu."0.4.0".default or true);
  }) [];


# end
# winapi-util-0.1.1

  crates.winapi_util."0.1.1" = deps: { features?(features_.winapi_util."0.1.1" deps {}) }: buildRustCrate {
    crateName = "winapi-util";
    version = "0.1.1";
    authors = [ "Andrew Gallant <jamslam@gmail.com>" ];
    sha256 = "10madanla73aagbklx6y73r2g2vwq9w8a0qcghbbbpn9vfr6a95f";
    dependencies = (if kernel == "windows" then mapFeatures features ([
      (crates."winapi"."${deps."winapi_util"."0.1.1"."winapi"}" deps)
    ]) else []);
  };
  features_.winapi_util."0.1.1" = deps: f: updateFeatures f (rec {
    winapi = fold recursiveUpdate {} [
      { "${deps.winapi_util."0.1.1".winapi}"."consoleapi" = true; }
      { "${deps.winapi_util."0.1.1".winapi}"."errhandlingapi" = true; }
      { "${deps.winapi_util."0.1.1".winapi}"."fileapi" = true; }
      { "${deps.winapi_util."0.1.1".winapi}"."minwindef" = true; }
      { "${deps.winapi_util."0.1.1".winapi}"."processenv" = true; }
      { "${deps.winapi_util."0.1.1".winapi}"."std" = true; }
      { "${deps.winapi_util."0.1.1".winapi}"."winbase" = true; }
      { "${deps.winapi_util."0.1.1".winapi}"."wincon" = true; }
      { "${deps.winapi_util."0.1.1".winapi}"."winerror" = true; }
      { "${deps.winapi_util."0.1.1".winapi}".default = true; }
    ];
    winapi_util."0.1.1".default = (f.winapi_util."0.1.1".default or true);
  }) [
    (features_.winapi."${deps."winapi_util"."0.1.1"."winapi"}" deps)
  ];


# end
# winapi-x86_64-pc-windows-gnu-0.4.0

  crates.winapi_x86_64_pc_windows_gnu."0.4.0" = deps: { features?(features_.winapi_x86_64_pc_windows_gnu."0.4.0" deps {}) }: buildRustCrate {
    crateName = "winapi-x86_64-pc-windows-gnu";
    version = "0.4.0";
    authors = [ "Peter Atashian <retep998@gmail.com>" ];
    sha256 = "0n1ylmlsb8yg1v583i4xy0qmqg42275flvbc51hdqjjfjcl9vlbj";
    build = "build.rs";
  };
  features_.winapi_x86_64_pc_windows_gnu."0.4.0" = deps: f: updateFeatures f (rec {
    winapi_x86_64_pc_windows_gnu."0.4.0".default = (f.winapi_x86_64_pc_windows_gnu."0.4.0".default or true);
  }) [];


# end
# wincolor-1.0.1

  crates.wincolor."1.0.1" = deps: { features?(features_.wincolor."1.0.1" deps {}) }: buildRustCrate {
    crateName = "wincolor";
    version = "1.0.1";
    authors = [ "Andrew Gallant <jamslam@gmail.com>" ];
    sha256 = "0gr7v4krmjba7yq16071rfacz42qbapas7mxk5nphjwb042a8gvz";
    dependencies = mapFeatures features ([
      (crates."winapi"."${deps."wincolor"."1.0.1"."winapi"}" deps)
      (crates."winapi_util"."${deps."wincolor"."1.0.1"."winapi_util"}" deps)
    ]);
  };
  features_.wincolor."1.0.1" = deps: f: updateFeatures f (rec {
    winapi = fold recursiveUpdate {} [
      { "${deps.wincolor."1.0.1".winapi}"."minwindef" = true; }
      { "${deps.wincolor."1.0.1".winapi}"."wincon" = true; }
      { "${deps.wincolor."1.0.1".winapi}".default = true; }
    ];
    winapi_util."${deps.wincolor."1.0.1".winapi_util}".default = true;
    wincolor."1.0.1".default = (f.wincolor."1.0.1".default or true);
  }) [
    (features_.winapi."${deps."wincolor"."1.0.1"."winapi"}" deps)
    (features_.winapi_util."${deps."wincolor"."1.0.1"."winapi_util"}" deps)
  ];


# end
# winutil-0.1.1

  crates.winutil."0.1.1" = deps: { features?(features_.winutil."0.1.1" deps {}) }: buildRustCrate {
    crateName = "winutil";
    version = "0.1.1";
    authors = [ "Dave Lancaster <lancaster.dave@gmail.com>" ];
    sha256 = "1wvq440hl1v3a65agjbp031gw5jim3qasfvmz703dlz95pbjv45r";
    dependencies = (if kernel == "windows" then mapFeatures features ([
      (crates."winapi"."${deps."winutil"."0.1.1"."winapi"}" deps)
    ]) else []);
  };
  features_.winutil."0.1.1" = deps: f: updateFeatures f (rec {
    winapi = fold recursiveUpdate {} [
      { "${deps.winutil."0.1.1".winapi}"."processthreadsapi" = true; }
      { "${deps.winutil."0.1.1".winapi}"."winbase" = true; }
      { "${deps.winutil."0.1.1".winapi}"."wow64apiset" = true; }
      { "${deps.winutil."0.1.1".winapi}".default = true; }
    ];
    winutil."0.1.1".default = (f.winutil."0.1.1".default or true);
  }) [
    (features_.winapi."${deps."winutil"."0.1.1"."winapi"}" deps)
  ];


# end
# ws2_32-sys-0.2.1

  crates.ws2_32_sys."0.2.1" = deps: { features?(features_.ws2_32_sys."0.2.1" deps {}) }: buildRustCrate {
    crateName = "ws2_32-sys";
    version = "0.2.1";
    authors = [ "Peter Atashian <retep998@gmail.com>" ];
    sha256 = "1zpy9d9wk11sj17fczfngcj28w4xxjs3b4n036yzpy38dxp4f7kc";
    libName = "ws2_32";
    build = "build.rs";
    dependencies = mapFeatures features ([
      (crates."winapi"."${deps."ws2_32_sys"."0.2.1"."winapi"}" deps)
    ]);

    buildDependencies = mapFeatures features ([
      (crates."winapi_build"."${deps."ws2_32_sys"."0.2.1"."winapi_build"}" deps)
    ]);
  };
  features_.ws2_32_sys."0.2.1" = deps: f: updateFeatures f (rec {
    winapi."${deps.ws2_32_sys."0.2.1".winapi}".default = true;
    winapi_build."${deps.ws2_32_sys."0.2.1".winapi_build}".default = true;
    ws2_32_sys."0.2.1".default = (f.ws2_32_sys."0.2.1".default or true);
  }) [
    (features_.winapi."${deps."ws2_32_sys"."0.2.1"."winapi"}" deps)
    (features_.winapi_build."${deps."ws2_32_sys"."0.2.1"."winapi_build"}" deps)
  ];


# end
# yaml-rust-0.4.2

  crates.yaml_rust."0.4.2" = deps: { features?(features_.yaml_rust."0.4.2" deps {}) }: buildRustCrate {
    crateName = "yaml-rust";
    version = "0.4.2";
    authors = [ "Yuheng Chen <yuhengchen@sensetime.com>" ];
    sha256 = "1bxc5hhky8rk5r8hrv4ynppsfkivq07jbj458i3h8zkhc1ca33lk";
    dependencies = mapFeatures features ([
      (crates."linked_hash_map"."${deps."yaml_rust"."0.4.2"."linked_hash_map"}" deps)
    ]);
  };
  features_.yaml_rust."0.4.2" = deps: f: updateFeatures f (rec {
    linked_hash_map."${deps.yaml_rust."0.4.2".linked_hash_map}".default = true;
    yaml_rust."0.4.2".default = (f.yaml_rust."0.4.2".default or true);
  }) [
    (features_.linked_hash_map."${deps."yaml_rust"."0.4.2"."linked_hash_map"}" deps)
  ];


# end
}
