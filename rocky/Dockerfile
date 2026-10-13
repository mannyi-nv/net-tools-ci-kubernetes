FROM mannydevops/rocky9-net-tools-ci:V1.0

WORKDIR /build

# Pre-install all required build tools and enable CRB repository
RUN dnf install -y \
        rpm-build \
        rpmdevtools \
        dnf-plugins-core \
        wget && \
    dnf config-manager --set-enabled crb && \
    dnf makecache

COPY net-tools-docker.sh .
RUN chmod +x net-tools-docker.sh

CMD ["./net-tools-docker.sh"]


