#!/bin/bash
WORKSPACE=`dirname $0`
source $WORKSPACE/proprietary/general_info.sh
source $WORKSPACE/lib/common/utils.sh
source $WORKSPACE/lib/openstack/openstack.sh

echo "$DEBUG $(date)"

if [ -z "$1" ] || [ "$1" == "help" ]
then
    echo "Script for cleaning tenant's resources."
    echo "$WARNING This is a destructive action. Please be careful to run this script."
    echo 'Usage:'
    echo "    $0 <cloud_name> <tenant_name>"
    echo 'Parameters:'
    echo '    <cloud_name>     : (required) OTT-PC2 | PLA-PC2'
    echo '    <tenant_name>    : (required) your Openstack tenant name'
    echo 'Examples:'
    echo "    $0 OTT-PC2 OTT.PC2.SV.VNFM.SBC.SANITY"
    echo "    $0 PLA-PC2 PLA.PC2.SV.VNFM.SBC.1"

    exit 128
fi

CLOUD="$1"
TENANT="$2"
echo '---------------------------------------------'
echo "$DEBUG Source tenant RC file..."
sourceTenant $CLOUD $TENANT

deleteStack () {
echo '---------------------------------------------'
echo "$DEBUG Delete stacks..."
heat stack-list | grep -v id | grep -v "+---" | awk '{print$2}' | xargs -I % heat stack-delete %
local delete_loop=1
local delete_loop_counter=0
while [ $delete_loop -eq 1 ]; do
    REMAINED=$(heat stack-list | grep -v id | grep -v "+---" | wc -l )
    if [ -z "$REMAINED" ] || [ "$REMAINED" == "0" ]; then
        echo "$INFO No stack remained"
        delete_loop=0
    else
        echo "$INFO Deleting $REMAINED stack\(s\)"
    fi
    delete_loop_counter=$((delete_loop_counter+1))
    if [ $delete_loop_counter -eq 5 ]; then
        delete_loop=0
        echo "$WARNING Remained $REMAINED stack\(s\) cannot be deleted"
    fi
    sleep 10
done
}

deleteFloatingIP () {
echo '---------------------------------------------'
echo 'Delete floating IPs...'
neutron floatingip-list | grep -v id | grep -v "+---" | awk '{print$2}' | xargs -I % neutron floatingip-delete %
local delete_loop=1
local delete_loop_counter=0
while [ $delete_loop -eq 1 ]; do
    REMAINED=$(neutron floatingip-list | grep -v id | grep -v "+---" | wc -l )
    if [ -z "$REMAINED" ] || [ "$REMAINED" == "0" ]; then
        echo "$INFO No floating IP remained"
        delete_loop=0
    else
        echo "$INFO Deleting $REMAINED floating IP\(s\)"
    fi
    delete_loop_counter=$((delete_loop_counter+1))
    if [ $delete_loop_counter -eq 6 ]; then
        delete_loop=0
        echo "$WARNING Remained $REMAINED floating IP\(s\) cannot be deleted"
    fi
    sleep 10
done
}

deleteInstance () {
echo '---------------------------------------------'
echo 'Delete instances...'
nova list | grep -v ID | grep -v "+---" | awk '{print$2}' |  xargs -I % nova delete %
local delete_loop=1
local delete_loop_counter=0
while [ $delete_loop -eq 1 ]; do
    REMAINED=$(nova list | grep -v ID | grep -v "+---" | wc -l )
    if [ -z "$REMAINED" ] || [ "$REMAINED" == "0" ]; then
        echo "$INFO No instance remained"
        delete_loop=0
    else
        echo "$INFO Deleting $REMAINED instance\(s\)"
    fi
    delete_loop_counter=$((delete_loop_counter+1))
    if [ $delete_loop_counter -eq 10 ]; then
        delete_loop=0
        echo "$WARNING Remained $REMAINED instance\(s\) cannot be deleted"
    fi
    sleep 10
done
}

deleteVolume () {
echo '---------------------------------------------'
echo 'Delete volume...'
#cinder --os-volume-api-version 2 list
openstack volume list | grep -v ID | grep -v "+---" | awk '{print$2}' | xargs -I % openstack volume delete %
local delete_loop=1
local delete_loop_counter=0
while [ $delete_loop -eq 1 ]; do
    REMAINED=$(openstack volume list | grep -v ID | grep -v "+---" | wc -l )
    if [ -z "$REMAINED" ] || [ "$REMAINED" == "0" ]; then
        echo "$INFO No volume remained"
        delete_loop=0
    else
        echo "$INFO Deleting $REMAINED volume\(s\)"
    fi
    delete_loop_counter=$((delete_loop_counter+1))
    if [ $delete_loop_counter -eq 10 ]; then
        delete_loop=0
        echo "$WARNING Remained $REMAINED volume\(s\) cannot be deleted"
    fi
    sleep 10
done
}

deletePort () {
echo '---------------------------------------------'
echo 'Delete ports...'
neutron port-list | grep -v mac_address | grep -v "+---" | awk '{print$2}' | xargs -I % neutron port-update --device-owner none %
neutron port-list | grep -v mac_address | grep -v "+---" | awk '{print$2}' | xargs -I % neutron port-delete %
local delete_loop=1
local delete_loop_counter=0
while [ $delete_loop -eq 1 ]; do
    REMAINED=$(neutron port-list | grep -v mac_address | grep -v "+---" | wc -l )
    if [ -z "$REMAINED" ] || [ "$REMAINED" == "0" ]; then
        echo "$INFO No port remained"
        delete_loop=0
    else
        echo "$INFO Deleting $REMAINED port\(s\)"
    fi
    delete_loop_counter=$((delete_loop_counter+1))
    if [ $delete_loop_counter -eq 10 ]; then
        delete_loop=0
        echo "$WARNING Remained $REMAINED port\(s\) cannot be deleted"
    fi
    sleep 10
done
}

deleteSecGroup () {
echo '---------------------------------------------'
echo 'Delete security groups...'
neutron security-group-list -c id | grep -v id | grep -v "+---" | awk '{print$2}' | xargs -I % neutron security-group-delete %
local delete_loop=1
local delete_loop_counter=0
while [ $delete_loop -eq 1 ]; do
    REMAINED=$(neutron security-group-list -c id | grep -v id | grep -v "+---" | wc -l )
    if [ -z "$REMAINED" ] || [ "$REMAINED" == "1" ]; then
        echo "$INFO Only default security group remained"
        delete_loop=0
    else
        echo "$INFO Deleting $REMAINED security group\(s\)"
    fi
    delete_loop_counter=$((delete_loop_counter+1))
    if [ $delete_loop_counter -eq 10 ]; then
        delete_loop=0
        echo "$WARNING Remained $REMAINED security group\(s\) cannot be deleted"
    fi
    sleep 10
done
}

deleteServerGroup () {
echo '---------------------------------------------'
echo 'Delete server groups...'
nova server-group-list | grep -v Id | grep -v "+---" | awk '{print$2}' | xargs -I % nova server-group-delete %
local delete_loop=1
local delete_loop_counter=0
while [ $delete_loop -eq 1 ]; do
    REMAINED=$(nova server-group-list | grep -v Id | grep -v "+---" | wc -l )
    if [ -z "$REMAINED" ] || [ "$REMAINED" == "0" ]; then
        echo "$INFO No server group remained"
        delete_loop=0
    else
        echo "$INFO Deleting $REMAINED server group\(s\)"
    fi
    delete_loop_counter=$((delete_loop_counter+1))
    if [ $delete_loop_counter -eq 10 ]; then
        delete_loop=0
        echo "$WARNING Remained $REMAINED server group\(s\) cannot be deleted"
    fi
    sleep 10
done
}

deleteRouter () {
echo '---------------------------------------------'
echo 'Delete routers...'
#remove Subnet interface from Router
neutron router-list | grep -v external_gateway_info | grep -v "+---" | awk '{print$2}' | xargs -I % neutron router-gateway-clear %
neutron router-list | grep -v external_gateway_info | grep -v "+---" | awk '{print$2}' | xargs -I % neutron router-delete %
local delete_loop=1
local delete_loop_counter=0
while [ $delete_loop -eq 1 ]; do
    REMAINED=$(neutron router-list | grep -v external_gateway_info | grep -v "+---" | wc -l )
    if [ -z "$REMAINED" ] || [ "$REMAINED" == "0" ]; then
        echo "$INFO No router remained"
        delete_loop=0
    else
        echo "$INFO Deleting $REMAINED router\(s\)"
    fi
    delete_loop_counter=$((delete_loop_counter+1))
    if [ $delete_loop_counter -eq 6 ]; then
        delete_loop=0
        echo "$WARNING Remained $REMAINED router\(s\) cannot be deleted"
    fi
    sleep 10
done
}

deleteSubnet () {
echo '---------------------------------------------'
echo 'Delete subnets...'
neutron subnet-list --shared=False | grep -v id | grep -v "+---" | awk '{print$2}' | xargs -I % neutron subnet-delete %
local delete_loop=1
local delete_loop_counter=0
while [ $delete_loop -eq 1 ]; do
    REMAINED=$(neutron subnet-list --shared=False | grep -v id | grep -v "+---" | wc -l )
    if [ -z "$REMAINED" ] || [ "$REMAINED" == "0" ]; then
        echo "$INFO No subnet remained"
        delete_loop=0
    else
        echo "$INFO Deleting $REMAINED subnet\(s\)"
    fi
    delete_loop_counter=$((delete_loop_counter+1))
    if [ $delete_loop_counter -eq 6 ]; then
        delete_loop=0
        echo "$WARNING Remained $REMAINED subnet\(s\) cannot be deleted"
    fi
    sleep 10
done
}

deleteNetwork () {
echo '---------------------------------------------'
echo 'Delete networks...'
neutron net-list --shared=False | grep -v id | grep -v "+---" | awk '{print$2}' | xargs -I % neutron net-delete %
local delete_loop=1
local delete_loop_counter=0
while [ $delete_loop -eq 1 ]; do
    REMAINED=$(neutron net-list --shared=False | grep -v id | grep -v "+---" | wc -l )
    if [ -z "$REMAINED" ] || [ "$REMAINED" == "0" ]; then
        echo "$INFO No network remained"
        delete_loop=0
    else
        echo "$INFO Deleting $REMAINED network\(s\)"
    fi
    delete_loop_counter=$((delete_loop_counter+1))
    if [ $delete_loop_counter -eq 6 ]; then
        delete_loop=0
        echo "$WARNING Remained $REMAINED network\(s\) cannot be deleted"
    fi
    sleep 10
done
}

deleteStack
deleteInstance
deletePort
deleteServerGroup
deleteRouter
deleteSubnet
deleteNetwork
deleteSecGroup
deleteFloatingIP
deleteVolume

echo '================================================='
echo "$INFO Done.  It's now your tenant."
echo '================================================='
