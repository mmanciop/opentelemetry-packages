FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY "packaging/tests/shared/dotnet/DotNetTestApp.csproj" .
RUN dotnet restore "DotNetTestApp.csproj"
COPY "packaging/tests/shared/dotnet/*.cs" .
RUN dotnet build "DotNetTestApp.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "DotNetTestApp.csproj" -c Release -o /app/publish

FROM ubuntu:24.04 AS final

ARG ARCH=amd64

ENV LANG=C.UTF-8

RUN apt-get update && apt-get install -y wget

RUN wget https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    rm packages-microsoft-prod.deb

RUN apt-get update && apt-get install -y dotnet-runtime-9.0

ADD https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.128.0/otelcol-contrib_0.128.0_linux_${ARCH}.deb otelcol-contrib.deb
RUN dpkg -i otelcol-contrib.deb

COPY build/packages/opentelemetry-injector_*_${ARCH}.deb injector.deb
COPY build/packages/opentelemetry-dotnet-autoinstrumentation_*_${ARCH}.deb dotnet-agent.deb

RUN dpkg -i injector.deb dotnet-agent.deb

RUN echo /usr/lib/opentelemetry/injector/libotelinject.so >> /etc/ld.so.preload

COPY --from=publish /app/publish .
COPY packaging/tests/shared/dotnet/test.sh test.sh

CMD ["./test.sh"]
