#!/bin/bash

# finds version line from Chart yaml(not any follwing lines) - "version: 0.1.0"
# get value field after separator - " 0.1.0"
# trim whitespace at front - "0.1.0"
echo "asset-management-$(grep -A0 'version:' Chart.yaml | cut -d: -f2 | sed 's/^[ \]*//')"