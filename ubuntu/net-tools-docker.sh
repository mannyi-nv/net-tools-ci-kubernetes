#!/bin/bash

set -e
: "${WORKSPACE:?WORKSPACE must be set by Jenkins}"

PACKAGE="net-tools"

echo "=== Updating APT package information ==="
apt update

echo "=== Downloading source package ==="
cd ~

apt-get source "$PACKAGE"

# Find the source directory created by apt-get source
SRC_DIR=$(find ~ -maxdepth 1 -type d -name "net-tools-*" | head -1)

if [[ -z "$SRC_DIR" ]]; then
    echo "ERROR: Source directory was not found"
    exit 1
fi

echo "Source directory:"
echo "$SRC_DIR"

cd "$SRC_DIR"

echo "=== Installing build dependencies ==="
apt-get build-dep -y "$PACKAGE"

echo "=== Building DEB package ==="
dpkg-buildpackage -us -uc -b

echo "=== Finding built net-tools package ==="

DEB=$(find .. -maxdepth 1 -type f \
    -name "net-tools_*.deb" \
    -print -quit)

if [[ -z "$DEB" ]]; then
    echo "ERROR: net-tools DEB package was not found"
    exit 1
fi

echo "Built DEB:"
echo "$DEB"

echo "=== Checking DEB package information ==="
dpkg-deb -I "$DEB" | grep -E 'Package:|Version:|Architecture:'

echo "=== Installing net-tools ==="
apt install -y "$DEB"

echo "=== Testing ifconfig ==="

if ifconfig; then
    echo "=== ifconfig test successful ==="
else
    echo "ERROR: ifconfig test failed"
    exit 1
fi

echo "=== Copying DEB artifact ==="

ARTIFACT_DIR="${WORKSPACE}/artifacts/ubuntu"

mkdir -p "$ARTIFACT_DIR"

cp "$DEB" "$ARTIFACT_DIR/"

echo "Artifact copied to:"

echo "$ARTIFACT_DIR/$(basename "$DEB")"

echo "Artifact:"

ls -lh "$ARTIFACT_DIR/"