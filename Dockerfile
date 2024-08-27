# Base Ubuntu version to use
ARG UBUNTU_RELEASE=20.04

# Base image with NVIDIA OpenGL runtime
FROM nvidia/opengl:1.1-glvnd-runtime-ubuntu${UBUNTU_RELEASE}

# Build arguments for the username, user ID, and group ID
ARG USERNAME
ARG USERID
ARG GROUPID

# Build arguments for Blender Version
ARG BLENDER_MAJOR=4.1
ARG BLENDER_VERSION=4.1.1

# Set environment variables
ENV USER=${USERNAME}
ENV DEBIAN_FRONTEND=noninteractive

# URL to download Blender
ENV BLENDER_URL=https://download.blender.org/release/Blender${BLENDER_MAJOR}/blender-${BLENDER_VERSION}-linux-x64.tar.xz

# Install essential packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        apt-transport-https \
        build-essential \
        ca-certificates \
        curl \
        dialog \
        git \
        gnupg \
        lsb-release \
        nano \
        pkg-config \
        python3-pip \
        software-properties-common \
        ssh \
        sudo \
        unzip \
        wget \
        zip && \
    # Clean up package caches and remove unnecessary files to reduce image size
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

# Modify sudoers to allow members of the sudo group to execute any command without a password
RUN sed -i /etc/sudoers -re 's/^%sudo.*/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/g'

# Create a group and user with the specified IDs, and add the user to the sudo group
RUN groupadd -g ${GROUPID} ${USERNAME} && \
    useradd ${USERNAME} \
        --create-home \
        --uid ${USERID} \
        --gid ${GROUPID} \
        --shell=/bin/bash && \
    adduser ${USERNAME} sudo 

# Create a symlink to ensure 'python' points to 'python3'
RUN ln -s /usr/bin/python3 /usr/bin/python

# Install additional dependencies for Blender and OpenCL
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libfreetype6 \
        libglu1-mesa \
        libxi6 \
        libxrender1 \
        xz-utils \
        libxkbcommon-x11-0 \
        libsm6 \
        libxext6 \
        libxrender-dev \
        libegl1-mesa \
        libegl1 \
        ocl-icd-libopencl1 && \
    # Clean up package caches and remove unnecessary files
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

# Create a symlink for the OpenCL library
RUN ln -s libOpenCL.so.1 /usr/lib/x86_64-linux-gnu/libOpenCL.so 

# Download and extract Blender
RUN curl -L ${BLENDER_URL} | tar -xJ -C /usr/local/ && \
    mv /usr/local/blender-${BLENDER_VERSION}-linux-x64 /usr/local/blender && \
    ln -s /usr/local/blender/blender /usr/bin/blender

# Copy addon activation and configuration files
COPY scripts/activate_addons.py .
COPY config/addons.yaml .

# Set the working directory to the newly created user's home directory
WORKDIR /home/${USERNAME}

# Copy the Python requirements file
COPY config/requirements.txt .

# Define the path to Blender's Python executable
ARG BLENDER_PYTHON_PATH=/usr/local/blender/${BLENDER_MAJOR}/python/bin
ARG BLENDER_LIB_PATH=/usr/local/blender/${BLENDER_MAJOR}/python/lib/python*/site-packages

RUN PYTHON_VERSION=$(python3 --version | sed 's/Python //'); \
    if [ "$(echo $PYTHON_VERSION | awk -F. '{print ($1 > 3) || ($1 == 3 && $2 >= 9)}')" -eq 1 ]; then \
        ${BLENDER_PYTHON_PATH}/python3* -m ensurepip && \
        ${BLENDER_PYTHON_PATH}/python3* -m pip install -r /home/${USERNAME}/requirements.txt --target ${BLENDER_LIB_PATH} ; \
    else \
        BLENDER_PYTHON_PATH=/usr/local/blender/${BLENDER_MAJOR}/python/bin \
        ${BLENDER_PYTHON_PATH}/python3* -m ensurepip && \
        ${BLENDER_PYTHON_PATH}/pip3 install --upgrade pip && \
        ${BLENDER_PYTHON_PATH}/pip3 install -r ./requirements.txt; \
    fi

# # Install Python packages using Blender's bundled Python
# RUN ${BLENDER_PYTHON_PATH}/python3* -m ensurepip && \
#     ${BLENDER_PYTHON_PATH}/pip3 install --upgrade pip && \
#     ${BLENDER_PYTHON_PATH}/pip3 install -r ./requirements.txt

# Copy the script for installing Blender addons
COPY scripts/install_blender_addons.py .

# Switch to the newly created user
USER ${USERNAME}

# Install Blender addons
RUN blender -b --python install_blender_addons.py

# Clean up installation scripts and temporary files
RUN rm -rf install_blender_addons.py requirements.txt && \
    sudo rm -rf /tmp/* 

# Command to run Blender with the addon activation script
CMD ["blender", "--python", "/activate_addons.py"]
