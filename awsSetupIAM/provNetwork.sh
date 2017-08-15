#!/bin/bash -e

# since we are using params resource `net_conf` as an IN all the params are set
# automatically. $REGION, #VPC settings that are used in tfvars file

export ACTION=$1
export CURR_JOB_CONTEXT="awsSetupIAM"
export RES_REPO="auto_repo"
export RES_AWS_CREDS="aws_creds"

export STATE_RES="net_tf_state"
export TF_STATEFILE="terraform.tfstate"
export OUT_AMI_VPC="ami_vpc_conf"
export OUT_TEST_VPC="test_vpc_conf"
export OUT_PROD_VPC="prod_vpc_conf"

# get the path where gitRepo code is available
export RES_REPO_STATE=$(shipctl get_resource_state $RES_REPO)
export RES_REPO_CONTEXT="$RES_REPO_STATE/$CURR_JOB_CONTEXT"

# Now get AWS keys
export AWS_ACCESS_KEY_ID=$(shipctl get_integration_resource_field $RES_AWS_CREDS aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(shipctl get_integration_resource_field $RES_AWS_CREDS aws_secret_access_key)

set_context(){
  # This restores the terraform state file
  shipctl copy_resource_file_from_state $STATE_RES $TF_STATEFILE

  # now setup the variables based on context
  # naming the file terraform.tfvars makes terraform automatically load it
  shipctl replace terraform.tfvars
}

destroy_changes() {
  echo "----------------  Destroy changes  -------------------"
  terraform destroy -force
}

apply_changes() {
  echo "----------------  Planning changes  -------------------"
  terraform plan

  echo "-----------------  Apply changes  ------------------"
  terraform apply

  #output AMI VPC
  shipctl post_resource_state $OUT_AMI_VPC versionName \
    "Version from build $BUILD_NUMBER"
  shipctl put_resource_state $OUT_AMI_VPC REGION $REGION
  shipctl put_resource_state $OUT_AMI_VPC BASE_ECS_AMI \
    $(terraform output base_ecs_ami)
  shipctl put_resource_state $OUT_AMI_VPC AMI_VPC_ID \
    $(terraform output ami_vpc_id)
  shipctl put_resource_state $OUT_AMI_VPC AMI_PUBLIC_SN_ID \
    $(terraform output ami_public_sn_id)
  shipctl put_resource_state $OUT_AMI_VPC AMI_PUBLIC_SG_ID \
    $(terraform output ami_public_sg_id)

  #output TEST VPC
  shipctl post_resource_state $OUT_TEST_VPC versionName \
    "Version from build $BUILD_NUMBER"
  shipctl put_resource_state $OUT_TEST_VPC REGION $REGION
  shipctl put_resource_state $OUT_TEST_VPC TEST_VPC_ID \
    $(terraform output test_vpc_id)
  shipctl put_resource_state $OUT_TEST_VPC TEST_PUBLIC_SN_ID \
    $(terraform output test_public_sn_id)
  shipctl put_resource_state $OUT_TEST_VPC TEST_PUBLIC_SG_ID \
    $(terraform output test_public_sg_id)

  #output PROD VPC
  shipctl post_resource_state $OUT_PROD_VPC versionName \
    "Version from build $BUILD_NUMBER"
  shipctl put_resource_state $OUT_PROD_VPC REGION $REGION
  shipctl put_resource_state $OUT_PROD_VPC PROD_VPC_ID \
    $(terraform output test_vpc_id)
  shipctl put_resource_state $OUT_PROD_VPC PROD_PUBLIC_SN_ID \
    $(terraform output test_public_sn_id)
  shipctl put_resource_state $OUT_PROD_VPC PROD_PUBLIC_SG_ID \
    $(terraform output test_public_sg_id)
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
