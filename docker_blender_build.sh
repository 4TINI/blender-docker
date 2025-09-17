#!/bin/bash
# 
# Blender Docker Build Script
#
# This script builds a Docker image for Blender with user-defined
# or default Ubuntu and Blender versions. It ensures correct user
# permissions inside the container and provides interactive prompts
# for customization.
#
# Usage:
#   ./build_blender.sh [BLENDER_VERSION] [UBUNTU_RELEASE]
#
# Example:
#   ./build_blender.sh 4.1.1 22.04
#
# Options:
#   -h, --help    Show this help message and exit.
#
# Defaults:
#   BLENDER_VERSION = 4.1.1
#   UBUNTU_RELEASE = (detected from host system)
#

set -euo pipefail
shopt -s expand_aliases

# -------------------------------
# Helper: Show help message
# -------------------------------
show_help() {
    awk 'NR>1 && /^#/ {sub(/^# ?/, ""); print; next} NR>1 {exit}' "$0"
}

# -------------------------------
# Parse arguments
# -------------------------------
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    show_help
    exit 0
fi

uid=$(id -u)
gid=$(id -g)

LOCAL_UBUNTU_RELEASE=$(lsb_release -r -s)
BLENDER_VERSION=${1:-"4.1.1"}
UBUNTU_RELEASE=${2:-$LOCAL_UBUNTU_RELEASE}

# -------------------------------
# Confirm Blender version
# -------------------------------
if [[ -z "${1:-}" ]]; then
    echo "No Blender version provided. Defaulting to version $BLENDER_VERSION."
    read -p "Do you want to proceed with Blender version $BLENDER_VERSION? (yes to continue, or enter a different version): " USER_INPUT
    if [[ -n "$USER_INPUT" && "$USER_INPUT" != "yes" ]]; then
        BLENDER_VERSION="$USER_INPUT"
    fi
    echo "Using Blender version $BLENDER_VERSION."
fi

# -------------------------------
# Confirm Ubuntu release
# -------------------------------
echo "No Ubuntu release provided. Defaulting to locally identified release $UBUNTU_RELEASE."
read -p "Do you want to proceed with Ubuntu release $UBUNTU_RELEASE? (yes to continue, or enter a different release): " UBUNTU_INPUT
if [[ -n "$UBUNTU_INPUT" && "$UBUNTU_INPUT" != "yes" ]]; then
    UBUNTU_RELEASE="$UBUNTU_INPUT"
fi
echo "Using Ubuntu release $UBUNTU_RELEASE."

# -------------------------------
# Extract Blender major version
# -------------------------------
BLENDER_MAJOR=$(echo "$BLENDER_VERSION" | awk -F. '{print $1"."$2}')

# -------------------------------
# Build Docker image
# -------------------------------
docker build -f Dockerfile \
        --build-arg UBUNTU_RELEASE=$UBUNTU_RELEASE \
        --build-arg BLENDER_MAJOR=$BLENDER_MAJOR \
        --build-arg BLENDER_VERSION=$BLENDER_VERSION \
        --build-arg USERNAME=$USER \
        --build-arg USERID=$uid \
        --build-arg GROUPID=$gid \
        --tag blender:$BLENDER_MAJOR \
        .

# -------------------------------
# Cleanup unused Docker objects
# -------------------------------
yes | docker system prune --force >/dev/null 2>&1
echo "Docker build complete. Image tagged as blender-source:$BLENDER_MAJOR"
