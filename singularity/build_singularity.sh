#!/usr/bin/env bash

# Build singularity container
cd singularity
singularity image.create -s 3000 docker-openstudio.simg
SINGULARITY_NOHTTPS=1 singularity build docker-openstudio.simg Singularity
cp docker-openstudio.simg ..
