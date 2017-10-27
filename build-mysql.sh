#!/bin/bash
CONTAINER="mysql"
HOSTNAME="mysql"
TO_BUILD="mysql/mysql-server:latest"

USER="root"
PASSWORD="secrets"

LOCAL_TCP_PORT="6033"
CONTAINER_TCP_PORT="3306"
DOCKERIP=`ip -f inet addr show docker0 | grep -Po 'inet \K[\d.]+'`

ROOT_DIR="/opt/testground"
LOCAL_LOG_DIR="$ROOT_DIR/mysql/logs"
CONTAINER_LOG_DIR="/var/lib/mysql"
ASSETS="$ROOT_DIR/mysql/assets"
TAR_DESTINATION=$ROOT_DIR

tar -cvf $TAR_DESTINATION/mysql-logs-$(date +%Y-%m-%d-%H%M).tar $LOCAL_LOG_DIR

echo "$(date) - Killing all former instances of container <$CONTAINER>"
docker kill $CONTAINER
rm -rf $ROOT_DIR/mysql/logs/*
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
docker build -t $CONTAINER $ROOT_DIR/mysql
sleep 1
echo "-------------------------------------------------------------------------"
echo "  "

echo "$(date) - Downloading components and starting container <$CONTAINER>"
docker run -h $HOSTNAME -v $LOCAL_LOG_DIR:$CONTAINER_LOG_DIR -p $LOCAL_TCP_PORT:$CONTAINER_TCP_PORT --name $CONTAINER -e MYSQL_ROOT_PASSWORD=$PASSWORD -d $TO_BUILD
docker logs $CONTAINER
sleep 1
echo "-------------------------------------------------------------------------"
echo "  "

echo "Network information:"
echo ""
netstat -tulpn | grep $LOCAL_TCP_PORT
echo "-------------------------------------------------------------------------"
echo "  "

while ! curl -s http://127.0.0.1:$LOCAL_TCP_PORT > /dev/null
do
  echo "$(date) - Attempting to reach docker container <$CONTAINER>"
  sleep 2
done
echo "-------------------------------------------------------------------------"
echo "  "

echo "$(date) - Connected successfully - allowing remote access to <$CONTAINER>"
docker exec -dit $CONTAINER mysql -u$USER -p$PASSWORD -e "grant all on *.* to '"$USER"'@'%' identified by '"$PASSWORD"';"
echo "-------------------------------------------------------------------------"
echo "  "
sleep 2

echo "$(date) - Granting local access to container <$CONTAINER> via mysql connection"
docker exec -dit $CONTAINER mysql -u$USER -p$PASSWORD -e "grant all on *.* to '"$USER"'@'"$DOCKERIP"' identified by '"$PASSWORD"';"
echo "-------------------------------------------------------------------------"
echo "  "
sleep 2

echo "$(date) - Version info should be displayed if local mysql connection is successful:"
export MYSQL_PWD=$PASSWORD
mysql -u$USER -h 127.0.0.1 -e "SHOW VARIABLES LIKE '%version%';"
sleep 2

echo "$(date) - Updating mysql configuration on container <$CONTAINER> and restarting"
docker cp $ASSETS/my.cnf $CONTAINER:/etc/my.cnf
docker restart $CONTAINER
sleep 2

while ! curl -s http://127.0.0.1:$LOCAL_TCP_PORT > /dev/null
do
  echo "$(date) - Verifying restart of container <$CONTAINER>"
  sleep 2
done
echo "-------------------------------------------------------------------------"
echo ""
echo "Your container is ready for use"
echo ""
