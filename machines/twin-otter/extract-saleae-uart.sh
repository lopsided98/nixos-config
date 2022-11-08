#!/usr/bin/env bash
# Script to convert Saleae Logic UART decoder text data to raw binary. Designed
# to work with text console output (e.g. from U-Boot). The only reason I need
# this is because U-Boot is broken and uses a wierd baud rate that my USB-UARTs
# can't decode.

sed -e 's#.*,\(.*\),,.*#\1#' | \
tail -n +2 | \
tr '\n' '\0' | \
sed -z \
  -e "s/'8'/\x8/" \
  -e 's/\\r//' \
  -e 's/\\n/\n/' \
  -e 's/\\t/\t/' \
  -e "s/COMMA/,/" \
  -e "s/'\(.\)'/\1/" | \
tr -d '\0'
