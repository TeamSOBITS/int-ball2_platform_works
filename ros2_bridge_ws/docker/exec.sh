#!/bin/bash

# Usage: exec.sh [--root]
#   (default)  Enter as the non-root development user (matches the host UID/GID).
#   --root     Enter as root — an escape hatch for administrative tasks
#              (e.g. system-wide apt operations). See design.md D7.
AS_ROOT=false
case "$1" in
  --root)
    AS_ROOT=true
    ;;
  "")
    ;;
  *)
    echo "Usage: $0 [--root]"; exit 1
    ;;
esac

# Load environment variables
if [[ -f ".env" ]]; then
  source .env
else
  echo ".env not found"; exit 1
fi

PROJECT_NAME=${CONTAINER_NAME}

# Check if container is running
if [ ! "$(docker ps -q -f name=${CONTAINER_NAME})" ]; then
  echo "Container ${CONTAINER_NAME} is not running."
  echo "Please run './up.sh' first to start the container."
  exit 1
fi

if [[ "$AS_ROOT" == "true" ]]; then
  echo "Entering container: ${CONTAINER_NAME} (as root)"
  docker compose -p ${PROJECT_NAME} exec -it --user root sobits-container /bin/bash
else
  echo "Entering container: ${CONTAINER_NAME} (as ${USERNAME}, UID ${LOCAL_UID})"
  docker compose -p ${PROJECT_NAME} exec -it sobits-container /bin/bash
fi
