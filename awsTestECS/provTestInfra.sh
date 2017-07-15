#!/bin/bash -e

export ACTION=$1
export CURR_JOB_CONTEXT="awsTestECS"
export STATE_RES="test_tf_state"
export RES_CONF="vpc_conf"
export RES_AMI="ami_sec_approved"
export OUT_RES_SET="test_env_ecs"

export RES_REPO="auto_repo"
export RES_AWS_CREDS="aws_creds"
export TF_STATEFILE="terraform.tfstate"

# get the path where gitRepo code is available
export RES_REPO_STATE=$(ship_resource_get_state $RES_REPO)
export RES_REPO_CONTEXT="$RES_REPO_STATE/$CURR_JOB_CONTEXT"

# Now get AWS keys
export AWS_ACCESS_KEY_ID=$(ship_resource_get_integration $RES_AWS_CREDS aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(ship_resource_get_integration $RES_AWS_CREDS aws_secret_access_key)

# Now get all VPC settings
export REGION=$(ship_resource_get_param $RES_CONF REGION)
export TEST_VPC_ID=$(ship_resource_get_param $RES_CONF TEST_VPC_ID)
export TEST_PUBLIC_SN_ID=$(ship_resource_get_param $RES_CONF TEST_PUBLIC_SN_ID)
export TEST_PUBLIC_SG_ID=$(ship_resource_get_param $RES_CONF TEST_PUBLIC_SG_ID)
export AMI_ID=$(ship_resource_get_param $RES_AMI AMI_ID)

set_context(){
  pushd $RES_REPO_CONTEXT

  echo "CURR_JOB_CONTEXT=$CURR_JOB_CONTEXT"
  echo "RES_REPO=$RES_REPO"
  echo "RES_AWS_CREDS=$RES_AWS_CREDS"
  echo "RES_REPO_CONTEXT=$RES_REPO_CONTEXT"

  echo "AWS_ACCESS_KEY_ID=${#AWS_ACCESS_KEY_ID}" #print only length not value
  echo "AWS_SECRET_ACCESS_KEY=${#AWS_SECRET_ACCESS_KEY}" #print only length not value

  # This restores the terraform state file
  ship_resource_copy_file_from_state $STATE_RES $TF_STATEFILE .

  # now setup the variables based on context
  # naming the file terraform.tfvars makes terraform automatically load it
  echo "aws_access_key_id = \"$AWS_ACCESS_KEY_ID\"" > terraform.tfvars
  echo "aws_secret_access_key = \"$AWS_SECRET_ACCESS_KEY\"" >> terraform.tfvars
  echo "region = \"$REGION\"" >> terraform.tfvars
  echo "test_vpc_id = \"$TEST_VPC_ID\"" >> terraform.tfvars
  echo "test_public_sn_id = \"$TEST_PUBLIC_SN_ID\"" >> terraform.tfvars
  echo "test_public_sg_id = \"$TEST_PUBLIC_SG_ID\"" >> terraform.tfvars
  echo "ami_id = \"$AMI_ID\"" >> terraform.tfvars

  popd
}

destroy_changes() {
  pushd $RES_REPO_CONTEXT

  echo "----------------  Destroy changes  -------------------"
  terraform destroy -force

  ship_resource_post_state $OUT_RES_SET versionName \
    "Version from build $BUILD_NUMBER"
  ship_resource_put_state $OUT_RES_SET PROV_STATE "Deleted"

  popd
}

apply_changes() {
  pushd $RES_REPO_CONTEXT

  echo "----------------  Planning changes  -------------------"
  terraform plan

  echo "-----------------  Apply changes  ------------------"
  terraform apply

  ship_resource_post_state $OUT_RES_SET versionName \
    "Version from build $BUILD_NUMBER"

  ship_resource_put_state $OUT_RES_SET PROV_STATE "Active"
  ship_resource_put_state $OUT_RES_SET REGION $REGION
  ship_resource_put_state $OUT_RES_SET TEST_ECS_INS_0_IP \
    $(terraform output test_ecs_ins_0_ip)
  ship_resource_put_state $OUT_RES_SET TEST_ECS_INS_1_IP \
    $(terraform output test_ecs_ins_1_ip)
  ship_resource_put_state $OUT_RES_SET TEST_ECS_CLUSTER_ID \
    $(terraform output test_ecs_cluster_id)

  popd
}

main() {
  echo "----------------  Testing SSH  -------------------"
  eval `ssh-agent -s`
  ps -eaf | grep ssh
  which ssh-agent

  set_context

  if [ $ACTION = "create" ]; then
    apply_changes
  fi

  if [ $ACTION = "destroy" ]; then
    destroy_changes
  fi
}

main
