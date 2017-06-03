#!/bin/bash -e
set -o pipefail

export CURR_JOB="test"
export RES_AWS_CREDS="test_creds"

# since resources here have dashes Shippable replaces them and UPPER cases them
export CURR_JOB_UP=$(echo $CURR_JOB | awk '{print toupper($0)}')
export CURR_JOB_STATE=$(eval echo "$"$CURR_JOB_UP"_STATE")

# Now get AWS keys
export RES_AWS_CREDS_UP=$(echo $RES_AWS_CREDS | awk '{print toupper($0)}')
export RES_AWS_CREDS_INT=$RES_AWS_CREDS_UP"_INTEGRATION"


set_context(){
  # now get the AWS keys
  export AWS_ACCESS_KEY_ID=$(eval echo "$"$RES_AWS_CREDS_INT"_AWS_ACCESS_KEY_ID")
  export AWS_SECRET_ACCESS_KEY=$(eval echo "$"$RES_AWS_CREDS_INT"_AWS_SECRET_ACCESS_KEY")

  echo "CURR_JOB=$CURR_JOB"
  echo "RES_AWS_CREDS=$RES_AWS_CREDS"

  echo "CURR_JOB_STATE=$CURR_JOB_STATE"
  echo "JOB_STATE=$JOB_STATE"
  echo "RES_AWS_CREDS_INT=$RES_AWS_CREDS_INT"

  echo "AWS_ACCESS_KEY_ID=${#AWS_ACCESS_KEY_ID}" #print only length not value
  echo "AWS_SECRET_ACCESS_KEY=${#AWS_SECRET_ACCESS_KEY}" #print only length not value
}

main() {
  eval `ssh-agent -s`
  which ssh-agent

  set_context

}

main
