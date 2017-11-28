self: super:

with self; {
  dnsupdate = callPackage ./dnsupdate/default.nix {
    inherit (python3Packages) buildPythonApplication requests pyyaml beautifulsoup4;
  };
  
  muximux = callPackage ./muximux/default.nix {};
  
  tinyssh = callPackage ./tinyssh/default.nix {};
  
  tinyssh-convert = callPackage ./tinyssh-convert/default.nix {};
}
