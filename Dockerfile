# syntax=docker/dockerfile:1

# ---------------------------------------------------------------------------
# BASE IMAGE
# ---------------------------------------------------------------------------
# The base image is a pre-built Jupyter environment with Python and common
# scientific libraries (numpy, scipy, matplotlib) already installed.
# The date tag ensures the exact same version for each build of the image.
FROM quay.io/jupyter/scipy-notebook:2025-12-31

# ---------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# ---------------------------------------------------------------------------
# This variable can be read by Python code to detect it is running inside
# a container, for example to adjust file paths. Check VISU_tutorial.ipynb on how to use it.
ENV RUNNING_IN_CONTAINER=Yes

# ---------------------------------------------------------------------------
# WORKING DIRECTORY
# ---------------------------------------------------------------------------
# Sets the working directory inside the container. This is the default path for running any commands in the container.
WORKDIR /code

# ---------------------------------------------------------------------------
# SYSTEM DEPENDENCIES
# ---------------------------------------------------------------------------
# Install system-level packages required by some Python libraries.
# All steps are combined into one command to keep the image size small.
# As an example, nano and ca-certificates are installed.
# nano = Command-line text editor. Useful for opening a terminal inside the container to edit files.
# ca-certificates = Trusted SSL certificates for HTTPS connections
USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nano \
        ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
# Run the container as a regular (non-root) user for security.
USER ${NB_UID}

# ---------------------------------------------------------------------------
# PYTHON PACKAGES
# ---------------------------------------------------------------------------
# Copy the requirements file and install packages.
# Copying requirements.txt before the rest of the code means Docker can
# skip re-installing packages when only your code changes.
COPY requirements.txt /code/requirements.txt
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r /code/requirements.txt

# ---------------------------------------------------------------------------
# CODE
# ---------------------------------------------------------------------------
# Copy notebooks and scripts into the container.
#
# The image contains only code and libraries. Note that data is not copied to the container.
# This is especially important in a case where sensitive data would be available.
# Here, .dockerignore file is used to avoid copying the contents of /data folder into the container during build.
#
#   Demo use:       Download the dataset yourself (see README.md) and transfer
#                   it to the VISU computing environment alongside this image via sftp.
#
#   Sensitive data: Data is provided to VISU by research services according to the research permit.
#                   The data is bind-mounted inside the container to the path /code/data at runtime.
#
# To make your local data folder available inside the container:
#   Docker (local):     docker run --rm -p 8888:8888 -v ./data:/code/data visu-demo-image:jupyter-notebook
#
#   Apptainer (VISU):   apptainer exec --bind /data/import:/code/data visu-demo-container.sif \
#                           jupyter lab --ip=0.0.0.0 --no-browser
COPY . .

# ---------------------------------------------------------------------------
# STARTUP COMMAND
# ---------------------------------------------------------------------------
# Opens JupyterLab when the Docker container starts.
# --ip=0.0.0.0 makes it reachable from the browser outside the container.
#
# Note: this command is ignored when using Apptainer. Instead, run the similar command with:
#   apptainer exec --bind /data/import:/code/data visu-demo-container.sif \
#       jupyter lab --ip=0.0.0.0 --no-browser
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--no-browser"]
