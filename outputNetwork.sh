#!/bin/bash -e
set -o pipefail

export CURR_JOB="aws_infra_setup"
export RES_AWS_CREDS="test_creds"

# make this come from terraform
export VPC_ID="vpc-1032db76"
export SUBNET_ID="subnet-1c0cda20"
export SECURITY_GROUP_ID="sg-d1c671ac"
export REGION="us-east-1"

# since resources here have dashes Shippable replaces them and UPPER cases them
export CURR_JOB_UP=$(echo $CURR_JOB | awk '{print toupper($0)}')
export CURR_JOB_STATE=$(eval echo "$"$CURR_JOB_UP"_STATE")

set_network_params(){

  echo "CURR_JOB=$CURR_JOB"
  echo "RES_AWS_CREDS=$RES_AWS_CREDS"

  echo "CURR_JOB_STATE=$CURR_JOB_STATE"
  echo "JOB_STATE=$JOB_STATE"

  echo "VPC_ID=$VPC_ID" >> "$JOB_STATE/$CURR_JOB.env"
  echo "SUBNET_ID=$SUBNET_ID" >> "$JOB_STATE/$CURR_JOB.env"
  echo "SECURITY_GROUP_ID=$SECURITY_GROUP_ID" >> "$JOB_STATE/$CURR_JOB.env"
  echo "REGION=$REGION" >> "$JOB_STATE/$CURR_JOB.env"
  cat "$JOB_STATE/$CURR_JOB.env"
}

main() {
  eval `ssh-agent -s`
  which ssh-agent

  set_network_params

}

main
