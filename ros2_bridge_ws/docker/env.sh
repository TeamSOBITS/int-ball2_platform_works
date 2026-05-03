#!/bin/bash

# -- Base System Configuration --
export UBUNTU_VERSION="22.04"

# -- GPU / CPU Configuration --
export COMPUTE_TYPE="gpu"    # Options: "cpu" or "gpu"
export CUDA_VERSION="12.8.1" # Required only if COMPUTE_TYPE is "gpu"

# -- ROS Configuration --
export ROS_DISTRO="humble"
export ROS_DOMAIN_ID="0"
export ROS_WORKSPACE="colcon_ws"

# --- Do not modify below this line ---

# -- User and Group IDs --
export USERNAME="sobits"
export LOCAL_UID=$(id -u)
export LOCAL_GID=$(id -g)

# -- Naming --
export IMAGE_NAME="sobits/ros2-bridge:${COMPUTE_TYPE}-ubuntu${UBUNTU_VERSION}-ros${ROS_DISTRO}"
export CONTAINER_NAME=$(basename $(dirname $(pwd)))
