#!/bin/bash

kphttp-cli get --plaintext python-keepasshttp ansible-vault | cut -d ' ' -f2
