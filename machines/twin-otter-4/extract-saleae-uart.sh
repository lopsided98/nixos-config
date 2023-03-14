#!/usr/bin/env bash
# Script to convert Saleae Logic UART decoder export data to raw binary. Data
# must be exported in hex format. The only reason I need this is because U-Boot
# is broken and uses a non-standard baud rate that my USB UARTs can't decode, so
# I have to use a logic analyzer instead.

tail -n +2 | \
sed -e 's#.*,0x\(.*\),,.*#\1#' | \
xxd -r -p
