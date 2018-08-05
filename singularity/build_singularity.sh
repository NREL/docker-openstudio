#!/usr/bin/env bash

# Build singularity container
cd singularity
SINGULARITY_NOHTTPS=1 singularity build docker-openstudio.simg Singularity
cp docker-openstudio.simg ..
