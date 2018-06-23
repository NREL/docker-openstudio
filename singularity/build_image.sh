if [ ! "$(docker ps -q -f name=for_export)" ]; then docker rm for_export; else echo "Container does not exist"; fi
# start an instance of the container for export
docker run --name for_export docker-openstudio /bin/true
if [ -f docker-openstudio.simg ]; then rm -f docker-openstudio.simg; else echo "File does not exist"; fi
singularity image.create -s 2000 docker-openstudio.simg
