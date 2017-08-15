#!/bin/bash -e

export CURR_JOB_CONTEXT=$1
export STATE_RES=$2

export RES_REPO="auto_repo"
export RES_REPO_STATE=$(shipctl get_resource_state $RES_REPO)

export REPO_RES_CONTEXT="$RES_REPO_STATE/$CURR_JOB_CONTEXT"
export NEW_TF_STATEFILE="$REPO_RES_CONTEXT/terraform.tfstate"

main() {
  shipctl refresh_file_to_out_path $NEW_TF_STATEFILE $STATE_RES
}

main
