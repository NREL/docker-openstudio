#!/bin/bash
source ./env.sh
echo Windows users $win_user was detected.
echo using  X server at this IP $x_display:0.0 .
echo start $1
docker start $1
