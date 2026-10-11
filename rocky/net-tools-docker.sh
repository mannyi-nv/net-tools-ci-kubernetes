#!/bin/bash

set -e

SRPM="net-tools-2.0-0.64.20160912git.el9.src.rpm"
URL="https://dl.rockylinux.org/pub/rocky/9.8/BaseOS/source/tree/Packages/n/$SRPM"

echo "=== Installing build tools ==="

dnf install -y \
    rpm-build \
    rpmdevtools \
    dnf-plugins-core \
    wget

echo "=== Enabling CRB repository ==="

dnf config-manager --set-enabled crb

dnf makecache

echo "=== Setting up RPM build tree ==="

rpmdev-setuptree

SRPM="net-tools-2.0-0.64.20160912git.el9.src.rpm"
URL="https://dl.rockylinux.org/pub/rocky/9.8/BaseOS/source/tree/Packages/n/$SRPM"

echo "=== Installing build dependencies ==="

dnf install -y \
    rpm-build \
    rpmdevtools \
    dnf-plugins-core \
    wget

echo "=== Setting up RPM build tree ==="

rpmdev-setuptree

cd ~/rpmbuild/SRPMS

echo "=== Downloading source RPM ==="

wget -N "$URL"

echo "=== Installing build dependencies from SRPM ==="

dnf builddep -y "$SRPM"

echo "=== Building RPM ==="

rpmbuild --rebuild "$SRPM"

RPM=$(find ~/rpmbuild/RPMS -type f -name "net-tools-[0-9]*.rpm" | head -1)

echo "=== Built RPM ==="
echo "$RPM"

echo "=== Installing net-tools ==="

dnf install -y "$RPM"

echo "=== Testing ifconfig ==="

ifconfig

echo "=== ifconfig test successful ==="

echo "=== Copying RPM artifact ==="

ARTIFACT_DIR="/artifacts/build_${BUILD_NUMBER}"

mkdir -p "$ARTIFACT_DIR"
cp "$RPM" "$ARTIFACT_DIR/"

echo "Artifact copied to:"
echo "$ARTIFACT_DIR/$(basename "$RPM")"

echo "Artifact:"
ls -lh "/artifacts/build_${BUILD_NUMBER}/"

echo "=== Removing net-tools ==="