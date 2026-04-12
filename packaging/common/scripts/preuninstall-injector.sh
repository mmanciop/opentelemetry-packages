#!/bin/bash

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

# Pre-uninstallation script for the opentelemetry-injector package.
# Removes the injector library from /etc/ld.so.preload.

set -euo pipefail

LIBOTELINJECT_PATH="/usr/lib/opentelemetry/injector/libotelinject.so"
LD_SO_PRELOAD="/etc/ld.so.preload"

# Remove the injector from ld.so.preload
if [ -f "$LD_SO_PRELOAD" ]; then
    sed -i "\|${LIBOTELINJECT_PATH}|d" "$LD_SO_PRELOAD"

    # Remove the file if it is now empty
    if [ ! -s "$LD_SO_PRELOAD" ]; then
        rm -f "$LD_SO_PRELOAD"
    fi
fi
