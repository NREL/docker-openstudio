#!/usr/bin/env bash
VERSION=2.8.1
x_display=$(ipconfig | grep -m 1 "IPv4" | awk '{print $NF}')
image=openstudio

docker rmi $image
echo "Windows User: $win_user"
echo "Host/X server IP: $x_display"
echo "image name: $image"
# Creare and run image based on system. 
if [ "$(uname)" == "Darwin" ]; then
    echo "Running image on $(uname) (untested)"
	echo "docker build --build-arg DISPLAY=$x_display:0.0 -t $image ."
	docker build --build-arg DISPLAY=$x_display:0.0 -t $image .
	echo "docker run -it $image"
	docker run -it $image
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    # Do something under GNU/Linux platform
    echo "Running image on $(uname) (untested)"
	echo "docker build --build-arg DISPLAY=$x_display:0.0 -t $image ."
	docker build --build-arg DISPLAY=$x_display:0.0 -t $image .
	echo "docker run -it $image"
	docker run -it $image
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
    # Do something under 64 bits Windows NT platform
	echo "Running image on $(uname)"
	#Check if X server is running. 
	if [ "`ps | grep Xming`" == "" ] ; then
		#If not running try to start it. 
		if [ -d "/c/Program Files/Xming/" ]; then
			/c/Program\ Files/Xming/Xming.exe -ac -multiwindow -clipboard  -dpi 108 &
			echo "found Xming and running with /c/Program\ Files/Xming/Xming.exe -ac -multiwindow -clipboard  -dpi 108"
		elif [ -d "/c/Program Files (x86)/Xming/" ]; then
			/c/Program\ Files\ \(x86\)/Xming/Xming.exe -ac -multiwindow -clipboard  -dpi 108 &
		else
			echo "Could not find Xming installed on your system either /c/Program Files/Xming or /c/Program Files (x86)/Xming." 
			echo "Please install Xming, ideally the donation version in the default location." 
			echo "X Display will not work, you can continue while basic shell access."
			exit
		fi
	else
		echo "Using instance of Xming already running."
	fi
	echo "docker build --build-arg DISPLAY=$x_display:0.0 -t $image ."
	docker build --no-cache --build-arg DOCKER_OPENSTUDIO_VERSION=$VERSION --build-arg OPENSTUDIO_VERSION=$VERSION --build-arg DISPLAY=$x_display:0.0 -t $image .
	echo "winpty docker run -it $image"
	winpty docker run -it $image
fi