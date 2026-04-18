# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

ARCH?=amd64
VERSION?=0.0.0-dev
DIST_DIR_BINARY:=dist
DIST_DIR_PACKAGE:=build/packages

# Injector binary source
INJECTOR_RELEASE_TAG := $(shell cat packaging/injector-release.txt | tr -d '[:space:]')
INJECTOR_REPO := open-telemetry/opentelemetry-injector

ifeq ($(ARCH),arm64)
  RPM_PACKAGE_ARCH:=aarch64
else
  RPM_PACKAGE_ARCH:=x86_64
endif
RPM_VERSION=$(subst -,_,$(VERSION))

SHELL = /bin/bash
.SHELLFLAGS = -o pipefail -c

# SRC_ROOT is the top of the source tree.
SRC_ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# ============================================================================
# Injector Binary Acquisition
# ============================================================================
# The injector binary is built in the open-telemetry/opentelemetry-injector
# repository. We download it from GitHub releases.

BINARY_NAME:=libotelinject_$(ARCH).so
DIST_TARGET:=$(DIST_DIR_BINARY)/$(BINARY_NAME)

.PHONY: download-injector-binary
download-injector-binary: $(DIST_TARGET)

$(DIST_TARGET):
	@echo "Downloading injector binary $(BINARY_NAME) from $(INJECTOR_REPO) release $(INJECTOR_RELEASE_TAG)"
	@mkdir -p $(DIST_DIR_BINARY)
	curl -sfL "https://github.com/$(INJECTOR_REPO)/releases/download/$(INJECTOR_RELEASE_TAG)/$(BINARY_NAME)" \
		-o "$(DIST_TARGET)"
	chmod 755 "$(DIST_TARGET)"

# ============================================================================
# FPM Docker Image
# ============================================================================

.PHONY: fpm-docker-image
fpm-docker-image:
	docker build -t instrumentation-fpm packaging/common/fpm

# ============================================================================
# Generic function to build a modular package
# ============================================================================

define build_modular_package
$(eval $@_PKG_TYPE = $(1))
$(eval $@_PKG_NAME = $(2))
$(eval $@_VERSION = $(3))
@echo "Building $($@_PKG_TYPE) package: $($@_PKG_NAME) version $($@_VERSION) for $(ARCH)"
@mkdir -p $(DIST_DIR_PACKAGE)
docker rm -f otel-packager 2>/dev/null || true
docker run -d --name otel-packager --rm -v $(CURDIR):/repo -e VERSION=$($@_VERSION) -e ARCH=$(ARCH) instrumentation-fpm sleep inf
docker exec otel-packager ./packaging/$($@_PKG_TYPE)/$($@_PKG_NAME)/build.sh "$($@_VERSION)" "$(ARCH)" "/repo/$(DIST_DIR_PACKAGE)"
docker rm -f otel-packager 2>/dev/null
endef

# ============================================================================
# DEB Package Targets
# ============================================================================

.PHONY: deb-package-injector
deb-package-injector: download-injector-binary fpm-docker-image
	@$(call build_modular_package,deb,injector,$(VERSION))

.PHONY: deb-package-java
deb-package-java: fpm-docker-image
	@$(call build_modular_package,deb,java,$(VERSION))

.PHONY: deb-package-nodejs
deb-package-nodejs: fpm-docker-image
	@$(call build_modular_package,deb,nodejs,$(VERSION))

.PHONY: deb-package-dotnet
deb-package-dotnet: fpm-docker-image
	@$(call build_modular_package,deb,dotnet,$(VERSION))

.PHONY: deb-package-meta
deb-package-meta: fpm-docker-image
	@$(call build_modular_package,deb,meta,$(VERSION))

.PHONY: deb-packages
deb-packages: deb-package-injector deb-package-java deb-package-nodejs deb-package-dotnet deb-package-meta
	@echo "All DEB packages built successfully"

# Aliases for CI compatibility
.PHONY: deb-package
deb-package: deb-packages

# ============================================================================
# RPM Package Targets
# ============================================================================

.PHONY: rpm-package-injector
rpm-package-injector: download-injector-binary fpm-docker-image
	@$(call build_modular_package,rpm,injector,$(RPM_VERSION))

.PHONY: rpm-package-java
rpm-package-java: fpm-docker-image
	@$(call build_modular_package,rpm,java,$(RPM_VERSION))

.PHONY: rpm-package-nodejs
rpm-package-nodejs: fpm-docker-image
	@$(call build_modular_package,rpm,nodejs,$(RPM_VERSION))

.PHONY: rpm-package-dotnet
rpm-package-dotnet: fpm-docker-image
	@$(call build_modular_package,rpm,dotnet,$(RPM_VERSION))

.PHONY: rpm-package-meta
rpm-package-meta: fpm-docker-image
	@$(call build_modular_package,rpm,meta,$(RPM_VERSION))

.PHONY: rpm-packages
rpm-packages: rpm-package-injector rpm-package-java rpm-package-nodejs rpm-package-dotnet rpm-package-meta
	@echo "All RPM packages built successfully"

# Aliases for CI compatibility
.PHONY: rpm-package
rpm-package: rpm-packages

.PHONY: packages
packages: deb-packages rpm-packages
	@echo "All packages built successfully"

# ============================================================================
# Packaging Integration Tests
# ============================================================================
# Parameterized: make integration-test FORMAT=deb DISTRO=debian-12 LANG=java
# Or use the convenience targets below.

FORMAT ?= deb
DISTRO ?= debian-12
LANG ?= java

DEB_DISTROS := debian-11 debian-12 ubuntu-22.04 ubuntu-24.04
RPM_DISTROS := fedora-41 ubi-8 ubi-9
LANGS := java nodejs dotnet

.PHONY: integration-test
integration-test:
	ARCH=$(ARCH) packaging/tests/$(FORMAT)/run.sh $(DISTRO) $(LANG)

.PHONY: integration-tests-deb
integration-tests-deb: deb-packages
	@for distro in $(DEB_DISTROS); do \
	  for lang in $(LANGS); do \
	    echo "=== Testing deb/$$distro/$$lang/$(ARCH) ==="; \
	    ARCH=$(ARCH) packaging/tests/deb/run.sh $$distro $$lang || exit 1; \
	  done; \
	done

.PHONY: integration-tests-rpm
integration-tests-rpm: rpm-packages
	@for distro in $(RPM_DISTROS); do \
	  for lang in $(LANGS); do \
	    echo "=== Testing rpm/$$distro/$$lang/$(ARCH) ==="; \
	    ARCH=$(ARCH) packaging/tests/rpm/run.sh $$distro $$lang || exit 1; \
	  done; \
	done

.PHONY: integration-tests-all
integration-tests-all: integration-tests-deb integration-tests-rpm

# Legacy targets for backwards compatibility with CI
.PHONY: packaging-integration-test-deb-%
packaging-integration-test-deb-%: deb-packages
	ARCH=$(ARCH) packaging/tests/deb/run.sh $(DISTRO) $*

.PHONY: packaging-integration-test-rpm-%
packaging-integration-test-rpm-%: rpm-packages
	ARCH=$(ARCH) packaging/tests/rpm/run.sh $(DISTRO) $*

# ============================================================================
# Local Package Repositories for Testing
# ============================================================================

LOCAL_REPO_DIR := $(CURDIR)/build/local-repo

.PHONY: local-apt-repo
local-apt-repo: deb-packages
	@echo "Creating local APT repository in $(LOCAL_REPO_DIR)/apt"
	@mkdir -p $(LOCAL_REPO_DIR)/apt/pool
	@cp $(DIST_DIR_PACKAGE)/*.deb $(LOCAL_REPO_DIR)/apt/pool/
	@docker run --rm --platform linux/amd64 \
		-v $(LOCAL_REPO_DIR)/apt:/repo \
		-v $(CURDIR)/packaging/repo:/scripts:ro \
		debian:12 /scripts/generate-apt-repo.sh /repo
	@echo ""
	@echo "APT repository created at $(LOCAL_REPO_DIR)/apt"
	@echo ""
	@echo "To test in a container:"
	@echo "  docker run --platform linux/amd64 -v $(LOCAL_REPO_DIR)/apt:/local-repo -it debian:12 bash"
	@echo ""
	@echo "Then inside the container:"
	@echo "  echo 'deb [trusted=yes] file:///local-repo stable main' > /etc/apt/sources.list.d/local.list"
	@echo "  apt-get update"
	@echo "  apt-get install opentelemetry-injector opentelemetry-java-autoinstrumentation"

.PHONY: local-rpm-repo
local-rpm-repo: rpm-packages
	@echo "Creating local RPM repository in $(LOCAL_REPO_DIR)/rpm"
	@mkdir -p $(LOCAL_REPO_DIR)/rpm/packages
	@cp $(DIST_DIR_PACKAGE)/*.rpm $(LOCAL_REPO_DIR)/rpm/packages/
	@docker run --rm --platform linux/amd64 \
		-v $(LOCAL_REPO_DIR)/rpm:/repo \
		-v $(CURDIR)/packaging/repo:/scripts:ro \
		fedora:41 /scripts/generate-rpm-repo.sh /repo
	@echo ""
	@echo "RPM repository created at $(LOCAL_REPO_DIR)/rpm"
	@echo ""
	@echo "To test in a container:"
	@echo "  docker run --platform linux/amd64 -v $(LOCAL_REPO_DIR)/rpm:/local-repo -it fedora:41 bash"
	@echo ""
	@echo "Then inside the container:"
	@echo "  echo -e '[local]\nname=Local\nbaseurl=file:///local-repo/packages\nenabled=1\ngpgcheck=0' > /etc/yum.repos.d/local.repo"
	@echo "  dnf install opentelemetry-injector opentelemetry-java-autoinstrumentation"

.PHONY: local-repos
local-repos: local-apt-repo local-rpm-repo
	@echo "All local repositories created in $(LOCAL_REPO_DIR)"

# ============================================================================
# Linting
# ============================================================================

.PHONY: check-shellcheck-installed
check-shellcheck-installed:
	@if ! shellcheck --version > /dev/null 2>&1; then \
	  echo "error: shellcheck is not installed. See https://github.com/koalaman/shellcheck?tab=readme-ov-file#installing for installation instructions."; \
	  exit 1; \
	fi

.PHONY: shellcheck-lint
shellcheck-lint: check-shellcheck-installed
	@echo "linting shell scripts with shellcheck"
	find . -name \*.sh | xargs shellcheck -x

.PHONY: lint
lint: shellcheck-lint

# ============================================================================
# Housekeeping
# ============================================================================

.PHONY: clean
clean:
	rm -rf dist build

.PHONY: clean-local-repos
clean-local-repos:
	rm -rf $(LOCAL_REPO_DIR)

.PHONY: list
list:
	@grep '^[^#[:space:]].*:' Makefile
