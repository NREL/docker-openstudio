# Creating Singularity Image

* Build Singularity/Docker Image

    ```bash
    docker build -t singularity -f singularity/Dockerfile .
    ```
    
* Pull and deploy registry image

    ```bash
    docker pull registry:2
    docker run -d -p 5000:5000 --name registry registry:2
    ```

* Build OpenStudio Container (Locally) and push it to the local registry
    
    ```bash
    # Set the version of OpenStudio to install
    export OPENSTUDIO_VERSION=2.8.1
    export OPENSTUDIO_SHA=6914d4f590
  
    docker build -t docker-openstudio --build-arg OPENSTUDIO_VERSION=$OPENSTUDIO_VERSION --build-arg OPENSTUDIO_SHA=$OPENSTUDIO_SHA .
    docker tag docker-openstudio:latest 127.0.0.1:5000/docker-openstudio:latest
    docker push 127.0.0.1:5000/docker-openstudio:latest
    ```  
    
* Launch the Container (in privileged mode with docker.sock mounted in the container)

    ```bash
    docker run -it --rm --privileged -v $(pwd):/root/build -v /var/run/docker.sock:/var/run/docker.sock --network container:registry singularity /root/build/singularity/build_singularity.sh
    ```
    
* The singularity image will be in the docker-openstudio root directory. Hop inside the singularity container to test the new image

    ```bash
    # test the container
    docker run -it --privileged --rm -v $(pwd):/root/build singularity /bin/bash
    singularity shell -B $(pwd):/singtest docker-openstudio.simg
    # RUBYLIB isn't copied into Singularity container for some reason
    openstudio --bundle /var/oscli/Gemfile --bundle_path /var/oscli/gems gem_list
    # Verify that the openstudio standards gem specified has the expected SHA
    ```

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


