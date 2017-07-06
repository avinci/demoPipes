#!/bin/bash -e

_set_shippable_name() {
  echo $(echo $1 | sed -e 's/[^a-zA-Z_0-9]//g')
}

_to_upper(){
  echo $(echo $1 | awk '{print toupper($0)}')
}

ship_get_resource_name() {
  _set_shippable_name $(_to_upper $1)
}

ship_get_resource_id() {
  UP=$(ship_get_resource_name $1)
  echo $(eval echo "$"$UP"_ID")
}

ship_get_resource_meta() {
  UP=$(ship_get_resource_name $1)
  echo $(eval echo "$"$UP"_META") #loc of integration.json
}

ship_get_resource_state() {
  UP=$(ship_get_resource_name $1)
  echo $(eval echo "$"$UP"_STATE")
}

ship_get_resource_operation() {
  UP=$(ship_get_resource_name $1)
  echo $(eval echo "$"$UP"_OPERATION")
}

ship_get_resource_type() {
  UP=$(ship_get_resource_name $1)
  echo $(eval echo "$"$UP"_TYPE")
}

ship_get_resource_state() {
  UP=$(ship_get_resource_name $1)
  echo $(eval echo "$"$UP"_STATE")
}

ship_get_resource_param_value() {
  UP=$(ship_get_resource_name $1)
  PARAMNAME=$(_set_shippable_name $(_to_upper $2))
  echo $(eval echo "$"$UP"_PARAMS_"$PARAMNAME)
}

ship_get_resource_integration_value() {
    UP=$(ship_get_resource_name $1)
    INTKEYNAME=$(_set_shippable_name $(_to_upper $2))
    echo $(eval echo "$"$UP"_INTEGRATION_"$INTKEYNAME)
}

ship_get_resource_version_name() {
    UP=$(ship_get_resource_name $1)
    echo $(eval echo "$"$UP"_VERSIONNAME")
}

ship_get_resource_version_id() {
  UP=$(ship_get_resource_name $1)
  echo $(eval echo "$"$UP"_VERSIONID")
}

ship_get_resource_version_number() {
  UP=$(ship_get_resource_name $1)
  echo $(eval echo "$"$UP"_VERSIONNUMBER")
}

ship_get_resource_integration_value() {
  META=$(ship_get_resource_meta $1)
  cat "$META/integration.json"  | jq -r '.'$2
}

ship_get_json_value() {
  cat $1 | jq -r '.'$2
}

ship_post_resource_state_value() {
  RES=$1
  STATENAME=$2
  STATEVALUE=$3
  echo $STATENAME=$STATEVALUE > "$JOB_STATE/$RES.env"
}

ship_put_resource_state_value() {
  RES=$1
  STATENAME=$2
  STATEVALUE=$3
  echo $STATENAME=$STATEVALUE >> "$JOB_STATE/$RES.env"
}

ship_copy_file_to_job_state() {
  FILENAME=$1
  cp -vr $FILENAME $JOB_STATE
}

ship_refresh_file_to_job_state() {
  NEWSTATEFILE=$1
  #this could contain path i.e / too and hence try and find only filename
  #greedy trimming ## is greedy, / is the string to look for and return last
  #part
  ONLYFILENAME=${NEWSTATEFILE##*/}

  if [ -f "$NEWSTATEFILE" ]; then
      echo "---------------  New state file exists, copying  ----------------"
      cp -vr $NEWSTATEFILE $JOB_STATE
  else
      local PREVSTATE="$JOB_PREVIOUS_STATE/$ONLYFILENAME"
      if [ -f "$PREVSTATE" ]; then
          echo ""
          echo "------  Previous state file exists, copying -----"
          cp -vr $PREVSTATE $JOB_STATE
      else
          echo "-------  No previous state file exists. Skipping  ---------"
      fi
  fi
}

ship_copy_file_from_job_prev_state() {
  PREV_TF_STATEFILE=$JOB_PREVIOUS_STATE/$1
  PATH_TO_RESTORE_IN=$2
  echo "---------------- Managing state file -------------------"
  if [ -f "$PREV_TF_STATEFILE" ]; then
    echo "------  State file exists, copying -----"
    cp -vr $PREV_TF_STATEFILE $PATH_TO_RESTORE_IN
  else
    echo "-------  No state file exists. Skipping  ---------"
  fi
}

ship_copy_file_from_resource_state() {
  RES_NAME=$1
  FILE_NAME=$2
  PATH_TO_COPY_INTO=$3
  FULL_PATH="/build/IN/"$RES_NAME"/state/"$FILE_NAME

  echo "---------------- Managing state file -------------------"
  if [ -f "$FULL_PATH" ]; then
    echo "------  State file exists, copying -----"
    cp -vr $FULL_PATH $PATH_TO_COPY_INTO
  else
    echo "-------  No state file exists. Skipping  ---------"
  fi
}

ship_refresh_file_to_resource_state() {
  FILE_NAME=$1
  RES_NAME=$2


  #this could contain path i.e / too and hence try and find only filename
  #greedy trimming ## is greedy, / is the string to look for and return last
  #part
  ONLYFILENAME=${FILE_NAME##*/}
  RES_OUT_PATH="/build/OUT/"$RES_NAME"/state"
  RES_IN_PATH="/build/IN/"$RES_NAME"/state"

    if [ -f "$FILE_NAME" ]; then
        echo "---------------  New state file exists, copying  ----------------"
        cp -vr $FILE_NAME $RES_OUT_PATH
    else
        local PREVSTATE="$RES_IN_PATH/$ONLYFILENAME"
        if [ -f "$PREVSTATE" ]; then
            echo ""
            echo "------  Previous state file exists, copying -----"
            cp -vr $PREVSTATE $RES_OUT_PATH
        else
            echo "-------  No previous state file exists. Skipping  ---------"
        fi
    fi
}
