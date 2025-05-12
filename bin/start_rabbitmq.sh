#!/usr/bin/env bash

# ----------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------
CONTAINER_NAME="rabbitmq"
IMAGE_NAME="rabbitmq-custom"
RABBITMQ_PORT=5672
RABBITMQ_MGMT_PORT=15672
SECRETS_DIR="$(pwd)/secrets"
SECRETS_MOUNT="/var/lib/rabbitmq/secrets"
DATA_VOLUME="rabbitmq-data"
DATA_MOUNT="/var/lib/rabbitmq"
PASSWORD_FILE="admin_password"

# ----------------------------------------------------------------------
# Helper Functions
# ----------------------------------------------------------------------
show_help() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --no-rebuild          Skip rebuilding the Docker image"
  echo "  --use-existing        Use existing container if available"
  echo "  --stop                Stop the running RabbitMQ container and exit"
  echo "  -h, --help            Display this help message and exit"
  echo ""
  echo "When run without options, the script will operate in interactive mode."
}

is_interactive() {
  [ -t 0 ]
}

container_exists() {
  docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
}

image_exists() {
  docker image inspect "${IMAGE_NAME}" >/dev/null 2>&1
}

# ----------------------------------------------------------------------
# Container Management Functions
# ----------------------------------------------------------------------
stop_container() {
  echo "Stopping ${CONTAINER_NAME} container..."
  docker stop "${CONTAINER_NAME}"
}

remove_container() {
  echo "Removing existing container..."
  docker rm "${CONTAINER_NAME}"
}

build_image() {
  echo "Building ${IMAGE_NAME} image..."
  docker build -t "${IMAGE_NAME}" .
}

start_existing_container() {
  echo "Starting existing ${CONTAINER_NAME} container..."
  docker start "${CONTAINER_NAME}"
}

handle_existing_container() {
  if [ "$USE_EXISTING" = true ]; then
    start_existing_container
    return 0
  elif is_interactive; then
    echo "${CONTAINER_NAME} container already exists."
    read -r -p "Start existing container? (y/n, default: y): " start_existing
    start_existing=${start_existing:-y}
    
    if [[ "$start_existing" =~ ^[yY]$ ]]; then
      start_existing_container
      return 0
    else
      remove_container
    fi
  else
    echo "Removing existing container to create a new one..."
    remove_container
  fi
  return 1  # Continue execution
}

handle_image_build() {
  if [ "$NO_REBUILD" = true ]; then
    echo "Skipping image build as requested..."
    return
  fi
  
  if ! image_exists; then
    echo "${IMAGE_NAME} image not found. Building..."
    build_image
  elif is_interactive && [ "$USE_EXISTING" = false ]; then
    read -r -p "Rebuild ${IMAGE_NAME} image? (y/n, default: n): " rebuild
    rebuild=${rebuild:-n}
    
    if [[ "$rebuild" =~ ^[yY]$ ]]; then
      build_image
    fi
  fi
}

# ----------------------------------------------------------------------
# Deployment Options Functions
# ----------------------------------------------------------------------
create_password_file() {
  read -r -s -p "Enter password to store in file: " file_password
  echo ""  # Add newline after hidden input
  
  echo "$file_password" > "${SECRETS_DIR}/${PASSWORD_FILE}"
  chmod 600 "${SECRETS_DIR}/${PASSWORD_FILE}"
  echo "Password file created."
}

run_with_auto_password() {
  echo "Starting RabbitMQ with auto-generated password..."
  docker run -d \
    --name "${CONTAINER_NAME}" \
    -p "${RABBITMQ_PORT}:${RABBITMQ_PORT}" \
    -p "${RABBITMQ_MGMT_PORT}:${RABBITMQ_MGMT_PORT}" \
    -v "${SECRETS_DIR}:${SECRETS_MOUNT}" \
    -v "${DATA_VOLUME}:${DATA_MOUNT}" \
    "${IMAGE_NAME}"
}

run_with_manual_password() {
  if ! is_interactive; then
    echo "Error: Manual password option requires interactive mode"
    exit 1
  fi
  
  read -r -s -p "Enter password for RabbitMQ admin user: " password
  echo ""  # Add newline after hidden input
  
  echo "Starting RabbitMQ with specified password..."
  docker run -d \
    --name "${CONTAINER_NAME}" \
    -p "${RABBITMQ_PORT}:${RABBITMQ_PORT}" \
    -p "${RABBITMQ_MGMT_PORT}:${RABBITMQ_MGMT_PORT}" \
    -e RABBITMQ_ADMIN_USER=admin \
    -e RABBITMQ_ADMIN_PASSWORD="$password" \
    -v "${SECRETS_DIR}:${SECRETS_MOUNT}" \
    -v "${DATA_VOLUME}:${DATA_MOUNT}" \
    "${IMAGE_NAME}"
}

run_with_password_file() {
  if [ -f "${SECRETS_DIR}/${PASSWORD_FILE}" ]; then
    echo "Starting RabbitMQ with password from file..."
  else
    if is_interactive; then
      echo "Password file not found. Create one now? (y/n)"
      read -r create_file
      
      if [[ "$create_file" =~ ^[yY]$ ]]; then
        create_password_file
      else
        echo "Aborted: Password file is required for this option."
        exit 1
      fi
    else
      echo "Error: Option requires password file to be present in non-interactive mode."
      exit 1
    fi
  fi
  
  docker run -d \
    --name "${CONTAINER_NAME}" \
    -p "${RABBITMQ_PORT}:${RABBITMQ_PORT}" \
    -p "${RABBITMQ_MGMT_PORT}:${RABBITMQ_MGMT_PORT}" \
    -v "${SECRETS_DIR}:${SECRETS_MOUNT}" \
    -v "${DATA_VOLUME}:${DATA_MOUNT}" \
    "${IMAGE_NAME}"
}

deploy_rabbitmq() {
  local choice=1
  
  if is_interactive; then
    echo "Choose RabbitMQ deployment option:"
    echo "1) Run with auto-generated password (default)"
    echo "2) Run with a manually specified password"
    echo "3) Use manually created password file"
    read -r -p "Enter option [1-3] (default: 1): " choice
    choice=${choice:-1}
  else
    echo "Non-interactive mode: Using auto-generated password..."
  fi
  
  case $choice in
    1) run_with_auto_password ;;
    2) run_with_manual_password ;;
    3) run_with_password_file ;;
    *)
      echo "Invalid option. Exiting."
      exit 1
      ;;
  esac
}

# ----------------------------------------------------------------------
# Main Script
# ----------------------------------------------------------------------
# Parse command line arguments
NO_REBUILD=false
USE_EXISTING=false
STOP_CONTAINER=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-rebuild)
      NO_REBUILD=true
      shift
      ;;
    --use-existing)
      USE_EXISTING=true
      shift
      ;;
    --stop)
      STOP_CONTAINER=true
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

# Handle stop request
if [ "$STOP_CONTAINER" = true ]; then
  stop_container
  exit 0
fi

# Create the secrets directory if it doesn't exist
mkdir -p "${SECRETS_DIR}"

# Build image if needed
handle_image_build

# Check if container exists and handle accordingly
if container_exists; then
  if handle_existing_container; then
    exit 0
  fi
fi

# Deploy RabbitMQ
deploy_rabbitmq