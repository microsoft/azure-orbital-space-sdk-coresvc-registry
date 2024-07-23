#!/usr/bin/env bash

# This will start the OCI Registry and the PyPI server in the background and listen for the
# SIGTERM and SIGINT signals to stop the processes gracefully.

# Function to handle termination signal
terminate_processes() {
    echo "Termination signal received. Stopping processes..."
    kill $REGISTRY_PID $PYPI_PID
    wait $REGISTRY_PID $PYPI_PID
    echo "Processes stopped."
    exit 0
}

# Trap SIGTERM and SIGINT signals and call the termination function
trap terminate_processes SIGTERM SIGINT


# Run the OCI_Registry in the background first
registry serve /etc/docker/registry/config.yml &
REGISTRY_PID=$!

# Run the pypi server in the background
mkdir -p /data/packages
/pypi-server/bin/pypi-server run -p ${PYPISERVER_PORT:-$PORT} --server gunicorn --backend cached-dir /data/packages &
PYPI_PID=$!

# Wait for the background processes to complete
wait $REGISTRY_PID $PYPI_PID