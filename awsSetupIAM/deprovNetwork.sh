#!/bin/bash -e

export CURR_JOB_CONTEXT="awsSetupIAM"
export STATE_RES="ami-tf-state"
export OUT_RES_SET="vpc_conf"
export RES_REPO="auto_repo"
export RES_AWS_CREDS="aws_creds"
export RES_CONF="net_conf"

export TF_STATEFILE="terraform.tfstate"

# get the path where gitRepo code is available
export RES_REPO_STATE=$(ship_get_resource_state $RES_REPO)
export RES_REPO_CONTEXT="$RES_REPO_STATE/$CURR_JOB_CONTEXT"

# Now get AWS keys
export AWS_ACCESS_KEY_ID=$(ship_get_resource_integration_value $RES_AWS_CREDS aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(ship_get_resource_integration_value $RES_AWS_CREDS aws_secret_access_key)

# Now get all VPC settings
export REGION=$(ship_get_resource_param_value $RES_CONF REGION)
export AMI_VPC=$(ship_get_resource_param_value $RES_CONF AMI_VPC)
export AMI_NETWORK_CIDR=$(ship_get_resource_param_value $RES_CONF AMI_NETWORK_CIDR)
export AMI_PUBLIC_CIDR=$(ship_get_resource_param_value $RES_CONF AMI_PUBLIC_CIDR)
export TEST_VPC=$(ship_get_resource_param_value $RES_CONF TEST_VPC)
export TEST_NETWORK_CIDR=$(ship_get_resource_param_value $RES_CONF TEST_NETWORK_CIDR)
export TEST_PUBLIC_CIDR=$(ship_get_resource_param_value $RES_CONF TEST_PUBLIC_CIDR)

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
  echo "region = \"$REGION\"" >> terraform.tfvars
  echo "ami_vpc = \"$AMI_VPC\"" >> terraform.tfvars
  echo "ami_network_cidr = \"$AMI_NETWORK_CIDR\"" >> terraform.tfvars
  echo "ami_public_cidr = \"$AMI_PUBLIC_CIDR\"" >> terraform.tfvars
  echo "test_vpc = \"$TEST_VPC\"" >> terraform.tfvars
  echo "test_network_cidr = \"$TEST_NETWORK_CIDR\"" >> terraform.tfvars
  echo "test_public_cidr = \"$TEST_PUBLIC_CIDR\"" >> terraform.tfvars

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
