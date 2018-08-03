# Creating Singularity Image

* Build Singularity/Docker Image

    ```bash
    docker build -t singularity -f singularity/Dockerfile .
    ```
    
* Build OpenStudio Container (Locally)
    
    ```bash
    # Set the version of OpenStudio to install
    export OPENSTUDIO_VERSION=2.6.0
    export OPENSTUDIO_SHA=8c81faf8bc
  
    docker build -t docker-openstudio --build-arg OPENSTUDIO_VERSION=$OPENSTUDIO_VERSION --build-arg OPENSTUDIO_SHA=$OPENSTUDIO_SHA .
    ```  
    
* Launch the Container (in privileged mode with docker.sock mounted in the container)

    ```bash
    docker run -it --rm --privileged -v $(pwd):/root/build -v /var/run/docker.sock:/var/run/docker.sock singularity bash
    ```
    
* Inside singularity build the docker container

    ```bash
    
    if [ ! "$(docker ps -q -f name=for_export)" ]; then docker rm for_export; else echo "Container does not exist"; fi
    # start an instance of the container for export
    docker run --name for_export docker-openstudio /bin/true
    if [ -f docker-openstudio.simg ]; then rm -f docker-openstudio.simg; else echo "File does not exist"; fi
    singularity image.create -s 2000 docker-openstudio.simg
    docker export for_export | singularity image.import docker-openstudio.simg

    # test singularity
    singularity shell -B $(pwd):/singtest docker-openstudio.simg
    # RUBYLIB isn't copied into Singularity container for some reason
    export RUBYLIB=/usr/local/openstudio-2.6.0/Ruby
    ruby /singtest/test/test.rb
  
    ```

* Exit out of the container and singularity image will be in the docker-openstudio root directory

# Using Singularity Container

* Download singularity image from S3

```
curl -SLO https://s3.amazonaws.com/openstudio-builds/2.6.0/OpenStudio-2.6.0.ac20db5eff-Singularity.simg
```

* Run singularity container

```
module load singularity-container
# Mount /scratch for analysis
singularity shell -B /scratch:/scratch OpenStudio-2.6.0.ac20db5eff-Singularity.simg

# Call bash (without --norc) for now until LANG is fixed
bash

openstudio --version
```

* Running singularity in line

```
singularity exec -B /scratch:/var/simdata/openstudio OpenStudio-2.6.0.ac20db5eff-Singularity.simg openstudio run -w in.osw


