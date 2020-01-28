# OpenStudio

[![Build Status](https://travis-ci.org/NREL/docker-openstudio.svg?branch=master)](https://travis-ci.org/NREL/docker-openstudio)

This repo provides a container for OpenStudio as well as several dependencies, including Ruby 2.x, Bundler, 
build-essentials and various development libraries for gem support.

At the moment, there are two target containers for this project, Docker and [Singularity](https://singularity.lbl.gov). We are working on a slim version container.

## Docker Tags

Below is a table of the various docker tags and their meanings as seen on [this page](https://hub.docker.com/r/nrel/openstudio/tags/). 

| Tag     | Description                                                                             |
|---------|-----------------------------------------------------------------------------------------|
| x.y.z   | Build of official OpenStudio release (recommended use)                                  |
| latest  | Latest official release of OpenStudio (e.g., 2.9.1)                                     |
| develop | Release of [develop branch](https://github.com/NREL/docker-openstudio/tree/develop)     |

## Building OpenStudio Container and Releasing

These images are automatically built in TravisCI. To trigger TravisCI for a new build do the following:

* On feature branch update the [.travis.yml](.travis.yml) with the new version of OpenStudio and SHA

    ```yaml
     - OPENSTUDIO_VERSION: 2.9.1
     - OPENSTUDIO_SHA: 3472e8b799
    ```

* Update the CHANGELOG.md file with changes.
* Push changes to feature branch, make and merge a pull-request to develop
* Wait for CI to finish and verify new develop image is available on [docker hub](https://hub.docker.com/r/nrel/openstudio/tags/).
* Test locally (if needed)

    ```bash
    docker pull nrel/openstudio:develop
    docker run -it --rm nrel/openstudio:develop bash
    irb
    require 'openstudio'
    puts OpenStudio.getOpenStudioCLI
    ```
  
To release an official version, then continue with the steps below. Note that it is not recommended to officially release any of the RCs, just tag RCs as needed.

* Create pull request from develop to master
* Once the PR passes, then merge to master where TravisCI will build, tag, and push the official container to Docker Hub
* Go to GitHub and release the master branch with the latest version (e.g., 2.9.1) and copy in the latest changelog entry.

### Building Locally
  
Begin by installing the [docker tool-kit](https://docs.docker.com/engine/installation/) version 17.03.1 or later, as 
described in the linked documentation. Once the tool-kit is installed and activated, run the command below to build the base image with OpenStudio 2.6.1.

```
docker build --target base -t openstudio-local --build-arg OPENSTUDIO_VERSION=2.9.1 --build-arg OPENSTUDIO_SHA=3472e8b799 .

# For testing local
docker run -it --rm openstudio-local bash
docker run -it -v $(pwd):/var/simdata/openstudio openstudio-local ruby /var/simdata/openstudio/test/test_run.rb

# This will fail since openstudio does not allow compilation of native extensions (FFI)
docker run -it -v $(pwd):/var/simdata/openstudio openstudio-local openstudio /var/simdata/openstudio/test/test_run.rb
```

The version of OpenStudio and the SHAs are listed [here](https://github.com/NREL/OpenStudio/wiki/OpenStudio-Version-Compatibility-Matrix). 

If the `--target` is not passed, then the docker build will contain only the CLI (if commented out in the CLI)

## Executing OpenStudio Container

There are two options to acquire the docker container required for execution. Both assume that the 
[docker tool-kit](https://docs.docker.com/engine/installation/) version 17.03.1 or later is installed. The first option,
building the container from a GitHub checkout, is outlined above. Additionally, it is typically easiest to 
[tag the resulting container](https://docs.docker.com/engine/reference/commandline/tag/) as `nrel/openstudio:latest`. 
For a more extensive discussion of the latest tag and associated best practices 
[please refer to this Medium article](https://medium.com/@mccode/the-misunderstood-docker-tag-latest-af3babfd6375). 
The second option, downloading a release from DockerHub, requires determining the 
[docker-openstudio tagged release](https://hub.docker.com/r/nrel/openstudio/tags/) that is desired, and then running 
`docker pull nrel/openstudio:<tag>`. As an example, to download the 2.9.1 docker-openstudio image, the command would 
be `docker pull nrel/openstudio:2.9.1`.

Once the desired container is available, either through a build or pull process, the next step is to run the container.
To simply access the container tagged with 'tag', (where tag was respectively 'latest' or '2.9.1' in the above 
paragraph,) run `docker run -it --rm nrel/openstudio:tag /bin/bash`. 

To execute an OpenStudio Workflow directly from the command line requires 
[mounting the requisite files to the container](https://docs.docker.com/engine/reference/run/#volume-shared-filesystems), 
as well as invoking the [OpenStudio CLI](https://nrel.github.io/OpenStudio-user-documentation/reference/command_line_interface/) 
(command line interface.) The docker container by default executes commands in the `/var/simdata/openstudio` directory, 
(this is defined in the [Dockerfile](./Dockerfile).) If the desired OSW was located at 
`/Users/myuser/demo_os_files/example.osw` on the host computer, the appropriate docker command to execute the OSW would 
be `docker run -it --rm -v=/Users/myuser/demo_os_files:/var/simdata/openstudio nrel/openstudio /usr/bin/openstudio run -w example.osw`

If gem dependencies are required as part of the CLI outside of those 
[packed with OpenStudio](https://github.com/NREL/OpenStudio/blob/develop/dependencies/ruby/Gemfile) please contact
 Kyle Benne, Tim Coleman, or Nicholas Long at their NREL email addresses.



# Issues

Please submit issues on the project's [Github](https://github.com/nrel/docker-openstudio) page. 
