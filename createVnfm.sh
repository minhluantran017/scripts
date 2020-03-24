#!/bin/bash
WORKSPACE=`dirname $0`
source $WORKSPACE/proprietary/general_info.sh
source $WORKSPACE/lib/common/utils.sh
source $WORKSPACE/lib/openstack/openstack.sh

echo "$INFO $(date)"

function printHelp {
    echo 'Script for setting up a VNFM HA.'
    echo 'Usage:'
    echo "    $0 --cloud <cloud_name> --tenant <tenant_name> --name <stack_name> <network_type>"
    echo 'Parameters:'
    echo '    -c, --cloud    <cloud_name>       : (required) OTT-PC2 | PLA-PC2 | WFD-PC2'
    echo '    -t, --tenant   <tenant_name>      : (required) your Openstack tenant name'
    echo '    -n, --name     <stack_name>       : (required) your stack name. Only use characters, digits, and _ or -'
    echo '    -p, --prov                        : (optional) deploy with provider network? Default to false'
    echo 'Options:'
    echo '    -V, --version                     : Print script version'
    echo '    -h, --help                        : Print this help'
    echo 'Examples:'
    echo "    $0 -c OTT-PC2 -t OTT.PC2.SV.VNFM.SANITY   -n VNFM-Test-1"
    echo "    $0 -c PLA-PC2 -t PLA.PC2.SV.VNFM.HA       -n VNFM-Test-2 --prov"
    echo "    $0 -c WFD-PC2 -t WFD.PC2.VNFM.JENKINS     -n VNFM-Test-3 --prov"
    exit 128
}

if [ -z "$1" ]; then
    printHelp
fi

echo "$INFO Setting environments..."
while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
    -V | --version )
        echo "There is no version until now :)"
        exit
        ;;
    -h | --help )
        printHelp
        exit
        ;;
    -c | --cloud )
        shift; CLOUD="$1"
        ;;
    -t | --tenant )
        shift; TENANT="$1"
        ;;
    -n | --name )
        shift; TOPOLOGY_NAME="$1"
        ;;
    -p | --prov )
        PROVIDER=1;
        ;;
esac; shift; done
if [[ "$1" == '--' ]]; then shift; fi

ZONE="general"
PRODUCT_RELEASE="mainline"

if [ "$CLOUD" == "PLA-PC2" ]; then
    EXTERNAL_NETWORK_NAME_1="EXT_RTP_0_V4"
    EXTERNAL_SUBNET_NAME_1="1111"
elif [ "$CLOUD" == "OTT-PC2" ]; then
    EXTERNAL_NETWORK_NAME_1="External OAM-V4"
    EXTERNAL_SUBNET_NAME_1="1111"
elif [ "$CLOUD" == "WFD-PC2" ]; then
    EXTERNAL_NETWORK_NAME_1="EXT_RTP_0_V4"
    EXTERNAL_SUBNET_NAME_1="1111"
fi

LAST_SUCCESSFUL_BUILD=`getVnfmLastSuccesfulBuild $PRODUCT_RELEASE`
echo "Last succesful build is $LAST_SUCCESSFUL_BUILD ."
read -p " Do you want to continue (y/n)?" -n 1 -r
if [[ $REPLY =~ ^[Nn]$ ]]
then
    echo "Please input the build number below:"
    read -r BUILD
fi
if [ "" -eq "$BUILD" ]; then
    BUILD_NUMBER="Build-$LAST_SUCCESSFUL_BUILD"
else
    BUILD_NUMBER="Build-$BUILD"
fi

echo "$INFO Source tenant RC file..."
sourceTenant $CLOUD $TENANT

echo "$INFO Create folder to store template..."
HEAT_TEMPLATE_FOLDER=~/AUTOMATION/HEAT/${BUILD_NUMBER}
echo "$INFO Downloading HEAT template..."
downloadFile ${HEAT_TEMPLATE_FOLDER}  ${ARTIFACTORY_URL}/${PRODUCT_RELEASE}/Artifacts/${BUILD_NUMBER}/heatTemplates/$HA_HEAT_TEMPLATE_PATTERN*
echo "$INFO Heat template is successfully downloaded into folder $HEAT_TEMPLATE_FOLDER"

echo "$INFO Check image availability on cloud..."
APP_IMAGE_NAME=$(curl -sS "$ARTIFACTORY_URL/$PRODUCT_RELEASE/Artifacts/$BUILD_NUMBER/" | grep -E 'href="([^"#]+)"' |  cut '-d"' -f2 | grep app)
DB_IMAGE_NAME=$(curl -sS "$ARTIFACTORY_URL/$PRODUCT_RELEASE/Artifacts/$BUILD_NUMBER/" | grep -E 'href="([^"#]+)"' |  cut '-d"' -f2 | grep db)
LB_IMAGE_NAME=$(curl -sS "$ARTIFACTORY_URL/$PRODUCT_RELEASE/Artifacts/$BUILD_NUMBER/" | grep -E 'href="([^"#]+)"' |  cut '-d"' -f2 | grep lb)

APP_IMAGE_ID=$(glanceGetImageId $APP_IMAGE_NAME)
if [ "$APP_IMAGE_ID" == "Unavailable" ]; then 
    echo "$WARNING Image $APP_IMAGE_NAME is unavailable."
    read -p " Do you want to continue (y/n)?" -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        APP_IMAGE_DIR=$(mktemp -d)
        echo "$INFO Downloading $APP_IMAGE_NAME to $APP_IMAGE_DIR..."
        downloadFile $APP_IMAGE_DIR ${VNFM_ARTIFACTORY_URL}/${PRODUCT_RELEASE}/Artifacts/${BUILD_NUMBER}/${APP_IMAGE_NAME}
        echo "$INFO Uploading $APP_IMAGE_NAME to cloud..."
        APP_IMAGE_ID=$(glanceImageUpload $APP_IMAGE_NAME $APP_IMAGE_DIR)
        rm -rf $APP_IMAGE_DIR
    fi
fi

DB_IMAGE_ID=$(glanceGetImageId $DB_IMAGE_NAME)
if [ "$DB_IMAGE_ID" == "Unavailable" ]; then 
    echo "$WARNING Image $DB_IMAGE_NAME is unavailable."
    read -p " Do you want to continue (y/n)?" -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        DB_IMAGE_DIR=$(mktemp -d)
        echo "$INFO Downloading $DB_IMAGE_NAME to $DB_IMAGE_DIR..."
        downloadFile $DB_IMAGE_DIR ${VNFM_ARTIFACTORY_URL}/${PRODUCT_RELEASE}/Artifacts/${BUILD_NUMBER}/${DB_IMAGE_NAME}
        echo "$INFO Uploading $DB_IMAGE_NAME to cloud..."
        DB_IMAGE_ID=$(glanceImageUpload $DB_IMAGE_NAME $DB_IMAGE_DIR)
        rm -rf $DB_IMAGE_DIR
    fi
fi

LB_IMAGE_ID=$(glanceGetImageId $LB_IMAGE_NAME)
if [ "$LB_IMAGE_ID" == "Unavailable" ]; then 
    echo "$WARNING Image $LB_IMAGE_NAME is unavailable."
    read -p " Do you want to continue (y/n)?" -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        LB_IMAGE_DIR=$(mktemp -d)
        echo "$INFO Downloading $LB_IMAGE_NAME to $LB_IMAGE_DIR..."
        downloadFile $LB_IMAGE_DIR ${VNFM_ARTIFACTORY_URL}/${PRODUCT_RELEASE}/Artifacts/${BUILD_NUMBER}/${LB_IMAGE_NAME}
        echo "$INFO Uploading $LB_IMAGE_NAME to cloud..."
        LB_IMAGE_ID=$(glanceImageUpload $LB_IMAGE_NAME $LB_IMAGE_DIR)
        rm -rf $LB_IMAGE_DIR
    fi
fi

echo "$INFO Creating new stack..."
heatStackCreateHA $TOPOLOGY_NAME $HEAT_TEMPLATE_FOLDER/*.yml \
    $APP_IMAGE_ID $DB_IMAGE_ID $LB_IMAGE_ID \
    $EXTERNAL_NETWORK_NAME_1 $PROVIDER $IPV6
echo "$INFO Done. :)"
