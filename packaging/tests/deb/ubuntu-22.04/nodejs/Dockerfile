FROM ubuntu:22.04

ARG ARCH=amd64

# Ubuntu 22.04 ships Node.js 12 which is too old; use NodeSource for Node.js 18
RUN apt-get update && apt-get install -y ca-certificates curl gnupg
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
      | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main" \
      > /etc/apt/sources.list.d/nodesource.list
RUN apt-get update && apt-get install -y nodejs wget

RUN mkdir my_express_app && \
    cd my_express_app && \
    npm init -y && \
    npm install express --save

ADD https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.128.0/otelcol-contrib_0.128.0_linux_${ARCH}.deb otelcol-contrib.deb
RUN dpkg -i otelcol-contrib.deb

COPY build/packages/opentelemetry-injector_*_${ARCH}.deb injector.deb
COPY build/packages/opentelemetry-nodejs-autoinstrumentation_*_all.deb nodejs-agent.deb

RUN dpkg -i injector.deb nodejs-agent.deb

RUN echo /usr/lib/opentelemetry/injector/libotelinject.so >> /etc/ld.so.preload

COPY packaging/tests/shared/nodejs/app.js my_express_app/app.js
COPY packaging/tests/shared/nodejs/test.sh test.sh

CMD ["./test.sh"]
