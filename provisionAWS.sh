#!/bin/bash -e

export TF_INSALL_LOCATION=/opt
export TF_VERSION=0.8.6

export CURR_JOB_CONTEXT=$1

export REPO_RES="auto_repo"
export AWS_CREDS_RES="aws_creds"
export AWS_PEM_RES="aws_pem"

export PREV_TF_STATEFILE="$JOB_PREVIOUS_STATE/terraform.tfstate"

export REPO_RES_UP=$(echo $REPO_RES | awk '{print toupper($0)}')
export REPO_RES_STATE=$(eval echo "$"$REPO_RES_UP"_STATE") #loc of git repo clone
export REPO_RES_CONTEXT="$REPO_RES_STATE/$CURR_JOB_CONTEXT"

export AWS_CREDS_RES_UP=$(echo $AWS_CREDS_RES | awk '{print toupper($0)}')
export AWS_CREDS_RES_META=$(eval echo "$"$AWS_CREDS_RES_UP"_META") #loc of integration.json

export AWS_PEM_RES_UP=$(echo $AWS_PEM_RES | awk '{print toupper($0)}')
export AWS_PEM_RES_META=$(eval echo "$"$AWS_PEM_RES_UP"_META") #loc of integration.json

test_env_info() {
  echo "Testing all environment variables that are critical"

  echo "########### CURR_JOB_CONTEXT: $CURR_JOB_CONTEXT"
  echo "########### PREV_TF_STATEFILE: $PREV_TF_STATEFILE"

  echo "########### REPO_RES: $REPO_RES"
  echo "########### REPO_RES_UP: $REPO_RES_UP"
  echo "########### REPO_RES_STATE: $REPO_RES_STATE"
  echo "########### REPO_RES_CONTEXT: $REPO_RES_CONTEXT"

  echo "########### AWS_CREDS_RES: $AWS_CREDS_RES"
  echo "########### AWS_CREDS_RES_UP: $AWS_CREDS_RES_UP"
  echo "########### AWS_CREDS_RES_META: $AWS_CREDS_RES_META"

  echo "########### AWS_PEM_RES: $AWS_PEM_RES"
  echo "########### AWS_PEM_RES_UP: $AWS_PEM_RES_UP"
  echo "########### AWS_PEM_RES_META: $AWS_PEM_RES_META"

  echo "successfully loaded node information"
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
    cp -vr $PREV_TF_STATEFILE $REPO_RES_CONTEXT
  else
    echo "No previous statefile exists"
    echo "-----------------------------------"
  fi
}

create_pemfile() {
 echo "Extracting AWS PEM"
 echo "-----------------------------------"
 cat "$AWS_PEM_RES_META/integration.json"  | jq -r '.key' > "$REPO_RES_CONTEXT/demo-key.pem"
 chmod 600 "$REPO_RES_CONTEXT/demo-key.pem"
 echo "Completed Extracting AWS PEM"
 echo "-----------------------------------"
}

destroy_changes() {
  pushd $REPO_RES_CONTEXT
  echo "-----------------------------------"

  echo "Destroy changes"
  echo "-----------------------------------"
  terraform destroy -force -var-file="$AWS_CREDS_RES_META/integration.env"
  popd
}

apply_changes() {
  pushd $REPO_RES_CONTEXT

  echo "Testing SSH"
  echo "-----------------------------------"
  ps -eaf | grep ssh
  which ssh-agent

  echo "Planning changes"
  echo "-----------------------------------"
  terraform plan -var-file="$AWS_CREDS_RES_META/integration.env"

  echo "Apply changes"
  echo "-----------------------------------"
  terraform apply -var-file="$AWS_CREDS_RES_META/integration.env"

  popd
}

main() {
  eval `ssh-agent -s`
  test_env_info
  install_terraform
  get_statefile
  create_pemfile
  #destroy_changes
  apply_changes
}

main
