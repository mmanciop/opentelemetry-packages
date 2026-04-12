#!/bin/bash

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

# Install additional dependencies needed by the build scripts.

set -euo pipefail

apt-get update -qq
apt-get install -y -qq --no-install-recommends curl unzip npm
