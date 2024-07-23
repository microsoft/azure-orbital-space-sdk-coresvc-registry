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
    echo "REGISTRY_ENABLED='true'. Starting the OCI Registry..."
    # Run the OCI_Registry in the background
    registry serve /etc/docker/registry/config.yml &
    REGISTRY_PID=$!
    echo "...OCI Registry successfully started."
fi

if [[ "${PYPISERVER_ENABLED}" == "true" ]]; then
    echo "PYPISERVER_ENABLED='true'. Starting the PyPiServer..."
    # Run the pypi server in the background
    mkdir -p /data/packages
    export GUNICORN_CMD_ARGS="--accesslog - --errorlog - --preload --workers 1 --worker-class gevent"
    /pypi-server/bin/pypi-server run -a . -P . -p ${PYPISERVER_PORT:-$PORT} --server gunicorn --backend cached-dir /data/packages --verbose --log-file /var/log/pypiserver.log &
    PYPI_PID=$!
    echo "...PyPiServer started."
fi


if [[ "${REGISTRY_ENABLED}" == "true" ]] && [[ "${PYPISERVER_ENABLED}" == "true" ]]; then
    # Wait for the background processes to complete
    wait $REGISTRY_PID $PYPI_PID
elif [[ "${REGISTRY_ENABLED}" == "true" ]]; then
    wait $REGISTRY_PID
elif [[ "${PYPISERVER_ENABLED}" == "true" ]]; then
    wait $PYPI_PID
fi

