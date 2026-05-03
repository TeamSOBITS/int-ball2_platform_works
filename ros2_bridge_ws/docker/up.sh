#!/bin/bash

# Load environment variables
if [[ -f ".env" ]]; then
  source .env
else
  echo ".env not found"; exit 1
fi

echo "Starting Docker container for $(if [ ${COMPUTE_TYPE} = "gpu" ]; then echo "GPU"; else echo "CPU"; fi) environment..."

PROJECT_NAME=${CONTAINER_NAME}

# Select compose files based on COMPUTE_TYPE
if [ "${COMPUTE_TYPE}" = "cpu" ]; then
  COMPOSE_FILES=(-f docker-compose.yml)
elif [ "${COMPUTE_TYPE}" = "gpu" ]; then
  COMPOSE_FILES=(-f docker-compose.yml -f docker-compose.gpu.yml)
else
  echo "Error: Invalid COMPUTE_TYPE '${COMPUTE_TYPE}' in .env"
  exit 1
fi

# Start the container
docker compose -p ${PROJECT_NAME} "${COMPOSE_FILES[@]}" up -d sobits-container
