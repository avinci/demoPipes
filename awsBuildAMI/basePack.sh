#!/bin/bash -e
set -o pipefail

export CURR_JOB="build_baseami"
export RES_AWS_CREDS="aws_creds"
export RES_PARAMS="network_params"
export RES_REPO="auto_repo"
export AMI_PARAMS="ami_params"

# since resources here have dashes Shippable replaces them and UPPER cases them
export CURR_JOB_UP=$(echo $CURR_JOB | awk '{print toupper($0)}')
export CURR_JOB_STATE=$(eval echo "$"$CURR_JOB_UP"_STATE")

# since resources here have dashes Shippable replaces them and UPPER cases them
export RES_PARAMS_UP=$(echo $RES_PARAMS | awk '{print toupper($0)}')
export RES_PARAMS_STR=$RES_PARAMS_UP"_PARAMS"

# Now get AWS keys
export RES_AWS_CREDS_UP=$(echo $RES_AWS_CREDS | awk '{print toupper($0)}')
export RES_AWS_CREDS_INT=$RES_AWS_CREDS_UP"_INTEGRATION"

# set the repo path
export RES_REPO_UP=$(echo $RES_REPO | awk '{print toupper($0)}')
export RES_REPO_STATE=$(eval echo "$"$RES_REPO_UP"_STATE")

set_context(){
  # now get all the parameters for ami location
  export REGION=$(eval echo "$"$RES_PARAMS_STR"_REGION")
  export VPC_ID=$(eval echo "$"$RES_PARAMS_STR"_VPC_ID")
  export SUBNET_ID=$(eval echo "$"$RES_PARAMS_STR"_SUBNET_ID")
  export SECURITY_GROUP_ID=$(eval echo "$"$RES_PARAMS_STR"_SECURITY_GROUP_ID")
  export SOURCE_AMI="ami-c8580bdf"

  # now get the AWS keys
  export AWS_ACCESS_KEY_ID=$(eval echo "$"$RES_AWS_CREDS_INT"_AWS_ACCESS_KEY_ID")
  export AWS_SECRET_ACCESS_KEY=$(eval echo "$"$RES_AWS_CREDS_INT"_AWS_SECRET_ACCESS_KEY")

  echo "CURR_JOB=$CURR_JOB"
  echo "RES_AWS_CREDS=$RES_AWS_CREDS"
  echo "RES_PARAMS=$RES_PARAMS"
  echo "AMI_PARAMS=$AMI_PARAMS"
  echo "RES_REPO=$RES_REPO"

  echo "CURR_JOB_STATE=$CURR_JOB_STATE"
  echo "JOB_STATE=$JOB_STATE"
  echo "RES_AWS_CREDS_INT=$RES_AWS_CREDS_INT"
  echo "RES_PARAMS_STR=$RES_PARAMS_STR"
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
    echo versionName=$(cat output.txt | awk -F, '$0 ~/artifact,0,id/ {print $6}' \
    | cut -d':' -f 2) > "$JOB_STATE/$CURR_JOB.env"

    #this is to get the ami from output
    echo versionName=$(cat output.txt | awk -F, '$0 ~/artifact,0,id/ {print $6}' \
    | cut -d':' -f 2) > "$JOB_STATE/$AMI_PARAMS.env"

  popd
}

main() {
  eval `ssh-agent -s`
  which ssh-agent

  set_context
  build_ecs_ami
}

main
