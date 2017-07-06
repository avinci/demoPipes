#!/bin/bash -e

export CURR_JOB=$1
export RES_REPO="auto_repo"
export RES_AWS_CREDS="aws_creds"
export RES_AWS_PEM="aws_pem"
export PREV_TF_STATEFILE="terraform.tfstate"

# get the path where gitRepo code is available
export RES_REPO_STATE=$(ship_get_resource_state $RES_REPO)
export RES_REPO_CONTEXT="$RES_REPO_STATE/$CURR_JOB"

# Now get AWS keys
export AWS_ACCESS_KEY_ID=$(ship_get_resource_integration_value $RES_AWS_CREDS aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(ship_get_resource_integration_value $RES_AWS_CREDS aws_secret_access_key)

set_context(){
  pushd $RES_REPO_CONTEXT

  echo "CURR_JOB=$CURR_JOB"
  echo "RES_REPO=$RES_REPO"
  echo "RES_AWS_CREDS=$RES_AWS_CREDS"
  echo "RES_AWS_PEM=$RES_AWS_PEM"

  echo "RES_REPO_STATE=$RES_REPO_STATE"
  echo "RES_REPO_CONTEXT=$RES_REPO_CONTEXT"

  # This restores the terraform state file
  ship_restore_resource_state_file $PREV_TF_STATEFILE $RES_REPO_CONTEXT

  # This gets the PEM key for SSH into the machines
  ship_get_resource_integration_value $RES_AWS_PEM key > demo-key.pem
  chmod 600 demo-key.pem

  popd
}

destroy_changes() {
  pushd $RES_REPO_CONTEXT

  echo "----------------  Destroy changes  -------------------"
  terraform destroy -force \
    -var "aws_access_key_id=$AWS_ACCESS_KEY_ID" \
    -var "aws_secret_access_key=$AWS_SECRET_ACCESS_KEY"

  popd
}

apply_changes() {
  pushd $RES_REPO_CONTEXT

  echo "----------------  Planning changes  -------------------"
  terraform plan \
    -var "aws_access_key_id=$AWS_ACCESS_KEY_ID" \
    -var "aws_secret_access_key=$AWS_SECRET_ACCESS_KEY"

  echo "-----------------  Apply changes  ------------------"
  terraform apply \
    -var "aws_access_key_id=$AWS_ACCESS_KEY_ID" \
    -var "aws_secret_access_key=$AWS_SECRET_ACCESS_KEY"

  popd
}

main() {
  echo "----------------  Testing SSH  -------------------"
  eval `ssh-agent -s`
  ps -eaf | grep ssh
  which ssh-agent

  set_context
  destroy_changes
  #apply_changes
}

main
