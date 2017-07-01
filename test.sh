#!/bin/bash -e
set -o pipefail

export CURR_JOB="test-job"
export RES_AWS_CREDS="aws_creds"

set_context(){
  # now get the AWS keys
  export AWS_ACCESS_KEY_ID=$(ship_get_resource_integration_value $RES_AWS_CREDS AWS_ACCESS_KEY_ID)
  export AWS_SECRET_ACCESS_KEY=$(ship_get_resource_integration_value $RES_AWS_CREDS AWS_SECRET_ACCESS_KEY)

  echo "AWS_ACCESS_KEY_ID=${#AWS_ACCESS_KEY_ID}" #print only length not value
  echo "AWS_SECRET_ACCESS_KEY=${#AWS_SECRET_ACCESS_KEY}" #print only length not value
}

main() {
  eval `ssh-agent -s`
  which ssh-agent

  pushd IN/auto_repo/gitRepo
  ./shipUtil.sh
  set_context
  popd
}

main
