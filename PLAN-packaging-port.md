# Plan: Port Packaging Logic from opentelemetry-injector PR #239

## Context

[PR #239](https://github.com/open-telemetry/opentelemetry-injector/pull/239) on
`open-telemetry/opentelemetry-injector` implements OTEP #4793 modular packaging.
It adds the build scripts, configuration files, CI workflows, and integration
tests to produce five system packages (DEB + RPM):

| Package | Description |
|---------|-------------|
| `opentelemetry-injector` | LD_PRELOAD injector (`libotelinject.so` + config) |
| `opentelemetry-java-autoinstrumentation` | Java agent (javaagent.jar) |
| `opentelemetry-nodejs-autoinstrumentation` | Node.js agent (npm package) |
| `opentelemetry-dotnet-autoinstrumentation` | .NET agent (GitHub release) |
| `opentelemetry` | Meta-package (depends on all above) |

This plan describes how to move **all** packaging machinery and package content
into `mmanciop/opentelemetry-packages`, while the injector source code and
binary build remain in `open-telemetry/opentelemetry-injector`.

### Key Design Decisions

1. **All packages are built in this repo**, including the `opentelemetry-injector`
   package. The injector repo only produces the raw `libotelinject.so` binary.
2. **The injector binary is obtained from opentelemetry-injector GitHub releases**
   (downloaded by the packaging scripts/CI).
3. **GitHub Pages on `mmanciop/opentelemetry-packages`** serves as the initial
   APT/YUM repository (expected to migrate later).
4. **`conf.d/` support in `config.zig`** (also part of PR #239) is a prerequisite
   that must be merged separately in the injector repo. This plan tracks it as a
   dependency but does not implement it.

---

## Prerequisites (external to this repo)

- [ ] The injector repo merges the `src/config.zig` and `src/dotnet.zig` changes
  from PR #239 that add `conf.d/` directory scanning. Without this, the drop-in
  config pattern used by language agent packages won't work at runtime.
- [ ] The injector repo publishes releases that include `libotelinject_amd64.so`
  and `libotelinject_arm64.so` as release assets (this is the existing release
  workflow behavior).

---

## Phase 1: Repository Structure

Create the following directory layout in `mmanciop/opentelemetry-packages`:

```
opentelemetry-packages/
├── .github/
│   └── workflows/
│       ├── build.yml                    # CI: build packages + integration tests
│       └── publish-repos.yml            # CD: deploy APT/YUM repos to GitHub Pages
├── .gitignore
├── Makefile                             # Top-level build orchestration
├── LICENSE                              # (already exists)
├── README.md                            # (update existing)
├── CONTRIBUTING.md
├── RELEASING.md
├── packaging/
│   ├── java-agent-release.txt           # Pinned Java agent version
│   ├── nodejs-agent-release.txt         # Pinned Node.js agent version
│   ├── dotnet-agent-release.txt         # Pinned .NET agent version
│   ├── injector-release.txt             # Pinned injector release tag to download
│   ├── common/
│   │   ├── fpm/                         # FPM Docker image for building packages
│   │   │   ├── Dockerfile
│   │   │   ├── Gemfile
│   │   │   ├── Gemfile.lock
│   │   │   └── install-deps.sh
│   │   ├── scripts/
│   │   │   ├── postinstall-injector.sh
│   │   │   └── preuninstall-injector.sh
│   │   ├── injector/
│   │   │   ├── otelinject.conf
│   │   │   ├── default_env.conf
│   │   │   ├── opentelemetry-injector.8.tmpl
│   │   │   └── README.md
│   │   ├── java/
│   │   │   ├── injector.conf
│   │   │   ├── otel-config.yaml
│   │   │   ├── opentelemetry-java.1.tmpl
│   │   │   └── README.md
│   │   ├── nodejs/
│   │   │   ├── injector.conf
│   │   │   ├── otel-config.yaml
│   │   │   ├── opentelemetry-nodejs.1.tmpl
│   │   │   └── README.md
│   │   └── dotnet/
│   │       ├── injector.conf
│   │       ├── otel-config.yaml
│   │       ├── opentelemetry-dotnet.1.tmpl
│   │       └── README.md
│   ├── deb/
│   │   ├── common.sh                   # Shared DEB packaging functions
│   │   ├── injector/
│   │   │   ├── build.sh
│   │   │   └── copyright
│   │   ├── java/
│   │   │   ├── build.sh
│   │   │   └── copyright
│   │   ├── nodejs/
│   │   │   ├── build.sh
│   │   │   └── copyright
│   │   ├── dotnet/
│   │   │   ├── build.sh
│   │   │   └── copyright
│   │   └── meta/
│   │       └── build.sh
│   ├── rpm/
│   │   ├── common.sh                   # Shared RPM packaging functions
│   │   ├── injector/
│   │   │   └── build.sh
│   │   ├── java/
│   │   │   └── build.sh
│   │   ├── nodejs/
│   │   │   └── build.sh
│   │   ├── dotnet/
│   │   │   └── build.sh
│   │   └── meta/
│   │       └── build.sh
│   ├── repo/
│   │   ├── generate-apt-repo.sh
│   │   ├── generate-rpm-repo.sh
│   │   └── index.html                  # Landing page template
│   └── tests/
│       ├── deb/
│       │   ├── java/Dockerfile
│       │   ├── nodejs/Dockerfile
│       │   └── dotnet/Dockerfile
│       ├── rpm/
│       │   ├── java/Dockerfile
│       │   ├── nodejs/Dockerfile
│       │   └── dotnet/Dockerfile
│       └── shared/
│           ├── determine-tomcat-download-url.sh
│           ├── java/test.sh
│           ├── nodejs/
│           │   ├── app.js
│           │   └── test.sh
│           └── dotnet/
│               ├── DotNetTestApp.csproj
│               ├── *.cs
│               └── test.sh
└── build/                               # (gitignored) build output directory
    ├── packages/                        # Built .deb and .rpm files
    └── local-repo/                      # Local APT/YUM repos for testing
```

### Files unique to this repo (not in PR #239)

- **`packaging/injector-release.txt`**: New file that pins the
  `opentelemetry-injector` release tag (e.g., `v0.7.0`) from which to download
  the binary. This replaces the tight coupling where the Makefile built the
  binary itself.

---

## Phase 2: Port Packaging Content (direct copy from PR #239)

These files are copied verbatim (or with minimal path adjustments) from the PR:

### 2a. Package configuration and content files
- `packaging/common/injector/otelinject.conf`
- `packaging/common/injector/default_env.conf`
- `packaging/common/injector/opentelemetry-injector.8.tmpl`
- `packaging/common/injector/README.md`
- `packaging/common/java/injector.conf`
- `packaging/common/java/otel-config.yaml`
- `packaging/common/java/opentelemetry-java.1.tmpl`
- `packaging/common/java/README.md`
- `packaging/common/nodejs/injector.conf`
- `packaging/common/nodejs/otel-config.yaml`
- `packaging/common/nodejs/opentelemetry-nodejs.1.tmpl`
- `packaging/common/nodejs/README.md`
- `packaging/common/dotnet/injector.conf`
- `packaging/common/dotnet/otel-config.yaml`
- `packaging/common/dotnet/opentelemetry-dotnet.1.tmpl`
- `packaging/common/dotnet/README.md`
- `packaging/common/scripts/postinstall-injector.sh`
- `packaging/common/scripts/preuninstall-injector.sh`

### 2b. FPM Docker build infrastructure
- `packaging/common/fpm/Dockerfile`
- `packaging/common/fpm/Gemfile`
- `packaging/common/fpm/Gemfile.lock`
- `packaging/common/fpm/install-deps.sh`

### 2c. Build scripts (DEB + RPM)
- `packaging/deb/common.sh`
- `packaging/deb/{injector,java,nodejs,dotnet,meta}/build.sh`
- `packaging/deb/{injector,java,nodejs,dotnet}/copyright`
- `packaging/rpm/common.sh`
- `packaging/rpm/{injector,java,nodejs,dotnet,meta}/build.sh`

### 2d. Agent release version pins
- `packaging/java-agent-release.txt`
- `packaging/nodejs-agent-release.txt`
- `packaging/dotnet-agent-release.txt`

### 2e. Repository generation scripts and templates
- `packaging/repo/generate-apt-repo.sh`
- `packaging/repo/generate-rpm-repo.sh`
- `packaging/repo/index.html`

### 2f. Integration test assets
- `packaging/tests/deb/{java,nodejs,dotnet}/Dockerfile`
- `packaging/tests/rpm/{java,nodejs,dotnet}/Dockerfile`
- `packaging/tests/shared/determine-tomcat-download-url.sh`
- `packaging/tests/shared/java/test.sh`
- `packaging/tests/shared/nodejs/{app.js,test.sh}`
- `packaging/tests/shared/dotnet/{DotNetTestApp.csproj,*.cs,test.sh}`

---

## Phase 3: Adapt the Build System

### 3a. New Makefile

Create a new `Makefile` for the packages repo. It needs to differ from PR #239's
Makefile in the following ways:

| Aspect | PR #239 (injector repo) | Packages repo |
|--------|------------------------|---------------|
| Injector binary | Built from Zig source via `make dist` | **Downloaded** from injector GitHub release |
| Zig toolchain | Required | **Not required** |
| Injector integration tests | Runs injector-level tests | **Not included** (stays in injector repo) |
| Lint targets | `zig-fmt-check`, `shellcheck-lint` | `shellcheck-lint` only |
| Changelog tooling | `chloggen` (Go-based) | Port as-is or simplify |

**New Makefile targets:**

```
# Binary acquisition
download-injector-binary   # Download libotelinject from injector release

# Package builds (same as PR #239)
deb-package-injector
deb-package-java
deb-package-nodejs
deb-package-dotnet
deb-package-meta
deb-packages               # All DEB packages
rpm-package-injector
rpm-package-java
rpm-package-nodejs
rpm-package-dotnet
rpm-package-meta
rpm-packages               # All RPM packages
packages                   # All packages

# Testing
packaging-integration-test-deb-java
packaging-integration-test-deb-nodejs
packaging-integration-test-deb-dotnet
packaging-integration-test-rpm-java
packaging-integration-test-rpm-nodejs
packaging-integration-test-rpm-dotnet

# Local repos for manual testing
local-apt-repo
local-rpm-repo
local-repos

# Linting
shellcheck-lint

# Housekeeping
clean
```

**New `download-injector-binary` target:**

```makefile
INJECTOR_RELEASE_TAG := $(shell cat packaging/injector-release.txt)
INJECTOR_REPO := open-telemetry/opentelemetry-injector

.PHONY: download-injector-binary
download-injector-binary:
	@mkdir -p $(DIST_DIR_BINARY)
	curl -sfL "https://github.com/$(INJECTOR_REPO)/releases/download/$(INJECTOR_RELEASE_TAG)/libotelinject_$(ARCH).so" \
		-o "$(DIST_DIR_BINARY)/libotelinject_$(ARCH).so"
```

The `deb-package-injector` and `rpm-package-injector` targets depend on
`download-injector-binary` instead of `dist`.

### 3b. Adapt `common.sh` scripts

The `packaging/deb/common.sh` and `packaging/rpm/common.sh` scripts need these
changes:

1. **`PKG_URL`**: Change from
   `https://github.com/open-telemetry/opentelemetry-injector` to
   `https://github.com/mmanciop/opentelemetry-packages` (and later to the
   OTel org URL).

2. **`setup_injector_buildroot()`**: The binary path
   `$REPO_DIR/dist/libotelinject_${arch}.so` remains the same — the Makefile
   downloads it to `dist/` so the existing path works.

3. **No structural changes needed** — the scripts already use relative paths
   from `REPO_DIR` so they work in either repo as long as the directory layout
   under `packaging/` is preserved.

---

## Phase 4: CI/CD Workflows

### 4a. `.github/workflows/build.yml`

New workflow adapted from PR #239's `build.yml`, with these changes:

| PR #239 step | Packages repo equivalent |
|-------------|--------------------------|
| `verify-and-build-binary` job (Zig compile) | **Replaced** by `download-injector-binary` step |
| `build-package` job | Same structure, calls `make {deb,rpm}-package` |
| `packaging-integration-tests` job | Same matrix (deb/rpm × java/nodejs/dotnet × amd64/arm64) |
| `publish-stable` job | Same (creates GitHub release with packages) |

**Workflow structure:**

```yaml
jobs:
  download-binary:
    # Downloads libotelinject from injector releases for each ARCH
    # Uploads as artifact for subsequent jobs

  build-package:
    needs: download-binary
    strategy:
      matrix:
        SYS_PACKAGE: [deb, rpm]
        ARCH: [amd64, arm64]
    # Downloads binary artifact
    # Runs make $SYS_PACKAGE-package ARCH=$ARCH
    # Uploads packages as artifacts

  packaging-integration-tests:
    needs: build-package
    strategy:
      matrix:
        SYS_PACKAGE: [deb, rpm]
        lang: [java, nodejs, dotnet]
        arch: [amd64, arm64]
        exclude:
          - lang: dotnet
            arch: arm64
    # Runs make packaging-integration-test-$SYS_PACKAGE-$lang

  publish-stable:
    if: startsWith(github.ref, 'refs/tags/')
    needs: packaging-integration-tests
    # Creates GitHub release with all packages
```

### 4b. `.github/workflows/publish-repos.yml`

Ported from PR #239 with URL adjustments:

- Repository URL changes from `open-telemetry/opentelemetry-injector` to
  `mmanciop/opentelemetry-packages`
- GitHub Pages URL becomes
  `https://mmanciop.github.io/opentelemetry-packages/`
- The `.repo` file name changes from `opentelemetry-injector.repo` to
  `opentelemetry.repo`

---

## Phase 5: Adjust Hardcoded References

Several files contain URLs or paths referencing the injector repo that need
updating:

| File | What to change |
|------|---------------|
| `packaging/deb/common.sh` | `PKG_URL` |
| `packaging/rpm/common.sh` | `PKG_URL` |
| `packaging/repo/index.html` | Template uses `@@GITHUB_REPO@@` (auto-replaced by CI) — no change needed |
| `packaging/common/injector/README.md` | Links to documentation |
| `RELEASING.md` | GitHub Pages URLs, workflow references |
| `CONTRIBUTING.md` | Build instructions (remove Zig references, adjust make targets) |

---

## Phase 6: Documentation Updates

### 6a. `README.md`
Update from the current seed description to document:
- What this repo does (builds and publishes OTel system packages)
- Available packages and how to install them
- How to build locally
- Relationship to the injector repo

### 6b. `CONTRIBUTING.md`
Adapted from the injector repo's CONTRIBUTING.md, removing Zig-specific
instructions and focusing on packaging:
- Prerequisites: Docker, Make
- How to build packages locally
- How to run integration tests
- How to update agent versions (editing `*-release.txt` files)

### 6c. `RELEASING.md`
Describes the release process:
- Tagging triggers CI build → packages → GitHub release → repo publish
- How to update the injector binary version
- How to update language agent versions

---

## Implementation Order

1. **Phase 1**: Create directory structure and `.gitignore`
2. **Phase 2**: Copy all packaging files from PR #239
3. **Phase 3**: Create the new `Makefile` and adapt `common.sh`
4. **Phase 4**: Create CI workflows
5. **Phase 5**: Update hardcoded references
6. **Phase 6**: Update documentation

Phases 2 + 5 can be combined (copy files with modifications in one pass).

---

## Out of Scope

- **Cleanup of the injector repo** (removing packaging code after migration) —
  explicitly deferred as future work.
- **`config.zig` changes** — must be merged in the injector repo independently.
- **GPG signing of packages** — future enhancement.
- **Renovate/Dependabot for agent version pins** — future enhancement.
- **Python/Ruby/PHP agent packages** — stretch goals per the Packaging SIG spec.
