#!/bin/sh

# Convert kbuild config file to Nix expression.

in=$1
out=$2

echo "{" > "${out}"
while IFS='=' read key val; do
  [ "x${key#CONFIG_}" != "x$key" ] || continue
  no_firstquote="${val#\"}";
  echo '  "'"$key"'" = "'"${no_firstquote%\"}"'";' >> "${out}"
done < "${in}"
echo "}" >> "${out}"
