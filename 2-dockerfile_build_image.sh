#!/bin/bash
source ./env.sh

docker build --pull --build-arg DISPLAY=$x_display:0.0 -t $image .
