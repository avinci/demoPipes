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
    PARAMNAME=$(_set_shippable_name $(_to_upper $1))
    echo $(eval echo "$"$UP"_PARAM_"$PARAMNAME)
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
