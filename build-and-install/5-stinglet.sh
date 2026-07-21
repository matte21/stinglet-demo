#!/bin/bash

# WARNING: the following script assumes ubuntu. Won't work on other distros!

set -o errexit
set -o nounset
set -o pipefail

readonly static_pods_path="/etc/kubernetes/manifests"

# Delete old kubelet state, if it exists.
sudo rm -rf /var/lib/kubelet/*
sudo rm -rf "$static_pods_path"/*
sudo rm -rf /etc/kubernetes/kubelet.yaml

# Build custom kubelet (i.e., stinglet).
cd components/stinglet/
make WHAT=cmd/kubelet

# Setup kubelet binary and necessary config files and folders in place.
sudo cp _output/bin/kubelet /usr/bin/kubelet
sudo mkdir -p "$static_pods_path"
sudo tee /etc/kubernetes/kubelet.yaml > /dev/null << EOF
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
authentication:
  webhook:
    enabled: false # Do NOT use in production clusters!
authorization:
  mode: AlwaysAllow # Do NOT use in production clusters!
enableServer: false
logging:
  format: text
address: 127.0.0.1 # Restrict access to localhost
readOnlyPort: 10255 # Do NOT use in production clusters!
staticPodPath: $static_pods_path
containerRuntimeEndpoint: unix:///var/run/crio/crio.sock
featureGates:
  TopologyManagerPolicyAlphaOptions: true
  CPUManagerPolicyAlphaOptions: true
kubeReserved:
  memory: "500Mi"
reservedMemory:
  - numaNode: 0
    limits:
      memory: "600Mi"
reservedSystemCPUs: "0,1"
cpuCFSQuota: false
cgroupDriver: "cgroupfs"
topologyManagerPolicy: "unifiedFarMem"
EOF

# Create systemd unit file for kubelet.
sudo tee /etc/systemd/system/kubelet.service > /dev/null << 'EOF'
[Unit]
Description=Kubelet
After=crio.service

[Service]
ExecStart=/usr/bin/kubelet --config=/etc/kubernetes/kubelet.yaml
Restart=always
RestartSec=5
StartLimitIntervalSec=0

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload

echo Stinglet installed successfully.
