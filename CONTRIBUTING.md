# How to Contribute to OpenTelemetry Packages

We'd love your help!

This project is [Apache 2.0 licensed](LICENSE) and accepts contributions via
GitHub pull requests. This document outlines conventions on development workflow,
contact points, and other resources to make it easier to get your contribution
accepted.

We gratefully welcome improvements to documentation as well as to code.

## Getting Started

### Prerequisites

* Docker version 23.0.0 or greater.
* GNU Make.
* curl.

### Makefile Commands

* `make packages` to build all RPM and Debian packages (injector, Java, Node.js,
  .NET agents, and meta-package)
* `make deb-packages` or `make rpm-packages` to build only DEB or RPM packages
  respectively
* `make deb-package-java` (or `-nodejs`, `-dotnet`, `-injector`, `-meta`) to
  build a specific DEB package
* `make packaging-integration-test-deb-java` (or `-nodejs`, `-dotnet`) to run
  integration tests against a specific language
* `make local-repos` to create local APT and YUM repositories for manual testing
* `make lint` to run shellcheck on all shell scripts
* `make clean` to remove all build artifacts

### Updating Agent Versions

Language agent versions are pinned in text files under `packaging/`:

* `packaging/injector-release.txt` - Injector binary release tag
* `packaging/java-agent-release.txt` - Java agent release tag
* `packaging/nodejs-agent-release.txt` - Node.js agent npm version
* `packaging/dotnet-agent-release.txt` - .NET agent release tag

To update an agent version, edit the corresponding file and submit a PR.

### GitHub PR Workflow

It is recommended to follow the
["GitHub Workflow"](https://guides.github.com/introduction/flow/). When using
[GitHub's CLI](https://github.com/cli/cli), here's how it typically looks:

```bash
gh repo fork github.com/mmanciop/opentelemetry-packages
git checkout -b your-feature-branch
# do your changes
git commit -sam "Add feature X"
gh pr create
```

## Contributing

Your contribution is welcome! For it to be accepted, we have a few standards
that must be followed.

### New features

Before starting the development of a new feature, please create an issue and
discuss it with the project maintainers. Features should come with documentation
and enough tests (unit and/or end-to-end).

### Bug fixes

Every bug fix should be accompanied by a test case, so that we can prevent
regressions.

### Documentation, typos, ...

They are mostly welcome!
