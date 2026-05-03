#!/bin/bash
set -e

# Load environment variables
if [[ -f "./env.sh" ]]; then
  source ./env.sh
else
  echo "Error: env.sh not found"; exit 1
fi

# Delete existing .env file if it exists
if [[ -f ".env" ]]; then
  rm .env
fi

# Generate .env file for Docker Compose
cat > .env <<EOF
LOCAL_UID=${LOCAL_UID}
LOCAL_GID=${LOCAL_GID}
UBUNTU_VERSION=${UBUNTU_VERSION}
COMPUTE_TYPE=${COMPUTE_TYPE}
USERNAME=${USERNAME}
IMAGE_NAME=${IMAGE_NAME}
CONTAINER_NAME=${CONTAINER_NAME}
CUDA_VERSION=${CUDA_VERSION}
ROS_DISTRO=${ROS_DISTRO}
ROS_DOMAIN_ID=${ROS_DOMAIN_ID}
ROS_WORKSPACE=${ROS_WORKSPACE}
EOF

cat > ros_entrypoint.sh <<EOF
source /opt/ros/noetic/setup.bash
if [ -f ~/catkin_ws/devel/setup.bash ]; then
  source ~/catkin_ws/devel/setup.bash
fi
source /opt/ros/humble/setup.bash
if [ -f ~/colcon_msgs_ws/install/setup.bash ]; then
  source ~/colcon_msgs_ws/install/setup.bash
fi
if [ -f ~/ros1_bridge_ws/install/setup.bash ]; then
  source ~/ros1_bridge_ws/install/setup.bash
fi
if [ -f ~/colcon_ws/install/setup.bash ]; then
  source ~/colcon_ws/install/setup.bash
fi
source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash
export ROS_MASTER_URI=\${ROS_MASTER_URI:-http://localhost:11311}
export ROS_DOMAIN_ID=${ROS_DOMAIN_ID}
alias cb='CURRENT_DIR=`pwd` && cd ~/colcon_ws/ && colcon build --symlink-install && source ~/.bashrc && cd ${CURRENT_DIR}'
alias bridge='bash ~/bridge/cmd.sh'
EOF

if [ "${COMPUTE_TYPE}" = "gpu" ]; then
  if ! command -v nvidia-smi &> /dev/null; then
    echo "Error: nvidia-smi not found. GPU may not be available."
    exit 1
  fi
  docker compose -f docker-compose.yml -f docker-compose.gpu.yml build sobits-container
elif [ "${COMPUTE_TYPE}" = "cpu" ]; then
  docker compose -f docker-compose.yml build sobits-container
else
  echo "Error: Invalid COMPUTE_TYPE '${COMPUTE_TYPE}' in env.sh"
  exit 1
fi

rm -f ros_entrypoint.sh

echo "Done."
