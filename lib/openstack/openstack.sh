if [[ -z $WORKSPACE ]]; then WORKSPACE=`dirname $0/../..`; fi

function sourceTenant {
    if [[ $# -ne 2 ]]; then return 1 ; fi
    local CLOUD="$1"
    local TENANT="$2"
    local AUTHEN_FILE=$WORKSPACE/proprietary/$CLOUD/$TENANT-openrc.sh
    if [[ -f $AUTHEN_FILE ]]
    then
        source $AUTHEN_FILE
    else
        echo "File not found. Using user input..."
        echo "Input username and press Enter:"
        read -r OS_USERNAME
        echo "Input password (silent mode) and press Enter:"
        read -sr OS_PASSWORD
        export OS_AUTH_URL="${cloud_endpoint[$CLOUD]}"
        export OS_PROJECT_NAME=$TENANT
        export OS_USERNAME=$OS_USERNAME
        export OS_PASSWORD=$OS_PASSWORD
        export OS_DOMAIN_NAME='Default'
        export OS_DOMAIN_ID='default'
    fi
}

function getVnfmLastSuccesfulBuild {
    if [[ $# -ne 1 ]]; then return 1 ; fi
    local PRODUCT_RELEASE="$1"
    local LAST_SUCCESSFUL_BUILD=$(curl -sSL "$VNFM_ARTIFACTORY_URL/$PRODUCT_RELEASE/Artifacts/lastSuccessfulBuild/heatTemplates/" | grep -E 'href="([^"#]+)"' |  cut '-d"' -f2 | grep $HA_HEAT_TEMPLATE_PATTERN | awk -F'_' '{ print $5}' | awk -F'-' '{print $2}' | awk -F'.' '{print $1}')
    echo "$LAST_SUCCESSFUL_BUILD"
}

function glanceGetImageId {
    if [[ $# -ne 1 ]]; then return 1 ; fi
    local IMAGE_NAME="$1"
    local IMAGE_ID=$(glance image-list | grep "$IMAGE_NAME" | awk '{print$2}')
    local OUTPUT=$(glance image-show "$IMAGE_ID" | grep status | awk '{print $4}')
    if [ "$OUTPUT" == "active" ]; then 
        echo ${IMAGE_ID}
    else 
        echo "Unavailable"
    fi
}

function glanceImageUpload {
    local IMAGE_NAME="$1"
    local IMAGE_STORE_FOLDER="$2"
    local IMAGE_ID=$( glance image-create --name "$IMAGE_NAME" --file "$IMAGE_STORE_FOLDER"/"$IMAGE_NAME" --disk-format qcow2 --container-format bare --visibility public --tags "VNFM_SVT" | grep id | awk '{print $4}' )
    echo IMAGE_ID
}

function heatStackCreateHA {
    local TOPOLOGY_NAME=$1
    local HEAT_TEMPLATE=$2
    local APP_IMAGE_ID=$3
    local DB_IMAGE_ID=$4
    local LB_IMAGE_ID=$5
    local EXTERNAL_NETWORK_NAME_1=$6
    local PROVIDER=$7
    local IPV6=$8

    local stack_create_loop_counter=1
    local stack_create=1
    if [[ $IPV6 == "true" ]]
    then
        if [[ $PROVIDER == "provider" ]]
        then 
            local ipv4_floating_network=false
            local ipv4_provider_network=true
        else
            local ipv4_floating_network=true
            local ipv4_provider_network=false
        fi
        local dns_servers=[10.2.1.2]
    else
        local ipv4_floating_network=false
        local ipv4_provider_network=false
        local ipv6_provider_network=true
        local dns_servers=[fd00:1000:1000:3121::5]
    fi
    while [ $stack_create -eq 1 ]
    do
        heat stack-create -f ${HEAT_TEMPLATE} \
        -P "availability_zone=general" \
        -P "lb_image_id=$LB_IMAGE_ID" \
        -P "db_image_id=$DB_IMAGE_ID" \
        -P "app_image_id=$APP_IMAGE_ID" \
        -P "ipv4_floating_network=$ipv4_floating_network" \
        -P "ipv4_provider_network=$ipv4_provider_network" \
        -P "ipv6_provider_network=$ipv6_provider_network" \
        -P "public_net_v4=$EXTERNAL_NETWORK_NAME_1" \
        -P "public_net_v4_subnet_id=1111" \
        -P "public_net_v6=$EXTERNAL_NETWORK_NAME_1" \
        -P "public_net_v6_subnet_id=1111" \
        -P "vnfm_public_key=$(cat $WORKSPACE/keypairs/openstack.pub)" \
        -P "dns_servers=$dns_servers" \
        "$TOPOLOGY_NAME"
        local stack_create_return_value=$(echo $?)
    
        if [ $stack_create_return_value -ne 0 ]; then
            stack_create_loop_counter=$((stack_create_loop_counter+1))
            if [ $stack_create_loop_counter -eq 6 ]; then
                echo "$ERROR Tried to create the stack for a minute (6 times with 10 sleeps). Stop!"
                exit 123
            fi
            sleep 10
            else
            stack_create=0
            echo "$INFO Stack Created Successfully!"
        fi
    done
}