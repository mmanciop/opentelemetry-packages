FROM registry.access.redhat.com/ubi9/ubi:latest

ARG ARCH=amd64
ARG RPM_ARCH=x86_64
ARG tomcat_download_url

ENV LANG=C.UTF-8

RUN dnf -y update && \
    dnf -y install java-17-openjdk wget && \
    dnf clean all

ADD ${tomcat_download_url} apache-tomcat.tar.gz
RUN tar xzvf apache-tomcat.tar.gz && mv apache-tomcat-10.* apache-tomcat

ADD https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.128.0/otelcol-contrib_0.128.0_linux_${ARCH}.rpm otelcol-contrib.rpm
RUN rpm -i otelcol-contrib.rpm

COPY build/packages/opentelemetry-injector-*-1.${RPM_ARCH}.rpm injector.rpm
COPY build/packages/opentelemetry-java-autoinstrumentation-*-1.noarch.rpm java-agent.rpm

RUN rpm -i injector.rpm java-agent.rpm

RUN echo /usr/lib/opentelemetry/injector/libotelinject.so >> /etc/ld.so.preload

COPY packaging/tests/shared/java/test.sh test.sh

CMD ["./test.sh"]
