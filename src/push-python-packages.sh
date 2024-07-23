#!/bin/bash

# This script is used to push the pypi packages to the spacefx pypi repository

# Set the path to the pypi repository
SPACEFX_PYPI_REPOSITORY="https://localhost:8080"
SPACEFX_PYPI_CERT="/var/spacedev/certs/registry/registry.spacefx.local.pem"

# Get the directory of the script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Push the packages to the pypi repository
for package in $(ls $DIR/../dependencies); do
    echo "Pushing $package to $SPACEFX_PYPI_REPOSITORY"
    twine upload --repository-url $SPACEFX_PYPI_REPOSITORY --cert $SPACEFX_PYPI_CERT --username anonymous --password none $DIR/../dependencies/$package
done