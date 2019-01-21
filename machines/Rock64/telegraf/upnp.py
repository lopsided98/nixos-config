#!/usr/bin/env python3

import upnpclient
import json
import sys

ifc = upnpclient.Device("http://192.168.1.1:49153/IGDdevicedesc_brlan0.xml").WANCommonIFC1

json.dump({
  'bytes_sent': ifc.GetTotalBytesSent()['NewTotalBytesSent'],
  'bytes_received': ifc.GetTotalBytesReceived()['NewTotalBytesReceived'],
  'packets_sent': ifc.GetTotalPacketsSent()['NewTotalPacketsSent'],
  'packets_received': ifc.GetTotalPacketsReceived()['NewTotalPacketsReceived']
}, sys.stdout)
