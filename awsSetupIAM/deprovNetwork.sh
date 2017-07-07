#!/bin/bash -e

export CURR_JOB_CONTEXT="awsSetupIAM"
export STATE_RES="ami-tf-state"
export OUT_RES_SET="vpc_conf"
export RES_REPO="auto_repo"
export RES_AWS_CREDS="aws_creds"

export TF_STATEFILE="terraform.tfstate"

# get the path where gitRepo code is available
export RES_REPO_STATE=$(ship_get_resource_state $RES_REPO)
export RES_REPO_CONTEXT="$RES_REPO_STATE/$CURR_JOB_CONTEXT"

# Now get AWS keys
export AWS_ACCESS_KEY_ID=$(ship_get_resource_integration_value $RES_AWS_CREDS aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(ship_get_resource_integration_value $RES_AWS_CREDS aws_secret_access_key)

set_context(){
  pushd $RES_REPO_CONTEXT

  echo "RES_REPO_CONTEXT=$RES_REPO_CONTEXT"
  echo "AWS_ACCESS_KEY_ID=${#AWS_ACCESS_KEY_ID}" #print only length not value
  echo "AWS_SECRET_ACCESS_KEY=${#AWS_SECRET_ACCESS_KEY}" #print only length not value

  # This restores the terraform state file
  ship_copy_file_from_resource_state $STATE_RES $TF_STATEFILE .

  # now setup the variables based on context
  # naming the file terraform.tfvars makes terraform automatically load it

  echo "aws_access_key_id = \"$AWS_ACCESS_KEY_ID\"" > terraform.tfvars
  echo "aws_secret_access_key = \"$AWS_SECRET_ACCESS_KEY\"" >> terraform.tfvars

  popd
}

destroy_changes() {
  pushd $RES_REPO_CONTEXT

  echo "----------------  Destroy changes  -------------------"
  terraform destroy -force

  popd
}

main() {
  echo "----------------  Testing SSH  -------------------"
  eval `ssh-agent -s`
  ps -eaf | grep ssh
  which ssh-agent

  set_context
  destroy_changes
}

main
