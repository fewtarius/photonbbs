#!/bin/bash

###
### Create the persistent volume if it doesn't exist.
###

docker volume inspect appdata >/dev/null 2>&1
if [ ! $? = 0 ]
then
  docker volume create appdata >/dev/null 2>&1
fi

###
### Build the image
###

docker buildx build --tag fewtarius/photonbbs .

###
### Describe how to start the container.
###

if [ $? = 0 ]
then
  echo -e "\n\nTo use this container, run:\n\ndocker container run -dti --net host --device=/dev/tty0 -v appdata:/appdata:rw -v /dev:/dev -v /lib/modules:/lib/modules --cgroup-parent=docker.slice --cgroupns private --privileged fewtarius/photonbbs"
fi
