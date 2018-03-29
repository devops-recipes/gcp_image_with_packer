#!/bin/bash
set -e
set -o pipefail

readonly NODE_ARCHITECTURE="x86_64"
readonly NODE_OPERATING_SYSTEM="Ubuntu_16.04"
readonly LEGACY_CI_CEXEC_LOCATION_ON_HOST="/home/shippable/cexec"
readonly SHIPPABLE_RELEASE_VERSION="master"
readonly EXEC_IMAGE="drydock/u16reqproc:master"
readonly REQKICK_DIR="/var/lib/shippable/reqKick"
readonly NODE_SCRIPTS_LOCATION="/root/node"
readonly NODE_SHIPCTL_LOCATION="$NODE_SCRIPTS_LOCATION/shipctl"
readonly INIT_SCRIPT_NAME="Docker_17.06.sh"
readonly NODE_SCRIPTS_DOWNLOAD_LOCATION="/tmp/node.tar.gz"
readonly NODE_TARBALL_URL="https://github.com/Shippable/node/archive/master.tar.gz"
readonly REQKICK_DOWNLOAD_URL="https://github.com/Shippable/reqKick/archive/master.tar.gz"
readonly CEXEC_DOWNLOAD_URL="https://github.com/Shippable/cexec/archive/master.tar.gz"
readonly REPORTS_DOWNLOAD_URL="https://s3.amazonaws.com/shippable-artifacts/reports/$SHIPPABLE_RELEASE_VERSION/reports-$SHIPPABLE_RELEASE_VERSION-$NODE_ARCHITECTURE-$NODE_OPERATING_SYSTEM.tar.gz"
readonly IS_SWAP_ENABLED=false

check_envs() {
  expected_envs=$1
  for env in "${expected_envs[@]}"
  do
    env_value=$(eval "echo \$$env")
    if [ -z "$env_value" ]; then
      echo "Missing ENV: $env"
      exit 1
    fi
  done
}

exec_cmd() {
  local cmd=$@
  eval $cmd
}

exec_grp() {
  local group_name=$1
  eval "$group_name"
}
__process_marker() {
  local prompt="$@"
  echo ""
  echo "# $(date +"%T") #######################################"
  echo "# $prompt"
  echo "##################################################"
}

__process_msg() {
  local message="$@"
  echo "|___ $@"
}

__process_error() {
  local message="$1"
  local error="$2"
  local bold_red_text='\e[91m'
  local reset_text='\033[0m'

  echo -e "$bold_red_text|___ $message$reset_text"
  echo -e "     $error"
}

__process_msg "adding dns settings to the node"
exec_cmd "echo 'supersede domain-name-servers 8.8.8.8, 8.8.4.4;' >> /etc/dhcp/dhclient.conf"

__process_msg "downloading node scripts tarball"
exec_cmd "wget '$NODE_TARBALL_URL' -O $NODE_SCRIPTS_DOWNLOAD_LOCATION"

__process_msg "creating node scripts dir"
exec_cmd "mkdir -p $NODE_SCRIPTS_LOCATION"

__process_msg "extracting node scripts"
exec_cmd "tar -xzvf '$NODE_SCRIPTS_DOWNLOAD_LOCATION' \
  -C $NODE_SCRIPTS_LOCATION \
  --strip-components=1"

__process_msg "Initializing node"
source "$NODE_SCRIPTS_LOCATION/initScripts/$NODE_ARCHITECTURE/$NODE_OPERATING_SYSTEM/$INIT_SCRIPT_NAME"
