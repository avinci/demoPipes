#!/bin/bash -e

export TF_INSALL_LOCATION=/opt
export TF_VERSION=0.8.6

export CURR_JOB=$1

export RES_REPO="auto_repo"
export RES_AWS_CREDS="aws_creds"
export RES_AWS_PEM="aws_pem"

export PREV_TF_STATEFILE="$JOB_PREVIOUS_STATE/terraform.tfstate"

export RES_REPO_UP=$(echo $RES_REPO | awk '{print toupper($0)}')
export RES_REPO_STATE=$(eval echo "$"$RES_REPO_UP"_STATE") #loc of git repo clone
export RES_REPO_CONTEXT="$RES_REPO_STATE/$CURR_JOB"

export RES_AWS_CREDS_UP=$(echo $RES_AWS_CREDS | awk '{print toupper($0)}')
export RES_AWS_CREDS_META=$(eval echo "$"$RES_AWS_CREDS_UP"_META") #loc of integration.json

export RES_AWS_PEM_UP=$(echo $RES_AWS_PEM | awk '{print toupper($0)}')
export RES_AWS_PEM_META=$(eval echo "$"$RES_AWS_PEM_UP"_META") #loc of integration.json


set_context(){
  echo "CURR_JOB=$CURR_JOB"
  echo "RES_REPO=$RES_REPO"
  echo "RES_AWS_CREDS=$RES_AWS_CREDS"
  echo "RES_AWS_PEM=$RES_AWS_PEM"

  echo "RES_REPO_UP=$RES_REPO_UP"
  echo "RES_REPO_STATE=$RES_REPO_STATE"
  echo "RES_REPO_CONTEXT=$RES_REPO_CONTEXT"

  echo "RES_AWS_CREDS_UP=$RES_AWS_CREDS_UP"
  echo "RES_AWS_CREDS_INT=$RES_AWS_CREDS_INT"
  echo "RES_AWS_PEM_UP=$RES_AWS_PEM_UP"
  echo "RES_AWS_PEM_META=$RES_AWS_PEM_META"
}

install_terraform() {
  pushd $TF_INSALL_LOCATION
  echo "Fetching terraform"
  echo "-----------------------------------"

  rm -rf $TF_INSALL_LOCATION/terraform
  mkdir -p $TF_INSALL_LOCATION/terraform

  wget -q https://releases.hashicorp.com/terraform/$TF_VERSION/terraform_"$TF_VERSION"_linux_386.zip
  apt-get install unzip
  unzip -o terraform_"$TF_VERSION"_linux_386.zip -d $TF_INSALL_LOCATION/terraform
  export PATH=$PATH:$TF_INSALL_LOCATION/terraform
  echo "downloaded terraform successfully"
  echo "-----------------------------------"
  
  local tf_version=$(terraform version)
  echo "Terraform version: $tf_version"
  popd
}

get_statefile() {
  echo "Managing state file"
  echo "-----------------------------------"
  if [ -f "$PREV_TF_STATEFILE" ]; then
    echo "Statefile exists, copying"
    echo "-----------------------------------"
    cp -vr $PREV_TF_STATEFILE $RES_REPO_CONTEXT
  else
    echo "No previous statefile exists"
    echo "-----------------------------------"
  fi
}

create_pemfile() {
 echo "Extracting AWS PEM"
 echo "-----------------------------------"
 cat "$RES_AWS_PEM_META/integration.json"  | jq -r '.key' > "$RES_REPO_CONTEXT/demo-key.pem"
 chmod 600 "$RES_REPO_CONTEXT/demo-key.pem"
 echo "Completed Extracting AWS PEM"
 echo "-----------------------------------"
}

destroy_changes() {
  pushd $RES_REPO_CONTEXT
  echo "-----------------------------------"

  echo "Destroy changes"
  echo "-----------------------------------"
  terraform destroy -force -var-file="$RES_AWS_CREDS_META/integration.env"
  popd
}

apply_changes() {
  pushd $RES_REPO_CONTEXT

  echo "Testing SSH"
  echo "-----------------------------------"
  ps -eaf | grep ssh
  which ssh-agent

  echo "Planning changes"
  echo "-----------------------------------"
  terraform plan -var-file="$RES_AWS_CREDS_META/integration.env"

  echo "Apply changes"
  echo "-----------------------------------"
  terraform apply -var-file="$RES_AWS_CREDS_META/integration.env"

  popd
}

main() {
  eval `ssh-agent -s`
  set_context
  install_terraform
  get_statefile
  create_pemfile
  #destroy_changes
  apply_changes
}

main
