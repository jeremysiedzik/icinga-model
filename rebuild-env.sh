#!/bin/bash
echo "This will remove all containers and start Docker from scratch!"
read -p "Are you sure you want to continue? Hit ENTER or Control-C the get the heck out of here! <y/N> " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
then
echo "Ok, deleting all containers"
	docker rm -f $(docker ps -a -q)
sleep 2

echo "Ok, deleting all images"
	docker rmi -f $(docker images -q)
echo "docker images returns the following:"
	echo ""
	docker images
	echo ""
else
  exit 0
fi
