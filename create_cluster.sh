#!/bin/bash

source lib/common.sh

#
# This script represents the current state of creating a Kubernetes cluster
# using Metal³.  Some parts are automated, like provisioning hosts through
# the Machine interface, but there's no higher level automation of the
# Kubernetes control plane built in, other than the ability to pass
# custom user-data to launch Kubernetes components when a Machine comes up.
#

#
# https://kubernetes.io/docs/setup/independent/install-kubeadm/
# https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/
#
cat << EOF > master-cloud-config.yaml
yum_repos:
  kubernetes:
    name: Kubernetes
    baseurl: https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
    enabled: true
    gpgcheck: true
    gpgkey: https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
packages:
 - kubelet
 - kubeadm
 - kubectl
runcmd:
 - [ setenforce, 0 ]
 - [ sed,  -i,  's/^SELINUX=enforcing$/SELINUX=permissive/', /etc/selinux/config ]
 - [ systemctl, enable, --now, kubelet ]
 - [ kubeadm, init ]
EOF

#
# Create the master.
#
# The two virtual bare metal hosts are identical, though we have them named
# kube-master-0 and kube-worker-0.  Nothing ensures that the Machine actuator
# actually chooses `kube-master-0` to be the master.
#   - See https://github.com/metal3-io/cluster-api-provider-baremetal/issues/66
#
export EXTRA_CLOUD_CONFIG=master-cloud-config.yaml
./create_machine.sh master
