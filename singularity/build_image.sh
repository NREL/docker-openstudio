#!/usr/bin/env bash

if [ ! "$(docker ps -q -f name=for_export)" ]; then docker rm for_export; else echo "Container does not exist"; fi
# start an instance of the container for export
docker run --name for_export docker-openstudio /bin/true
if [ -f docker-openstudio.simg ]; then rm -f docker-openstudio.simg; else echo "File does not exist"; fi
docker export for_export > docker-export.tar
singularity build docker-openstudio.simg docker-export.tar
rm docker-export.tar

# test singularity
#singularity shell -B $(pwd):/singtest docker-openstudio.simg
# RUBYLIB isn't copied into Singularity container for some reason
#export RUBYLIB=/usr/local/openstudio-2.6.0/Ruby
#ruby /singtest/test/test.rb