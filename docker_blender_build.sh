#!/bin/bash
shopt -s expand_aliases

# Get the current user's UID and GID
uid=$(id -u)
gid=$(id -g)

# Get the current Ubuntu release version if not provided by the user
LOCAL_UBUNTU_RELEASE=$(lsb_release -r -s)
UBUNTU_RELEASE=${2:-$LOCAL_UBUNTU_RELEASE}

# Check if a Blender version is passed; if not, assign a default value
BLENDER_VERSION=${1:-"4.1.1"}

# If no image name was provided as an argument, prompt the user
if [[ -z "$1" ]]; then
    echo "No Blender version provided. Defaulting to version $BLENDER_VERSION."

    # Prompt the user for confirmation to proceed or specify a different Blender image
    read -p "Do you want to proceed with Blender version $BLENDER_VERSION? (yes to continue, or enter a different image): " USER_INPUT

    # If the user provides a different Blender image, update the IMAGE_NAME variable
    if [[ -n "$USER_INPUT" && "$USER_INPUT" != "yes" ]]; then
        BLENDER_VERSION="$USER_INPUT"
        echo "Using Blender version $BLENDER_VERSION."
    else
        echo "Proceeding with Blender image $BLENDER_VERSION."
    fi
fi

# Inform the user about the versions being used
echo "No Ubuntu release provided. Defaulting to locally identified release $UBUNTU_RELEASE."

# Prompt the user for confirmation to proceed or specify a different Ubuntu release
read -p "Do you want to proceed with Ubuntu release $UBUNTU_RELEASE? (yes to continue, or enter a different release): " UBUNTU_INPUT

# If the user provides a different Ubuntu release, update the UBUNTU_RELEASE variable
if [[ -n "$UBUNTU_INPUT" && "$UBUNTU_INPUT" != "yes" ]]; then
    UBUNTU_RELEASE="$UBUNTU_INPUT"
    echo "Using Ubuntu release $UBUNTU_RELEASE."
else
    echo "Proceeding with Ubuntu release $UBUNTU_RELEASE."
fi

# Extract the major and minor version from the Blender version (e.g., 4.1 from 4.1.1)
BLENDER_MAJOR=$(echo "$BLENDER_VERSION" | awk -F. '{print $1"."$2}')

# Build the Docker image with the specified or default arguments
docker build -f Dockerfile \
        --build-arg UBUNTU_RELEASE=$UBUNTU_RELEASE \
        --build-arg BLENDER_MAJOR=$BLENDER_MAJOR \
        --build-arg BLENDER_VERSION=$BLENDER_VERSION \
        --build-arg USERNAME=$USER \
        --build-arg USERID=$uid \
        --build-arg GROUPID=$gid \
        --tag blender:$BLENDER_MAJOR \
        .

# Clean up unused Docker objects
yes | docker system prune --force >/dev/null 2>&1
