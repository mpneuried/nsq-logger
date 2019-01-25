#!/bin/sh
echo "read host ip"
export HOST=$( ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
echo "host = $HOST"

echo "start services"
docker-compose up -d

echo "define env's"
export NSQ_LOOKUP_A_HOST=$HOST
export NSQ_LOOKUP_B_HOST=$HOST
export NSQ_HOST=$HOST
export NO_DEAMONS=1
#export severity=debug

echo "build"
npm run build

echo "test"
npm run test

echo "stop docker services"
docker-compose stop
docker-compose rm -f
