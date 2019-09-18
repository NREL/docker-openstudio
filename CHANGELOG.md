# OpenStudio Docker Images

# Version 2.9.0
 Enable pre-releases.  Disable openstudio-cli images.

## Version 2.8.1
Enable pre-releases.  Disable openstudio-cli images.

## Version 2.8.0
Update to Ubuntu 16.04 Xenial.

## Version 2.7.1

## Version 2.7.0
* Additional support for Singularity images.

## Versions 2.6.1, 2.6.2

* Bundle install is run for OpenStudio Ruby gems. This enables the OpenStudio CLI (Oscli) to be run with the --bundle and --bundle_path options, which in turn enables the Oscli bundle to be updated.  This capability is leveraged by OpenStudio Server and documented in that wiki.
* Introduced multistage builds and nrel/openstudio-cli dockerhub images.  These are smaller images that include only OpenStudio CLI dependencies, OpenStudio CLI, and EnergyPlus executable, copied from full OpenStudio base image.  This corresponds to the "cli" target in the Dockerfile.
* Support for Singularity images was introduced.

## Version 2.5.2

* This has not been updated in quite some time.
* OpenStudio 2.5.2
* Add test for Radiance
* Release latest docker image only from master branch

## Version 1.7.2 

* OpenStudio now depends on EnergyPlus 8.3.
* Removed the installation of EnergyPlus on these images. The only EnergyPlus is the one provided by OpenStudio.

## Version 1.6.1

* No longer publishing the Ruby specific versions. 
