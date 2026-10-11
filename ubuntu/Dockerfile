FROM mannydevops/ubuntu24.04-net-tools-ci:V1.0

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /build

COPY net-tools-docker.sh .

RUN chmod +x net-tools-docker.sh

CMD ["./net-tools-docker.sh"]
