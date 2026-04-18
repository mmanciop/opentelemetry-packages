FROM ubuntu:24.04

ARG ARCH=amd64
ARG tomcat_download_url

RUN apt-get update && apt-get install -y default-jre wget

ADD ${tomcat_download_url} apache-tomcat.tar.gz
RUN tar xzvf apache-tomcat.tar.gz && mv apache-tomcat-10.* apache-tomcat

ADD https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.128.0/otelcol-contrib_0.128.0_linux_${ARCH}.deb otelcol-contrib.deb
RUN dpkg -i otelcol-contrib.deb

COPY build/packages/opentelemetry-injector_*_${ARCH}.deb injector.deb
COPY build/packages/opentelemetry-java-autoinstrumentation_*_all.deb java-agent.deb

RUN dpkg -i injector.deb java-agent.deb

RUN echo /usr/lib/opentelemetry/injector/libotelinject.so >> /etc/ld.so.preload

COPY packaging/tests/shared/java/test.sh test.sh

CMD ["./test.sh"]
