#!/bin/bash -e

set -o pipefail

export CURR_JOB=$1
export RES_AWS_CREDS=$2
export SHIPPABLE_RELEASE_VERSION="master"

# Now get AWS keys
export RES_AWS_CREDS_UP=$(echo $RES_AWS_CREDS | awk '{print toupper($0)}')
export RES_AWS_CREDS_INT=$RES_AWS_CREDS_UP"_INTEGRATION"

set_context(){

  # now get the AWS keys
  export AWS_ACCESS_KEY_ID=$(eval echo "$"$RES_AWS_CREDS_INT"_ACCESSKEY")
  export AWS_SECRET_ACCESS_KEY=$(eval echo "$"$RES_AWS_CREDS_INT"_SECRETKEY")

  echo "CURR_JOB=$CURR_JOB"
  echo "SOURCE_AMI=$SOURCE_AMI"
  echo "VPC_ID=$VPC_ID"
  echo "REGION=$REGION"
  echo "SUBNET_ID=$SUBNET_ID"
  echo "SECURITY_GROUP_ID=$SECURITY_GROUP_ID"
  echo "AWS_ACCESS_KEY_ID=${#AWS_ACCESS_KEY_ID}" #print only length not value
  echo "AWS_SECRET_ACCESS_KEY=${#AWS_SECRET_ACCESS_KEY}" #print only length not value
}

get_image_list() {
  export IMAGE_NAMES=$(cat images.txt)
  export IMAGE_NAMES_SPACED=$(eval echo $(tr '\n' ' ' < images.txt))
  echo "IMAGE_NAMES=$IMAGE_NAMES"
  echo "IMAGE_NAMES_SPACED=$IMAGE_NAMES_SPACED"
}

build_ami() {
  echo "-----------------------------------"
  echo "validating AMI template"
  echo "-----------------------------------"

  packer validate baseAMI.json

  echo "building AMI"
  echo "-----------------------------------"

  packer build -machine-readable -var aws_access_key=$AWS_ACCESS_KEY_ID \
    -var aws_secret_key=$AWS_SECRET_ACCESS_KEY \
    -var REGION=$REGION \
    -var VPC_ID=$VPC_ID \
    -var SUBNET_ID=$SUBNET_ID \
    -var SECURITY_GROUP_ID=$SECURITY_GROUP_ID \
    -var SOURCE_AMI=$SOURCE_AMI \
    -var IMAGE_NAMES_SPACED="${IMAGE_NAMES_SPACED}" \
    -var RES_IMG_VER_NAME=$SHIPPABLE_RELEASE_VERSION \
    -var RES_IMG_VER_NAME_DASH=$SHIPPABLE_RELEASE_VERSION \
    -var SHIPPABLE_RELEASE_VERSION=$SHIPPABLE_RELEASE_VERSION \
    baseAMI.json 2>&1 | tee output.txt

  # this is to get the ami from output
  echo versionName=$(cat output.txt | awk -F, '$0 ~/artifact,0,id/ {print $6}' \
    | cut -d':' -f 2) > "$JOB_STATE/$CURR_JOB.env"

  echo "RES_IMG_VER_NAME=$SHIPPABLE_RELEASE_VERSION" >> "$JOB_STATE/$CURR_JOB.env"
  echo "RES_IMG_VER_NAME_DASH=$SHIPPABLE_RELEASE_VERSION" >> "$JOB_STATE/$CURR_JOB.env"
  echo "IMAGE_NAMES_SPACED=$IMAGE_NAMES_SPACED" >> "$JOB_STATE/$CURR_JOB.env"

  cat "$JOB_STATE/$CURR_JOB.env"
}

main() {
  eval `ssh-agent -s`
  ps -eaf | grep ssh
  which ssh-agent

  set_context
  get_image_list
  build_ami
}

main
