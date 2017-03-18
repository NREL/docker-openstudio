#!/bin/bash
#Check if X server is running. 
if [ "`ps | grep Xming`" == "" ]
then
#If not running try to start it. 
if [ -d "/c/Program Files/Xming/" ]
then
  /c/Program\ Files/Xming/Xming.exe -ac -multiwindow -clipboard  -dpi 108 &
elif [ -d "/c/Program Files (x86)/Xming/" ]
then
  /c/Program\ Files\ \(x86\)/Xming/Xming.exe -ac -multiwindow -clipboard  -dpi 108 &
else
	echo "Could not find Xming installed on your system either /c/Program Files/Xming or /c/Program Files (x86)/Xming  . Please install Xming, ideally the donation version in the default location." 
	exit
fi
fi
linux_home_folder=/home/nrcan
x_display=$(ipconfig | grep -m 1 "IPv4" | awk '{print $NF}')
win_user=$(whoami)
image=dockerfile_btap_dev_image
echo "Windows User: $win_user"
echo "X server IP: $x_display"
echo "image name: $image"