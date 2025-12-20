#!/bin/bash
architecture=$(arch)

if [ "$architecture" == "arm64" ]; then
    status_default=$(colima -p default status 2>&1 | egrep "colima is running|arch: aarch64" | wc -l)
    if [ $status_default -lt 2 ]; then
        echo "starting default colima with aarch64"
        colima start --cpu 8 --memory 8 --arch aarch64
    else
        echo "already running default"
    fi

    docker context use colima
fi

docker login container-registry.oracle.com

docker compose up -d


