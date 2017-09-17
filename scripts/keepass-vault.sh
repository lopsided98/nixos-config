#!/bin/bash

kphttp-cli get --trigger-unlock --plaintext python-keepasshttp ansible-vault | cut -d ' ' -f2
