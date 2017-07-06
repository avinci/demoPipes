#!/bin/bash -e

export CURR_JOB_CONTEXT=$1
export STATE_RES=$2
export RES_REPO="auto_repo"
export RES_VPC="vpc_params"
export RES_AWS_CREDS="aws_creds"
export RES_AWS_PEM="aws_pem"
export OUT_RES_VPC_AMI="vpc_ami_params"
export TF_STATEFILE="terraform.tfstate"

# get the path where gitRepo code is available
export RES_REPO_STATE=$(ship_get_resource_state $RES_REPO)
export RES_REPO_CONTEXT="$RES_REPO_STATE/$CURR_JOB_CONTEXT"

# Now get AWS keys
export AWS_ACCESS_KEY_ID=$(ship_get_resource_integration_value $RES_AWS_CREDS aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(ship_get_resource_integration_value $RES_AWS_CREDS aws_secret_access_key)

# Now get all VPC settings
export REGION=$(ship_get_resource_param_value $RES_VPC REGION)
export AMI_VPC=$(ship_get_resource_param_value $RES_VPC AMI_VPC)
export AMI_NETWORK_CIDR=$(ship_get_resource_param_value $RES_VPC AMI_NETWORK_CIDR)
export AMI_PUBLIC_CIDR=$(ship_get_resource_param_value $RES_VPC AMI_PUBLIC_CIDR)

set_context(){
  pushd $RES_REPO_CONTEXT

  echo "CURR_JOB_CONTEXT=$CURR_JOB_CONTEXT"
  echo "RES_REPO=$RES_REPO"
  echo "RES_AWS_CREDS=$RES_AWS_CREDS"
  echo "RES_AWS_PEM=$RES_AWS_PEM"

  echo "RES_REPO_CONTEXT=$RES_REPO_CONTEXT"

  echo "AWS_ACCESS_KEY_ID=${#AWS_ACCESS_KEY_ID}" #print only length not value
  echo "AWS_SECRET_ACCESS_KEY=${#AWS_SECRET_ACCESS_KEY}" #print only length not value
  echo "REGION=$REGION"
  echo "AMI_VPC=$AMI_VPC"
  echo "AMI_NETWORK_CIDR=$AMI_NETWORK_CIDR"
  echo "AMI_PUBLIC_CIDR=$AMI_PUBLIC_CIDR"

  # This restores the terraform state file
  ship_copy_file_from_resource_state $STATE_RES $TF_STATEFILE .


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
    -var "aws_secret_access_key=$AWS_SECRET_ACCESS_KEY" \
    -var "region=$REGION" \
    -var "ami_vpc=$AMI_VPC" \
    -var "ami_network_cidr=$AMI_NETWORK_CIDR" \
    -var "ami_public_cidr=$AMI_PUBLIC_CIDR"

  popd
}

apply_changes() {
  pushd $RES_REPO_CONTEXT

  echo "----------------  Planning changes  -------------------"
  terraform plan \
    -var "aws_access_key_id=$AWS_ACCESS_KEY_ID" \
    -var "aws_secret_access_key=$AWS_SECRET_ACCESS_KEY" \
    -var "region=$REGION" \
    -var "ami_vpc=$AMI_VPC" \
    -var "ami_network_cidr=$AMI_NETWORK_CIDR" \
    -var "ami_public_cidr=$AMI_PUBLIC_CIDR"

  echo "-----------------  Apply changes  ------------------"
  terraform apply \
    -var "aws_access_key_id=$AWS_ACCESS_KEY_ID" \
    -var "aws_secret_access_key=$AWS_SECRET_ACCESS_KEY" \
    -var "region=$REGION" \
    -var "ami_vpc=$AMI_VPC" \
    -var "ami_network_cidr=$AMI_NETWORK_CIDR" \
    -var "ami_public_cidr=$AMI_PUBLIC_CIDR"

  ship_post_resource_state_value $OUT_RES_VPC_AMI versionName \
    "Version from build $BUILD_NUMBER"
  ship_put_resource_state_value $OUT_RES_VPC_AMI REGION $REGION
  ship_put_resource_state_value $OUT_RES_VPC_AMI AMI_VPC_ID \
    $(terraform output ami_vpc_id)
  ship_put_resource_state_value $OUT_RES_VPC_AMI AMI_PUBLIC_SN_ID \
    $(terraform output ami_public_sn_id)
  ship_put_resource_state_value $OUT_RES_VPC_AMI AMI_PUBLIC_SG_ID \
    $(terraform output ami_public_sg_id)

  cat $JOB_STATE/vpc_ami_params.env

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
