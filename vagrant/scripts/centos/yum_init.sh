#!/usr/bin/env bash
set -o errexit -o nounset
TOP_DIR=$(cd $(cat "../TOP_DIR" 2>/dev/null||echo $(dirname "$0"))/.. && pwd)
source "$TOP_DIR/config/paths"
source "$CONFIG_DIR/openstack"
# Pick up VM_PROXY
source "$CONFIG_DIR/localrc"
source "$LIB_DIR/functions.guest.sh"

indicate_current_auto

exec_logfile

function set_yum_proxy {
    local YUM_FILE=/etc/yum.conf
    if [ -z "${VM_PROXY-}" ]; then
        return 0;
    fi
    echo "proxy=${VM_PROXY}" | sudo tee -a $YUM_FILE
}

set_yum_proxy

# Enable RDO repo
case "${OPENSTACK_RELEASE:-}" in
    ussuri)
        sudo yum install -y "https://repos.fedorapeople.org/repos/openstack/openstack-ussuri/rdo-release-ussuri-2.el8.noarch.rpm"
        ;;
    victoria)
        sudo yum install -y "https://repos.fedorapeople.org/repos/openstack/openstack-victoria/rdo-release-victoria-2.el8.noarch.rpm"
        ;;
    *)
        echo 2>&1 "ERROR Unknown OpenStack release."
        exit 1
esac
