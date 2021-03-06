#!/bin/bash

set -e

if [ $# -eq 4 ]
then

    KUBE_HOME_DIR=${1}
    echo "KUBE_HOME_DIR :::>>> ${KUBE_HOME_DIR}"

    MICROSERVICE=${2}
    echo "MICROSERVICE :::>>> ${MICROSERVICE}"

    VERSION=${3}
    echo "VERSION :::>>> ${VERSION}"

    DOCKER_REGISTRY_HOST=${4}
    echo "DOCKER_REGISTRY_HOST :::>>> ${DOCKER_REGISTRY_HOST}"

else
    echo "Usage: ./publishKubeDockerImage.sh <<KUBE_HOME_DIR>> <<MICROSERVICE>> <<VERSION>> <<DOCKER_REGISTRY_HOST>>"
    exit 1
fi

###################
###ONLY SET THIS###
###################
docker ps

docker images

MICROSERVICE_CONTAINER=$(docker ps -a -q -f name=${MICROSERVICE})
echo "MICROSERVICE_CONTAINER :::>>> [[[ " + ${MICROSERVICE_CONTAINER} + " ]]]..."

if [ -z "${MICROSERVICE_CONTAINER}" ]
then
    echo "[[[SKIP]]] MICROSERVICE_CONTAINER :::>>> [[[ " + ${MICROSERVICE_CONTAINER} + " ]]]..."
else
    docker rm -f ${MICROSERVICE_CONTAINER}
    echo "STOPPED/REMOVED ::: MICROSERVICE_CONTAINER :::>>> [[[ " + ${MICROSERVICE_CONTAINER} + " ]]]..."
fi

MICROSERVICE_IMAGE=$(docker images | grep ${MICROSERVICE} | awk '{print $3}')
echo "MICROSERVICE_IMAGE :::>>> [[[ " + ${MICROSERVICE_IMAGE} + " ]]]..."

if [ -z "${MICROSERVICE_IMAGE}" ]
then
    echo "[[[SKIP]]] MICROSERVICE_IMAGE :::>>> [[[ " + ${MICROSERVICE_IMAGE} + " ]]]..."
else
    docker rmi -f ${MICROSERVICE_IMAGE}
    echo "STOPPED/REMOVED ::: MICROSERVICE_IMAGE :::>>> [[[ " + ${MICROSERVICE_IMAGE} + " ]]]..."
fi

docker ps

docker images

cd ${KUBE_HOME_DIR}/apps/toolbox/kube/docker/build/

echo "BUILDING :::>>> KUBE Docker Image ::: [[[ " + ${MICROSERVICE} + " ]]]..."
docker build --build-arg kubeMicroservice=${MICROSERVICE} -t ${DOCKER_REGISTRY_HOST}/${MICROSERVICE}:${VERSION} .
echo "BUILT :::>>> KUBE Docker Image ::: [[[ " + ${MICROSERVICE} + " ]]]..."

docker ps

docker images

docker login --username=navikco --password=Frisc0tx!

echo "PUSHING :::>>> KUBE Docker Image to Docker Registry ::: [[[ " + ${MICROSERVICE} + " ]]]..."
docker rmi ${DOCKER_REGISTRY_HOST}/${MICROSERVICE}:latest | true
docker tag ${DOCKER_REGISTRY_HOST}/${MICROSERVICE}:${VERSION} ${DOCKER_REGISTRY_HOST}/${MICROSERVICE}:latest
docker push ${DOCKER_REGISTRY_HOST}/${MICROSERVICE}:${VERSION}
docker push ${DOCKER_REGISTRY_HOST}/${MICROSERVICE}:latest
echo "PUSHED :::>>> KUBE Docker Image to Docker Registry ::: [[[ " + ${MICROSERVICE} + " ]]]..."

#Remove LOCAL Docker KUBE Image
echo "DELETING LOCAL :::>>> KUBE Docker Image ::: [[[ " + ${MICROSERVICE} + " ]]]..."
docker rmi -f $(docker images | grep ${MICROSERVICE}) | true
echo "DELETED LOCAL :::>>> KUBE Docker Image ::: [[[ " + ${MICROSERVICE} + " ]]]..."

#Remove LOCAL KUBE SpringBoot JAR
echo "DELETING KUBE JAR :::>>> [[[ " + ${MICROSERVICE} + " ]]]..."
rm -rf *.jar
echo "DELETED KUBE JAR :::>>> [[[ " + ${MICROSERVICE} + " ]]]..."

docker ps

docker images
