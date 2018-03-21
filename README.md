# OpenStudio

[![Build Status](https://travis-ci.org/NREL/docker-openstudio.svg?branch=master)](https://travis-ci.org/NREL/docker-openstudio)

This repo provides a container for OpenStudio as well as several dependencies, including Ruby 2.x, Bundler, build-essentials and various development libraries for gem support.

## Execution

The two supported use cases for this repo are building and executing the OpenStudio docker container, respectively. Each will be addressed in turn.

### Build

Begin by installing the [docker tool-kit](https://docs.docker.com/engine/installation/) version 17.03.1 or later, as described in the linked documentation. Once the tool-kit is installed and activated, run the command `docker build .`. This will initiate the build process for the docker container. Any updates to this process should be implemented through the [Dockerfile](./Dockerfile) in the root of this repo. 

### Execution

There are two options to acquire the docker container required for execution. Both assume that the [docker tool-kit](https://docs.docker.com/engine/installation/) version 17.03.1 or later is installed. The first option, building the container from a GitHub checkout, is outlined above. Additionally, it is typically easiest to [tag the resulting container](https://docs.docker.com/engine/reference/commandline/tag/) as `nrel/openstudio:latest`. For a more extensive discussion of the latest tag and associated best practices [please refer to this Medium article](https://medium.com/@mccode/the-misunderstood-docker-tag-latest-af3babfd6375). The second option, downloading a release from DockerHub, requires determining the [docker-openstudio tagged release](https://hub.docker.com/r/nrel/openstudio/tags/) that is desired, and then running `docker pull nrel/openstudio:<tag>`. As an example, to download the 2.1.1 docker-openstudio image, the command would be `docker pull nrel/openstudio:2.1.1`.

Once the desired container is available, either through a build or pull process, the next step is to run the container. To simply access the container tagged with 'tag', (where tag was respectively 'latest' or '2.1.1' in the above paragraph,) run `docker run -it --rm nrel/openstudio:tag /bin/bash`. 

To execute an OpenStudio Workflow directly from the command line requires [mounting the requisite files to the container](https://docs.docker.com/engine/reference/run/#volume-shared-filesystems), as well as invoking the [OpenStudio CLI](https://nrel.github.io/OpenStudio-user-documentation/reference/command_line_interface/) (command line interface.) The docker container by default executes commands in the `/var/simdata/openstudio` directory, (this is defined in the [Dockerfile](./Dockerfile).) If the desired OSW was located at `/Users/myuser/demo_os_files/example.osw` on the host computer, the appropriate docker command to execute the OSW would be `docker run -it --rm -v=/Users/myuser/demo_os_files:/var/simdata/openstudio nrel/openstudio /usr/bin/openstudio run -w example.osw`

If gem dependencies are required as part of the CLI outside of those [packed with OpenStudio](https://github.com/NREL/OpenStudio/blob/develop/dependencies/ruby/Gemfile) please contact Kyle Benne, Ry Horsey, and Dan Macumber at their NREL email addresses.

# Known Issues

Please submit issues on the project's [Github](https://github.com/nrel/docker-openstudio) page. 
