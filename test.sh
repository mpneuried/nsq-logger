#!/bin/sh
export HOST=$( ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
echo "host = $HOST"

echo "start services"
docker-compose up -d

export NSQ_LOOKUP_A_HOST=$HOST
export NSQ_LOOKUP_B_HOST=$HOST
export NSQ_HOST=$HOST
export NO_DEAMONS=1
#export severity=debug

npm run build

npm run test

docker-compose stop
docker-compose rm -f
