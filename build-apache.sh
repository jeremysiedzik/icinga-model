#!/bin/bash
CONTAINER="httpd"
HOSTNAME="httpd"
TO_BUILD="httpd:latest"

TCP_PORT="80"

ROOT_DIR="/opt/testground"
LOCAL_LOG_DIR="$ROOT_DIR/apache/logs"
CONTAINER_LOG_DIR="/usr/local/apache2/logs"
ASSETS="$ROOT_DIR/apache/assets"
TAR_DESTINATION=$ROOT_DIR

SERVERNAME="testcase"
SERVERCONFIGFILE="/usr/local/apache2/conf/httpd.conf"
LOCALCONFIGFILE="httpd.conf"
LOCALMASTERCONFIG="master-httpd.conf"

tar -cvf $TAR_DESTINATION/apache-logs-$(date +%Y-%m-%d-%H.%M).tar $LOCAL_LOG_DIR

echo "$(date) - Killing all former instances of container <$CONTAINER>"
docker kill $CONTAINER
rm -rf $ROOT_DIR/apache/logs/*
rm -rf $ASSETS/$LOCALCONFIGFILE
sleep 1
echo "-------------------------------------------------------------------------"
echo "  "

echo "$(date) - Removing all former instances of container <$CONTAINER>"
docker rm -f $CONTAINER
docker rmi -f $CONTAINER
sleep 1
echo "-------------------------------------------------------------------------"
echo "  "

echo "$(date) - Building new container <$CONTAINER>"
docker build -t $CONTAINER ./apache
sleep 1
echo "-------------------------------------------------------------------------"
echo "  "

echo "$(date) - Downloading components and starting container <$CONTAINER>"
docker run -h $HOSTNAME -v $LOCAL_LOG_DIR:$CONTAINER_LOG_DIR -p $TCP_PORT:$TCP_PORT --name $CONTAINER -d $TO_BUILD 
docker logs $CONTAINER
sleep 1
echo "-------------------------------------------------------------------------"
echo "  "

echo"Network information:"
echo ""
netstat -tulpn | grep $TCP_PORT | grep docker
echo "-------------------------------------------------------------------------"
echo "  "

while ! curl -s http://127.0.0.1:$TCP_PORT > /dev/null
do
  echo "$(date) - Attemtping to reach docker container <$CONTAINER>"
  sleep 2
done
echo "-------------------------------------------------------------------------"
echo "  "

echo "$(date) - Connected successfully to <$CONTAINER>"
echo "-------------------------------------------------------------------------"
echo "  "

echo "$(date) - Transferring configuration data to <$CONTAINER>"
echo "-------------------------------------------------------------------------"
echo "  "
cp $ASSETS/$LOCALMASTERCONFIG $ASSETS/$LOCALCONFIGFILE
echo "ServerName $SERVERNAME" >> $ASSETS/$LOCALCONFIGFILE
docker cp $ASSETS/$LOCALCONFIGFILE $CONTAINER:$SERVERCONFIGFILE
docker exec -dit $CONTAINER chown root:www-data $SERVERCONFIGFILE
docker restart $CONTAINER
sleep 2

while ! curl -s http://127.0.0.1:$TCP_PORT > /dev/null
do
  echo "$(date) - Verifying restart of container <$CONTAINER>"
  sleep 2
done
echo "-------------------------------------------------------------------------"
echo ""
echo "Your container is ready for use"
echo ""
