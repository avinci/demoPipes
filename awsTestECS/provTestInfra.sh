#!/bin/bash -e

export ACTION=$1
export CURR_JOB_CONTEXT="awsTestECS"
export RES_REPO="auto_repo"
export RES_AWS_CREDS="aws_creds"

export STATE_RES="test_tf_state"
export TF_STATEFILE="terraform.tfstate"
export OUT_RES_SET="test_env_ecs"

# get the path where gitRepo code is available
export RES_REPO_STATE=$(ship_resource_get_state $RES_REPO)
export RES_REPO_CONTEXT="$RES_REPO_STATE/$CURR_JOB_CONTEXT"

# Now get AWS keys
export AWS_ACCESS_KEY_ID=$(ship_resource_get_integration $RES_AWS_CREDS aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(ship_resource_get_integration $RES_AWS_CREDS aws_secret_access_key)

set_context(){
  # This restores the terraform state file
  shipctl copy_resource_file_from_state $STATE_RES $TF_STATEFILE .

  # now setup the variables based on context
  # naming the file terraform.tfvars makes terraform automatically load it
  shipctl replace terraform.tfvars
}

destroy_changes() {
  echo "----------------  Destroy changes  -------------------"
  terraform destroy -force

  shipctl post_resource_state $OUT_RES_SET versionName \
    "Version from build $BUILD_NUMBER"
  shipctl put_resource_state $OUT_RES_SET PROV_STATE "Deleted"
}

apply_changes() {
  echo "----------------  Planning changes  -------------------"
  terraform plan

  echo "-----------------  Apply changes  ------------------"
  terraform apply

  shipctl post_resource_state $OUT_RES_SET versionName \
    "Version from build $BUILD_NUMBER"

  shipctl put_resource_state $OUT_RES_SET PROV_STATE "Active"
  shipctl put_resource_state $OUT_RES_SET REGION $REGION
  shipctl put_resource_state $OUT_RES_SET TEST_ECS_INS_0_IP \
    $(terraform output test_ecs_ins_0_ip)
  shipctl put_resource_state $OUT_RES_SET TEST_ECS_INS_1_IP \
    $(terraform output test_ecs_ins_1_ip)
  shipctl put_resource_state $OUT_RES_SET TEST_ECS_CLUSTER_ID \
    $(terraform output test_ecs_cluster_id)
}

main() {
  echo "----------------  Testing SSH  -------------------"
  eval `ssh-agent -s`
  ps -eaf | grep ssh
  which ssh-agent

  pushd $RES_REPO_CONTEXT

  set_context

  if [ $ACTION = "create" ]; then
    apply_changes
  fi

  if [ $ACTION = "destroy" ]; then
    destroy_changes
  fi

  popd
}

main
