#!/bin/bash

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

# Post-installation script for the opentelemetry-injector package.
# Adds the injector library to /etc/ld.so.preload so it is loaded
# into every process on the system.

set -euo pipefail

LIBOTELINJECT_PATH="/usr/lib/opentelemetry/injector/libotelinject.so"
LD_SO_PRELOAD="/etc/ld.so.preload"

# Add the injector to ld.so.preload if not already present
if [ -f "$LD_SO_PRELOAD" ]; then
    if ! grep -qF "$LIBOTELINJECT_PATH" "$LD_SO_PRELOAD"; then
        echo "$LIBOTELINJECT_PATH" >> "$LD_SO_PRELOAD"
    fi
else
    echo "$LIBOTELINJECT_PATH" > "$LD_SO_PRELOAD"
fi
