#!/bin/bash

# This script download all the python packages specified in sample_requirements.txt and saves them in the dependencies folder

# Get the dicerctory of the script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Create the dependencies folder
mkdir -p $DIR/../dependencies

# Read the sample_requirements.txt file and download the packages to the dependencies folder
pip download -r $DIR/../sample_requirements.txt -d $DIR/../dependencies