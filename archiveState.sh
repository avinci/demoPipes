#!/bin/bash -e

export CURR_JOB_CONTEXT=$1
export RES_REPO="auto_repo"
export STATE_RES="ami-tf-state"
export RES_REPO_STATE=$(ship_get_resource_state $RES_REPO)
export REPO_RES_CONTEXT="$RES_REPO_STATE/$CURR_JOB_CONTEXT"
export NEW_TF_STATEFILE="$REPO_RES_CONTEXT/terraform.tfstate"


echo "CURR_JOB_CONTEXT=$CURR_JOB_CONTEXT"
echo "RES_REPO=$RES_REPO"
echo "RES_REPO_STATE=$RES_REPO_STATE"
echo "REPO_RES_CONTEXT=$REPO_RES_CONTEXT"
echo "NEW_TF_STATEFILE=$NEW_TF_STATEFILE"


main() {
  ship_refresh_file_to_job_state $NEW_TF_STATEFILE
  ship_refresh_file_to_resource_state "$REPO_RES_CONTEXT/test.sh" $STATE_RES
}

main
