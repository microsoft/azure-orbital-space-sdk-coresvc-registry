#!/usr/bin/env bash

# This will start the OCI Registry and the PyPI server in the background and listen for the
# SIGTERM and SIGINT signals to stop the processes gracefully.

REGISTRY_ENABLED="${REGISTRY_ENABLED:-"true"}"
PYPISERVER_ENABLED="${PYPISERVER_ENABLED:-"true"}"

# Function to handle termination signal
terminate_processes() {
    echo "Termination signal received. Stopping processes..."
    if [[ "${REGISTRY_ENABLED}" == "true" ]] && [[ "${PYPISERVER_ENABLED}" == "true" ]]; then
        kill $REGISTRY_PID $PYPI_PID
        wait $REGISTRY_PID $PYPI_PID
    elif [[ "${REGISTRY_ENABLED}" == "true" ]]; then
        kill $REGISTRY_PID
        wait $REGISTRY_PID
    elif [[ "${PYPISERVER_ENABLED}" == "true" ]]; then
        kill $PYPI_PID
        wait $PYPI_PID
    fi

    echo "Processes stopped."
    exit 0
}

# Trap SIGTERM and SIGINT signals and call the termination function
trap terminate_processes SIGTERM SIGINT

if [[ "${REGISTRY_ENABLED}" == "true" ]]; then
    # Run the OCI_Registry in the background
    registry serve /etc/docker/registry/config.yml 2>&1 | tee -a /var/log/registry.log &
    REGISTRY_PID=$!
fi

if [[ "${PYPISERVER_ENABLED}" == "true" ]]; then
    # Run the pypi server in the background
    mkdir -p /data/packages
    /pypi-server/bin/pypi-server run -p ${PYPISERVER_PORT:-$PORT} --server gunicorn --backend cached-dir /data/packages 2>&1 | tee -a /var/log/pypiserver.log &
    PYPI_PID=$!
fi


if [[ "${REGISTRY_ENABLED}" == "true" ]] && [[ "${PYPISERVER_ENABLED}" == "true" ]]; then
    # Wait for the background processes to complete
    wait $REGISTRY_PID $PYPI_PID
elif [[ "${REGISTRY_ENABLED}" == "true" ]]; then
    wait $REGISTRY_PID
elif [[ "${PYPISERVER_ENABLED}" == "true" ]]; then
    wait $PYPI_PID
fi

