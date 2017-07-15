#!/bin/bash -e
set -o pipefail

export CURR_JOB="test-job"
export RES_AWS_CREDS="aws_creds"

set_context(){
  # now get the AWS keys
  export AWS_ACCESS_KEY_ID=$(ship_resource_get_integration $RES_AWS_CREDS aws_access_key_id)
  export AWS_SECRET_ACCESS_KEY=$(ship_resource_get_integration $RES_AWS_CREDS aws_secret_access_key)

  echo "AVIN"
  echo $(ship_resource_get_type $CURR_JOB)
  echo $(ship_resource_get_meta $CURR_JOB)
  echo $(ship_resource_get_state $CURR_JOB)

  echo "AWS_ACCESS_KEY_ID=${#AWS_ACCESS_KEY_ID}" #print only length not value
  echo "AWS_SECRET_ACCESS_KEY=${#AWS_SECRET_ACCESS_KEY}" #print only length not value
}

main() {
  eval `ssh-agent -s`
  which ssh-agent


  set_context
}

main
