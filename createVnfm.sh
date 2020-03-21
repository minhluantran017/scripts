#!/bin/bash
WORKSPACE=`dirname $0`
source $WORKSPACE/proprietary/general_info.sh
source $WORKSPACE/lib/common/utils.sh
source $WORKSPACE/lib/openstack/openstack.sh

echo "$INFO $(date)"

if [ -z "$1" ] || [ "$1" == "help" ]; then
    echo 'Script for setting up a VNFM HA.'
    echo 'Usage:'
    echo "    $0 <cloud_name> <tenant_name> <stack_name> <network_type>"
    echo 'Parameters:'
    echo '    <cloud_name>     : (required) OTT-PC2 | PLA-PC2 | WFD-PC2'
    echo '    <tenant_name>    : (required) your Openstack tenant name'
    echo '    <stack_name>     : (required) your stack name. Only use characters, digits, and _ or -'
    echo '    <network_type>   : (optional) floating | provider. Default to floating'
    echo 'Examples:'
    echo "    $0 OTT-PC2 OTT.PC2.SV.VNFM.SANITY VNFM-Test-1 floating"
    echo "    $0 PLA-PC2 PLA.PC2.SV.VNFM.HA VNFM-Test-2 provider"
    echo "    $0 WFD-PC2 WFD.PC2.VNFM.JENKINS VNFM-Test-3 provider"
    exit 128
fi

echo "$INFO Setting environments..."
CLOUD="$1"
TENANT="$2"
PROVIDER="$4"
ZONE="general"
PRODUCT_RELEASE="mainline"

if [ -z "$3" ]; then
    TOPOLOGY_NAME="VNFM_HA_AUTO"
else
    TOPOLOGY_NAME="$3"
fi

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
