#!/bin/bash

xhost + >/dev/null 2>&1

# Extract the domain between /home and the username if exists
DOMAIN=$(echo "$HOME" | sed -n 's|/home/\(.*\)/'"$USER"'.*|\1|p')

# Set DOMAIN to an empty string if no domain is found
DOMAIN=${DOMAIN:+/$DOMAIN}

IMAGE_NAME=${1:-"blender:4.1"}

# If no image name was provided as an argument, prompt the user
if [[ -z "$1" ]]; then
    echo "No Blender image provided. Defaulting to image $IMAGE_NAME."

    # Prompt the user for confirmation to proceed or specify a different Blender image
    read -p "Do you want to proceed with Blender image $IMAGE_NAME? (yes to continue, or enter a different image): " USER_INPUT

    # If the user provides a different Blender image, update the IMAGE_NAME variable
    if [[ -n "$USER_INPUT" && "$USER_INPUT" != "yes" ]]; then
        IMAGE_NAME="$USER_INPUT"
        echo "Using Blender image $IMAGE_NAME."
    else
        echo "Proceeding with Blender image $IMAGE_NAME."
    fi
fi

# Check if the Docker image exists locally
if ! docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
    echo "Error: Docker image $IMAGE_NAME does not exist."
    exit 1
fi

echo "Docker image $IMAGE_NAME found. Proceeding..."

DOMAIN_HOME="/home$DOMAIN/$USER"
CONTAINER_NAME="blender"
WELCOME_MSG="You're in a Blender Docker Container!"

mkdir -p $DOMAIN_HOME/blender

# Function to check if GPU is available
function gpu_available {
    if command -v nvidia-smi &> /dev/null; then
        if nvidia-smi -L &> /dev/null; then
            return 0
        fi
    fi
    
    return 1
}

if docker ps --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
    # Enter the Docker container
    echo "Exec existing container: $CONTAINER_NAME."
    echo $WELCOME_MSG
    docker exec -it $CONTAINER_NAME /bin/bash
else
    docker_run_cmd=(
            "docker run"
            "--name $CONTAINER_NAME"
            "--privileged"
            "--hostname $CONTAINER_NAME"
            "--add-host=$CONTAINER_NAME=127.0.0.1"
            "-it"
            "--rm"
            "--network=host"
            "--ipc=host"
            "-v /tmp/.X11-unix:/tmp/.X11-unix"
            "-v /dev*:/dev*" 
            "-v $DOMAIN_HOME/.Xauthority:/home/$USER/.Xauthority"
            "--mount src=$DOMAIN_HOME/blender,target=/home/$USER/blender,type=bind"
            "-e DISPLAY=$DISPLAY"
            "-e "TERM=xterm-256color""
        )

    # Add GPU-related options if GPU is available
    if gpu_available; then
        echo "A GPU has been identified."
        docker_run_cmd+=(
            "--gpus all"
            "-e NVIDIA_DRIVER_CAPABILITIES=all"
            "--runtime=nvidia"
        )
    fi

    docker_run_cmd+=($IMAGE_NAME)

    # Run Docker container with the constructed command
    echo "Run container: $CONTAINER_NAME. Exiting this terminal will remove the running container."
    echo "Mounted volume: $DOMAIN_HOME/blender"
    eval "${docker_run_cmd[@]}" 
fi
