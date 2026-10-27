FROM mannydevops/ubuntu24.04-net-tools-ci:V1.0

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /build

COPY net-tools-build.sh .

RUN chmod +x net-tools-build.sh

CMD ["./net-tools-build.sh"]
