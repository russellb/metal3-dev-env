#!/usr/bin/env bash
set -ex

source lib/logging.sh
source lib/common.sh

sudo yum install -y libselinux-utils
if selinuxenabled ; then
    sudo setenforce permissive
    sudo sed -i "s/=enforcing/=permissive/g" /etc/selinux/config
fi

# Update to latest packages first
sudo yum -y update

# Install EPEL required by some packages
if [ ! -f /etc/yum.repos.d/epel.repo ] ; then
    if grep -q "Red Hat Enterprise Linux" /etc/redhat-release ; then
        sudo yum -y install http://mirror.centos.org/centos/7/extras/x86_64/Packages/epel-release-7-11.noarch.rpm
    else
        sudo yum -y install epel-release --enablerepo=extras
    fi
fi

# Install required packages
# python-{requests,setuptools} required for tripleo-repos install
sudo yum -y install \
  crudini \
  curl \
  dnsmasq \
  figlet \
  golang \
  NetworkManager \
  nmap \
  patch \
  psmisc \
  python-pip \
  python-requests \
  python-setuptools \
  vim-enhanced \
  wget

# We're reusing some tripleo pieces for this setup so clone them here
cd
if [ ! -d tripleo-repos ]; then
  git clone https://git.openstack.org/openstack/tripleo-repos
fi
pushd tripleo-repos
sudo python setup.py install
popd

# Needed to get a recent python-virtualbmc package
sudo tripleo-repos current-tripleo

# There are some packages which are newer in the tripleo repos
sudo yum -y update

# make sure additional requirments are installed
sudo yum -y install \
  ansible \
  bind-utils \
  jq \
  libguestfs-tools \
  libvirt \
  libvirt-devel \
  libvirt-daemon-kvm \
  nodejs \
  python-lxml \
  python-netaddr \
  python-virtualbmc \
  qemu-kvm \
  redhat-lsb-core \
  virt-install \
  unzip \
  genisoimage

if [[ "${CONTAINER_RUNTIME}" == "podman" ]]; then
  sudo yum -y install podman
else
  sudo yum install -y yum-utils \
    device-mapper-persistent-data \
    lvm2
  sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
  sudo yum install -y docker-ce docker-ce-cli containerd.io
  sudo systemctl start docker
fi

# Install python packages not included as rpms
sudo pip install \
  lolcat \
  yq

if ! which minikube 2>/dev/null ; then
    curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    chmod +x minikube
    sudo mv minikube /usr/local/bin/.
fi

if ! which docker-machine-driver-kvm2 2>/dev/null ; then
    curl -LO https://storage.googleapis.com/minikube/releases/latest/docker-machine-driver-kvm2
    chmod +x docker-machine-driver-kvm2
    sudo mv docker-machine-driver-kvm2 /usr/local/bin/.
fi

if ! which kubectl 2>/dev/null ; then
    curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/.
fi

if ! which kustomize 2>/dev/null ; then
    curl -Lo kustomize $(curl --silent -L https://github.com/kubernetes-sigs/kustomize/releases/latest 2>&1 | awk -F'"' '/linux_amd64/ { print "https://github.com"$2; exit }')
    chmod +x kustomize
    sudo mv kustomize /usr/local/bin/.
fi
