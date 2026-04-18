FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY "packaging/tests/shared/dotnet/DotNetTestApp.csproj" .
RUN dotnet restore "DotNetTestApp.csproj"
COPY "packaging/tests/shared/dotnet/*.cs" .
RUN dotnet build "DotNetTestApp.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "DotNetTestApp.csproj" -c Release -o /app/publish

FROM registry.access.redhat.com/ubi8/ubi:latest AS final

ARG ARCH=amd64
ARG RPM_ARCH=x86_64

ENV LANG=C.UTF-8

# Install .NET runtime from Microsoft's RHEL 8 repo
RUN dnf -y update && \
    dnf -y install wget && \
    rpm -Uvh https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm && \
    dnf -y install dotnet-runtime-9.0 && \
    dnf clean all

ADD https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.128.0/otelcol-contrib_0.128.0_linux_${ARCH}.rpm otelcol-contrib.rpm
RUN rpm -i otelcol-contrib.rpm

COPY build/packages/opentelemetry-injector-*-1.${RPM_ARCH}.rpm injector.rpm
COPY build/packages/opentelemetry-dotnet-autoinstrumentation-*-1.${RPM_ARCH}.rpm dotnet-agent.rpm

RUN rpm -i injector.rpm dotnet-agent.rpm

RUN echo /usr/lib/opentelemetry/injector/libotelinject.so >> /etc/ld.so.preload

COPY --from=publish /app/publish .
COPY packaging/tests/shared/dotnet/test.sh test.sh

CMD ["./test.sh"]
