#!/usr/bin/env bash

# RabbitMQ Setup Script
# This script configures a RabbitMQ instance with secure admin credentials

# Exit immediately if a command exits with a non-zero status
set -e

# --- Constants and Configuration ---
RABBITMQ_MNESIA_BASE="/var/lib/rabbitmq"
RABBITMQ_PID_FILE="${RABBITMQ_MNESIA_BASE}/pid"
RABBITMQ_ADMIN_USER=${RABBITMQ_ADMIN_USER:-admin}
SECRETS_DIR="/var/lib/rabbitmq/secrets"
SECRET_FILE="$SECRETS_DIR/admin_password"
MIN_PASSWORD_LENGTH=8
TEMP_PASSWORD=""

export RABBITMQ_MNESIA_BASE RABBITMQ_PID_FILE

# --- Functions ---
setup_secrets_directory() {
  mkdir -p "$SECRETS_DIR"
}

validate_password_file() {
  if [ ! -s "$SECRET_FILE" ]; then
    echo "Error: Password file exists but is empty"
    exit 1
  fi

  local password_length
  password_length=$(wc -c < "$SECRET_FILE")

  if [ "$password_length" -lt "$MIN_PASSWORD_LENGTH" ]; then
    echo "Error: Password file exists but doesn't contain a valid password (minimum $MIN_PASSWORD_LENGTH characters)"
    exit 1
  fi

  TEMP_PASSWORD="$(cat "${SECRET_FILE}")"
  echo "Using existing password from secrets file"
}

save_password_to_file() {
  echo "$TEMP_PASSWORD" > "$SECRET_FILE"
  chmod 600 "$SECRET_FILE"
}

generate_random_password() {
  echo "Generating secure random password with openssl"
  TEMP_PASSWORD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32)
  save_password_to_file
  echo "Generated secure password and saved to $SECRET_FILE"
  echo "Warning: Please save this password securely as it won't be displayed again"
}

get_admin_password() {
  if [ -f "$SECRET_FILE" ]; then
    validate_password_file
  elif [ -n "$RABBITMQ_ADMIN_PASSWORD" ]; then
    echo "Using password from environment variable"
    TEMP_PASSWORD=$RABBITMQ_ADMIN_PASSWORD
    save_password_to_file
  else
    generate_random_password
  fi
}

setup_rabbitmq() {
  # Start RabbitMQ in the background
  echo "Starting RabbitMQ in the background..."
  rabbitmq-server -detached || {
    echo "Failed to start RabbitMQ"
    return 1
  }

  # Wait for RabbitMQ to start
  echo "Waiting for RabbitMQ to start..."
  if ! rabbitmqctl wait --timeout 60 "$RABBITMQ_PID_FILE"; then
    echo "RabbitMQ failed to start within timeout"
    rabbitmqctl stop || true
    return 1
  fi

  # Create admin user and set permissions
  echo "Creating admin user ${RABBITMQ_ADMIN_USER} with ${TEMP_PASSWORD}"
  rabbitmqctl add_user "$RABBITMQ_ADMIN_USER" "$TEMP_PASSWORD"
  rabbitmqctl set_user_tags "$RABBITMQ_ADMIN_USER" administrator
  rabbitmqctl set_permissions -p / "$RABBITMQ_ADMIN_USER" ".*" ".*" ".*"

  # Check if guest user exists before trying to delete
  if rabbitmqctl list_users | grep -q "guest"; then
    echo "Removing default guest user..."
    rabbitmqctl delete_user guest || echo "Warning: Failed to delete guest user"
  else
    echo "Guest user already removed"
  fi

  # Stop the background RabbitMQ server
  echo "Stopping temporary RabbitMQ instance..."
  if ! rabbitmqctl stop; then
    echo "Warning: Failed to stop RabbitMQ gracefully"
    return 1
  fi

  echo "RabbitMQ setup completed successfully"
}

cleanup() {
  # Clear sensitive variables
  TEMP_PASSWORD=""
  unset RABBITMQ_ADMIN_PASSWORD
}

# --- Main Execution ---
setup_secrets_directory
get_admin_password
if ! setup_rabbitmq; then
  echo "RabbitMQ setup failed"
  exit 1
fi
cleanup

sleep 2

# Start RabbitMQ in the foreground
echo "Starting RabbitMQ server..."
exec rabbitmq-server
