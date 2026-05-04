#!/bin/bash
set -e

# Docker image names
ROS1_BASE_IMAGE="ghcr.io/teamsobits/ros1_base:noetic-humble"
MSG_BRIDGE_BASE_IMAGE="ghcr.io/teamsobits/msg_bridge_base"

# -- Mode flags --
MODE="pull"
PUSH=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pull)
      MODE="pull"
      shift
      ;;
    --msg-build)
      MODE="msg-build"
      shift
      ;;
    --full)
      MODE="full"
      shift
      ;;
    --push)
      PUSH=true
      shift
      ;;
    -h|--help)
      cat <<USAGE
Usage: $0 [--pull | --msg-build | --full] [--push]

Build Modes:
  --pull              (default) Fast development: pull msg_bridge_base from ghcr.io,
                      rebuild application layer only (~1 min)

  --msg-build         Environment update: pull ros1_base, rebuild messages and
                      ros1_bridge locally (~20-30 min)

  --msg-build --push  Same as above, then push msg_bridge_base to ghcr.io
                      (requires GITHUB_USER and GITHUB_TOKEN)

  --full              Full rebuild: build ros1_base locally, then messages and bridge
                      (~40+ min, for maintenance and validation)

  --full --push       Same as above, then push ros1_base to ghcr.io
                      (requires GITHUB_USER and GITHUB_TOKEN)

Environment Variables (for --push):
  GITHUB_USER         GitHub username (required for push)
  GITHUB_TOKEN        GitHub PAT with 'write:packages' scope (required for push)

Examples:
  # Regular development
  bash build.sh --pull

  # After updating message definitions
  bash build.sh --msg-build --push

  # Full validation
  bash build.sh --full
USAGE
      exit 0
      ;;
    *)
      echo "Error: unknown argument '$1'"; exit 1
      ;;
  esac
done

# Validate mode and push combinations
if [[ "$PUSH" == "true" && "$MODE" == "pull" ]]; then
  echo "Error: --push cannot be used with --pull mode"; exit 1
fi

# Load environment variables
if [[ -f "./env.sh" ]]; then
  source ./env.sh
else
  echo "Error: env.sh not found"; exit 1
fi

# Helper function: timestamp for image tagging
get_timestamp() {
  date +%Y-%m-%d-%H%M%S
}

# Helper function: docker login
docker_login_ghcr() {
  if [[ -z "${GITHUB_USER}" || -z "${GITHUB_TOKEN}" ]]; then
    echo "Error: GITHUB_USER and GITHUB_TOKEN environment variables are required for --push"
    echo "       The token must have 'write:packages' scope."
    exit 1
  fi
  echo "[build.sh] Logging in to ghcr.io..."
  echo "${GITHUB_TOKEN}" | docker login ghcr.io -u "${GITHUB_USER}" --password-stdin
}

# ============================================================================
# LAYER 1: ros1_base preparation
# ============================================================================
if [[ "$MODE" == "pull" || "$MODE" == "msg-build" ]]; then
  echo "[build.sh] Pulling ${ROS1_BASE_IMAGE}..."
  docker pull "${ROS1_BASE_IMAGE}"
elif [[ "$MODE" == "full" ]]; then
  echo "[build.sh] Building ros1_base locally (this may take 30+ minutes)..."
  docker build \
    --build-arg USERNAME="${USERNAME}" \
    --build-arg LOCAL_UID="${LOCAL_UID}" \
    --build-arg LOCAL_GID="${LOCAL_GID}" \
    --target ros1_base \
    -t "${ROS1_BASE_IMAGE}" \
    -f Dockerfile \
    .

  if [[ "$PUSH" == "true" ]]; then
    docker_login_ghcr
    echo "[build.sh] Pushing ${ROS1_BASE_IMAGE}..."
    docker push "${ROS1_BASE_IMAGE}"
  fi
fi

# ============================================================================
# LAYER 2: msg_bridge_base (messages + ros1_bridge)
# ============================================================================
if [[ "$MODE" == "msg-build" ]]; then
  TIMESTAMP=$(get_timestamp)
  MSG_BRIDGE_IMAGE_LATEST="${MSG_BRIDGE_BASE_IMAGE}:latest"
  MSG_BRIDGE_IMAGE_TAGGED="${MSG_BRIDGE_BASE_IMAGE}:${TIMESTAMP}"

  echo "[build.sh] Building msg_bridge_base locally (this may take 20-30 minutes)..."
  docker build \
    --build-arg USERNAME="${USERNAME}" \
    --build-arg LOCAL_UID="${LOCAL_UID}" \
    --build-arg LOCAL_GID="${LOCAL_GID}" \
    --build-arg ROS_DOMAIN_ID="${ROS_DOMAIN_ID}" \
    --target msg_bridge_base \
    --tag "${MSG_BRIDGE_IMAGE_LATEST}" \
    --tag "${MSG_BRIDGE_IMAGE_TAGGED}" \
    --build-arg DOCKER_BUILDKIT=1 \
    -f Dockerfile \
    .

  if [[ "$PUSH" == "true" ]]; then
    docker_login_ghcr
    echo "[build.sh] Pushing ${MSG_BRIDGE_IMAGE_LATEST}..."
    docker push "${MSG_BRIDGE_IMAGE_LATEST}"
    echo "[build.sh] Pushing ${MSG_BRIDGE_IMAGE_TAGGED}..."
    docker push "${MSG_BRIDGE_IMAGE_TAGGED}"
    echo "[build.sh] msg_bridge_base pushed successfully (tag: ${TIMESTAMP})"
  fi

  # Skip the final image build for msg-build mode
  echo "Done. msg_bridge_base is ready."
  exit 0
fi

# Delete existing .env file if it exists
if [[ -f ".env" ]]; then
  rm .env
fi

# Generate .env file for Docker Compose
cat > .env <<EOF
LOCAL_UID=${LOCAL_UID}
LOCAL_GID=${LOCAL_GID}
RENDER_GID=${RENDER_GID}
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

# ============================================================================
# LAYER 3: final (application layer - scripts, configuration)
# ============================================================================
echo "[build.sh] Building application layer (final image)..."
export DOCKER_BUILDKIT=1

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

echo "Done."
