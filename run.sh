#!/bin/bash

# WARNING: the following script assumes ubuntu. Won't work on other distros!

set -o errexit
set -o nounset
set -o pipefail

# Disable swap because kubelet can't run with it.
sudo swapoff -a

# First start CRI-O.
sudo systemctl start crio.service
while [[ "$(sudo systemctl is-active crio.service)" != "active" ]]; do
    sleep 1
    echo Waiting for CRI-O to get up and running...
done

echo CRI-O up and running.

echo "pulling container image of demo application..."
img=$(grep "image:" demo-app/pod.yaml | awk '{print $2}')
sudo crictl pull "$img"

# Now start stinglet.
sudo systemctl start kubelet.service
while [[ "$(sudo systemctl is-active kubelet.service)" != "active" ]]; do
    sleep 1
    echo Waiting for kubelet to get up and running...
done

# Wait until the kubelet is up and running and able to handle pods.
while [[ "$(curl -s http://localhost:10255/healthz)" != "ok" || -z "$(curl -s http://localhost:10255/pods | grep kind)" ]]; do
    sleep 1
    echo Waiting for kubelet to be able to handle pods...
done

echo Stinglet up and running.
echo Success!
