#!/bin/bash

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

# Parameterized runner for DEB integration tests.
# Usage: run.sh <distro> <lang>
# Example: ARCH=amd64 ./run.sh debian-12 java

set -euo pipefail

distro="${1:?Usage: $0 <distro> <lang>}"
lang="${2:?Usage: $0 <distro> <lang>}"
arch="${ARCH:-amd64}"

if [ "$arch" = arm64 ]; then
  docker_platform=linux/arm64
elif [ "$arch" = amd64 ]; then
  docker_platform=linux/amd64
else
  echo "The architecture $arch is not supported."
  exit 1
fi

echo "Running package integration tests for ${lang}/deb/${distro}/${arch}."

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/../../.."

dockerfile="packaging/tests/deb/${distro}/${lang}/Dockerfile"
if [ ! -f "$dockerfile" ]; then
  echo "Dockerfile not found: $dockerfile"
  exit 1
fi

build_args=(
  --platform "$docker_platform"
  --build-arg "ARCH=$arch"
)

if [ "$lang" = "java" ]; then
  tomcat_download_url=$(packaging/tests/shared/determine-tomcat-download-url.sh)
  if [[ ! "$tomcat_download_url" =~ dlcdn.apache.org ]]; then
    echo "The Tomcat download URL looks incorrect: \"$tomcat_download_url\""
    exit 1
  fi
  build_args+=(--build-arg "tomcat_download_url=$tomcat_download_url")
fi

image_tag="otel-test-${distro}-${lang}-${arch}"

docker build \
  "${build_args[@]}" \
  -t "$image_tag" \
  -f "$dockerfile" \
  .
docker run \
  --platform "$docker_platform" \
  --rm \
  "$image_tag"
