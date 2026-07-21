#!/bin/bash

# WARNING: the following script assumes ubuntu. Won't work on other distros!
# WARNING: this script assumes the kubelet is currently running. Stopping a
# partially-down stack (kubelet dead but CRI-O holding pods) is not yet handled
# and can leak pods.

set -o errexit
set -o nounset
set -o pipefail

readonly kubelet_pods_api="http://localhost:10255/pods"

# Delete all pods and wait for them to have been completely deleted.
#
# Note: the kubelet API clears deleted pods almost immediately, but it can take
# much longer for CRI-O to actually tear them down (stop containers, remove
# sandboxes), so we check both layers before declaring the pods gone.
sudo rm -rf /etc/kubernetes/manifests/*
while [[ $(curl -s "$kubelet_pods_api" | jq '.items') != "null" || $(sudo crictl pods -q) != "" || $(sudo crictl ps -q) != "" ]]; do
    echo "Waiting for all pods to have been permanently deleted..."
    sleep 5
done
echo "All pods and containers have been permanently deleted."

# Stop Stinglet.
sudo systemctl stop kubelet.service
while [[ "$(sudo systemctl is-active kubelet.service)" == "active" ]]; do
    sleep 1
    echo "Waiting for Stinglet to stop..."
done
echo "Stinglet stopped."

# Then stop CRI-O.
sudo systemctl stop crio.service
while [[ "$(sudo systemctl is-active crio.service)" == "active" ]]; do
    sleep 1
    echo "Waiting for CRI-O to stop..."
done

echo "CRI-O stopped."
echo "Success!"