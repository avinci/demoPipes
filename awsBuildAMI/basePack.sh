#!/bin/bash -e
set -o pipefail

export CURR_JOB="build_ecs_ami"
export RES_REPO="auto_repo"
export RES_PARAMS="network_params"
export RES_AWS_CREDS="aws_creds"
export AMI_PARAMS="ami_params"

export CURR_JOB_STATE=$(ship_get_resource_state $CURR_JOB)
export RES_REPO_STATE=$(ship_get_resource_state $RES_REPO)

# get network params
export REGION=$(ship_get_resource_param_value $RES_PARAMS REGION)
export VPC_ID=$(ship_get_resource_param_value $RES_PARAMS VPC_ID)
export SUBNET_ID=$(ship_get_resource_param_value $RES_PARAMS SUBNET_ID)
export SECURITY_GROUP_ID=$(ship_get_resource_param_value $RES_PARAMS SECURITY_GROUP_ID)
export SOURCE_AMI="ami-c8580bdf"

# Now get AWS keys
export AWS_ACCESS_KEY_ID=$(ship_get_resource_integration_value $RES_AWS_CREDS aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(ship_get_resource_integration_value $RES_AWS_CREDS aws_secret_access_key)

set_context(){
  echo "CURR_JOB=$CURR_JOB"
  echo "RES_AWS_CREDS=$RES_AWS_CREDS"
  echo "RES_PARAMS=$RES_PARAMS"
  echo "AMI_PARAMS=$AMI_PARAMS"
  echo "RES_REPO=$RES_REPO"

  echo "CURR_JOB_STATE=$CURR_JOB_STATE"
  echo "RES_REPO_STATE=$RES_REPO_STATE"

  echo "SOURCE_AMI=$SOURCE_AMI"
  echo "VPC_ID=$VPC_ID"
  echo "REGION=$REGION"
  echo "SUBNET_ID=$SUBNET_ID"
  echo "SECURITY_GROUP_ID=$SECURITY_GROUP_ID"
  echo "AWS_ACCESS_KEY_ID=${#AWS_ACCESS_KEY_ID}" #print only length not value
  echo "AWS_SECRET_ACCESS_KEY=${#AWS_SECRET_ACCESS_KEY}" #print only length not value
}

build_ecs_ami() {
  pushd "$RES_REPO_STATE/awsBuildAMI"
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
    baseAMI.json 2>&1 | tee output.txt

    #this is to get the ami from output
    AMI_ID=$(cat output.txt | awk -F, '$0 ~/artifact,0,id/ {print $6}' \
    | cut -d':' -f 2)

    ship_post_resource_state_value $CURR_JOB versionName $AMI_ID
    ship_post_resource_state_value $AMI_PARAMS versionName $AMI_ID

    ship_get_json_value manifest.json builds.artifact_id

  popd
}

main() {
  eval `ssh-agent -s`
  which ssh-agent

  set_context
  build_ecs_ami
}

main
