#!/bin/bash

kphttp-cli get --trigger-unlock --plaintext python-keepasshttp nixos-secrets | cut -d ' ' -f2
