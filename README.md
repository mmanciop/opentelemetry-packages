# OpenTelemetry Packages

This repository builds and publishes DEB and RPM system packages for
[OpenTelemetry](https://opentelemetry.io/) automatic instrumentation on Linux,
implementing the [System Packages project](https://github.com/mmanciop/opentelemetry-community/blob/d1c874b765181646864366e18b74f10663267dad/projects/packaging.md)
(OTEP #4793).

This repository is meant to be transferred to the
[OpenTelemetry organization](https://github.com/open-telemetry) when the
Packaging SIG is launched.

## Available Packages

| Package | Description |
|---------|-------------|
| `opentelemetry` | Meta-package that installs all components |
| `opentelemetry-injector` | LD_PRELOAD-based auto-instrumentation injector |
| `opentelemetry-java-autoinstrumentation` | Java agent for automatic instrumentation |
| `opentelemetry-nodejs-autoinstrumentation` | Node.js agent for automatic instrumentation |
| `opentelemetry-dotnet-autoinstrumentation` | .NET agent for automatic instrumentation |

## Quick Install

```bash
# Debian/Ubuntu
echo "deb [trusted=yes] https://mmanciop.github.io/opentelemetry-packages/debian stable main" \
  | sudo tee /etc/apt/sources.list.d/opentelemetry.list
sudo apt update && sudo apt install opentelemetry

# RHEL/Fedora/Amazon Linux
sudo curl -o /etc/yum.repos.d/opentelemetry.repo \
  https://mmanciop.github.io/opentelemetry-packages/rpm/opentelemetry.repo
sudo dnf install opentelemetry
```

## Architecture

The injector binary (`libotelinject.so`) is built in the
[opentelemetry-injector](https://github.com/open-telemetry/opentelemetry-injector)
repository. This repository downloads the binary from injector releases and
packages it alongside the language-specific auto-instrumentation agents.

Each language agent package installs a drop-in configuration fragment in
`/etc/opentelemetry/injector/conf.d/`, which the injector reads at runtime
to discover available agents.

## Building Locally

Prerequisites: Docker, Make, curl.

```bash
# Build all packages (DEB + RPM) for amd64
make packages

# Build only DEB packages
make deb-packages

# Build only the Java agent DEB package
make deb-package-java

# Run packaging integration tests
make packaging-integration-test-deb-java

# Create local APT/YUM repos for testing
make local-repos
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

## License

[Apache 2.0](LICENSE)
