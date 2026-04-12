# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

FROM ruby:3.3-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    rpm \
    npm \
    unzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /packaging

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY install-deps.sh ./
RUN chmod +x install-deps.sh

WORKDIR /repo
