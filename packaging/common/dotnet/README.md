# OpenTelemetry .NET Auto-Instrumentation

This package provides the OpenTelemetry .NET Auto-Instrumentation Agent for automatic instrumentation of .NET applications.

## Overview

The .NET agent automatically instruments .NET applications to collect distributed traces, metrics, and logs without requiring code changes. Both glibc and musl libc variants are included.

## Installation

The agent is installed at `/usr/lib/opentelemetry/dotnet/`.

When combined with the `opentelemetry-injector` package, .NET applications are automatically instrumented.

## Configuration

### Environment Variables

- `OTEL_SERVICE_NAME`: Service name for telemetry (required)
- `OTEL_EXPORTER_OTLP_ENDPOINT`: OTLP endpoint (default: http://localhost:4317)
- `OTEL_TRACES_EXPORTER`: Traces exporter (otlp, console, none)
- `OTEL_METRICS_EXPORTER`: Metrics exporter (otlp, console, none)
- `OTEL_LOGS_EXPORTER`: Logs exporter (otlp, console, none)

### Declarative Configuration

A configuration file is available at `/etc/opentelemetry/dotnet/otel-config.yaml`. To use it, set:

```bash
export OTEL_EXPERIMENTAL_CONFIG_FILE=/etc/opentelemetry/dotnet/otel-config.yaml
```

## See Also

- `opentelemetry-dotnet(1)` - Man page
- https://opentelemetry.io/docs/zero-code/net/
