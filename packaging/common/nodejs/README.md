# OpenTelemetry Node.js Auto-Instrumentation

This package provides the OpenTelemetry Node.js Auto-Instrumentation Agent for automatic instrumentation of Node.js applications.

## Overview

The Node.js agent automatically instruments popular Node.js frameworks and libraries to collect distributed traces, metrics, and logs without requiring code changes.

## Installation

The agent is installed at `/usr/lib/opentelemetry/nodejs/`.

When combined with the `opentelemetry-injector` package, Node.js applications are automatically instrumented.

## Configuration

### Environment Variables

- `OTEL_SERVICE_NAME`: Service name for telemetry (required)
- `OTEL_EXPORTER_OTLP_ENDPOINT`: OTLP endpoint (default: http://localhost:4317)
- `OTEL_TRACES_EXPORTER`: Traces exporter (otlp, console, none)
- `OTEL_METRICS_EXPORTER`: Metrics exporter (otlp, console, none)
- `OTEL_LOGS_EXPORTER`: Logs exporter (otlp, console, none)

### Declarative Configuration

A configuration file is available at `/etc/opentelemetry/nodejs/otel-config.yaml`. To use it, set:

```bash
export OTEL_EXPERIMENTAL_CONFIG_FILE=/etc/opentelemetry/nodejs/otel-config.yaml
```

## See Also

- `opentelemetry-nodejs(1)` - Man page
- https://opentelemetry.io/docs/zero-code/js/
