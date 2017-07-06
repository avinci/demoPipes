#!/bin/bash -e

export CURR_JOB_CONTEXT=$1
export RES_REPO="auto_repo"
export RES_REPO_STATE=$(ship_get_resource_state $RES_REPO)
export NEW_TF_STATEFILE="$REPO_RES_CONTEXT/terraform.tfstate"


main() {
  ship_refresh_resource_state_file $NEW_TF_STATEFILE
}

main
