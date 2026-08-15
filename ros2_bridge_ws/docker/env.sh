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

# -- Docker Registry Configuration (for multi-layer builds) --
export IMAGE_BASE_NOETIC_HUMBLE="ghcr.io/teamsobits/ros1_base:noetic-humble"
export IMAGE_MSG_BRIDGE_BASE="ghcr.io/teamsobits/msg_bridge_base:latest"

# --- Do not modify below this line ---

# -- User and Group IDs --
export USERNAME=$(whoami)
export LOCAL_UID=$(id -u)
export LOCAL_GID=$(id -g)

# -- Render group GID (for GPU access). Falls back to 0 (root) if missing on host. --
export RENDER_GID=$(getent group render | cut -d: -f3)
export RENDER_GID=${RENDER_GID:-0}

# -- Naming --
export IMAGE_NAME="sobits/ros2-bridge:${COMPUTE_TYPE}-ubuntu${UBUNTU_VERSION}-ros${ROS_DISTRO}"
export CONTAINER_NAME=$(basename $(dirname $(pwd)))
