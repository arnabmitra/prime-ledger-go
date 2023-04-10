#!/bin/bash


function up {
  docker volume prune -f
  docker-compose -f ./docker/dependencies.yml up --build -d
  docker ps -a
}

function down {
  docker-compose -f ./docker/dependencies.yml down
}

function bounce {
   down
   up
}

${1}




