#!/bin/bash
function info() { echo $'\e[1;32m'INFO:$'\e[0m' $1; }
function warn() { echo $'\e[1;33m'WARN:$'\e[0m' $1; }
function err() { echo $'\e[1;31m'ERR:$'\e[0m' $1; }
function debug() { echo $'\e[1;34m'DEBUG:$'\e[0m' $1; }

function print_help() {
    info "Script for cleaning OpenStack tenant's resources."
    warn "This is a destructive action. Please be careful to run this script."
    echo 'Usage:'
    echo "    $0 <cloud_name> <tenant_name>"
    echo 'Parameters:'
    echo '    <cloud_name>     : (required) OTT-PC2 | PLA-PC2'
    echo '    <tenant_name>    : (required) your Openstack tenant name'
    echo 'Examples:'
    echo "    $0 OTT-PC2 OTT.PC2.SV.VNFM.SBC.SANITY"
    echo "    $0 PLA-PC2 PLA.PC2.SV.VNFM.SBC.1"

    exit 0
}

function source_tenant {
    if [[ $# -ne 2 ]]; then exit 1; fi
    local l_cloud="$1"
    local l_tenant="$2"
    local l_authen_file=$HOME/.openstack/$l_cloud/$l_tenant-openrc.sh
    if [[ -f $l_authen_file ]]; then
        source $l_authen_file
    else
        echo "File not found. Using user input..."
        echo "Input username and press Enter:"
        read -r username
        echo "Input password (silent mode) and press Enter:"
        read -sr passwd
        echo "Input Keystone URL and press Enter: eg: http://172.29.49.201:5000/v3"
        read -r endpoint
        export OS_AUTH_URL=$endpoint
        export OS_PROJECT_NAME=$tenant
        export OS_USERNAME=$username
        export OS_PASSWORD=$passwd
        export OS_DOMAIN_NAME='Default'
        export OS_DOMAIN_ID='default'
    fi
}

function delete_stack () {
    echo '---------------------------------------------'
    echo "Delete stacks..."
    heat stack-list | grep -v id | grep -v "+---" | awk '{print$2}' | xargs -I % heat stack-delete %
    local delete_loop=1
    local delete_loop_counter=0
    while [ $delete_loop -eq 1 ]; do
        REMAINED=$(heat stack-list | grep -v id | grep -v "+---" | wc -l )
        if [ -z "$REMAINED" ] || [ "$REMAINED" == "0" ]; then
            info "No stack remained"
            delete_loop=0
        else
            info "Deleting $REMAINED stack\(s\)"
        fi
        delete_loop_counter=$((delete_loop_counter+1))
        if [ $delete_loop_counter -eq 5 ]; then
            delete_loop=0
            warn "Remained $REMAINED stack\(s\) cannot be deleted"
        fi
        sleep 10
    done
}

function delete_floating_ip () {
    echo '---------------------------------------------'
    echo 'Delete floating IPs...'
    neutron floatingip-list | grep -v id | grep -v "+---" | awk '{print$2}' | xargs -I % neutron floatingip-delete %
    local delete_loop=1
    local delete_loop_counter=0
    while [ $delete_loop -eq 1 ]; do
        REMAINED=$(neutron floatingip-list | grep -v id | grep -v "+---" | wc -l )
        if [ -z "$REMAINED" ] || [ "$REMAINED" == "0" ]; then
            info "No floating IP remained"
            delete_loop=0
        else
            info "Deleting $REMAINED floating IP\(s\)"
        fi
        delete_loop_counter=$((delete_loop_counter+1))
        if [ $delete_loop_counter -eq 6 ]; then
            delete_loop=0
            warn "Remained $REMAINED floating IP\(s\) cannot be deleted"
        fi
        sleep 10
    done
}

function delete_instance () {
    echo '---------------------------------------------'
    echo 'Delete instances...'
    nova list | grep -v ID | grep -v "+---" | awk '{print$2}' |  xargs -I % nova delete %
    local delete_loop=1
    local delete_loop_counter=0
    while [ $delete_loop -eq 1 ]; do
        REMAINED=$(nova list | grep -v ID | grep -v "+---" | wc -l )
        if [ -z "$REMAINED" ] || [ "$REMAINED" == "0" ]; then
            info "No instance remained"
            delete_loop=0
        else
            info "Deleting $REMAINED instance\(s\)"
        fi
        delete_loop_counter=$((delete_loop_counter+1))
        if [ $delete_loop_counter -eq 10 ]; then
            delete_loop=0
            warn "Remained $REMAINED instance\(s\) cannot be deleted"
        fi
        sleep 10
    done
}

function delete_volume () {
    echo '---------------------------------------------'
    echo 'Delete volume...'
    #cinder --os-volume-api-version 2 list
    openstack volume list | grep -v ID | grep -v "+---" | awk '{print$2}' | xargs -I % openstack volume delete %
    local delete_loop=1
    local delete_loop_counter=0
    while [ $delete_loop -eq 1 ]; do
        REMAINED=$(openstack volume list | grep -v ID | grep -v "+---" | wc -l )
        if [ -z "$REMAINED" ] || [ "$REMAINED" == "0" ]; then
            info "No volume remained"
            delete_loop=0
        else
            info "Deleting $REMAINED volume\(s\)"
        fi
        delete_loop_counter=$((delete_loop_counter+1))
        if [ $delete_loop_counter -eq 10 ]; then
            delete_loop=0
            warn "Remained $REMAINED volume\(s\) cannot be deleted"
        fi
        sleep 10
    done
}

function delete_port () {
    echo '---------------------------------------------'
    echo 'Delete ports...'
    neutron port-list | grep -v mac_address | grep -v "+---" | awk '{print$2}' | xargs -I % neutron port-update --device-owner none %
    neutron port-list | grep -v mac_address | grep -v "+---" | awk '{print$2}' | xargs -I % neutron port-delete %
    local delete_loop=1
    local delete_loop_counter=0
    while [ $delete_loop -eq 1 ]; do
        REMAINED=$(neutron port-list | grep -v mac_address | grep -v "+---" | wc -l )
        if [ -z "$REMAINED" ] || [ "$REMAINED" == "0" ]; then
            info "No port remained"
            delete_loop=0
        else
            info "Deleting $REMAINED port\(s\)"
        fi
        delete_loop_counter=$((delete_loop_counter+1))
        if [ $delete_loop_counter -eq 10 ]; then
            delete_loop=0
            warn "Remained $REMAINED port\(s\) cannot be deleted"
        fi
        sleep 10
    done
}

function delete_server_group () {
    echo '---------------------------------------------'
    echo 'Delete security groups...'
    neutron security-group-list -c id | grep -v id | grep -v "+---" | awk '{print$2}' | xargs -I % neutron security-group-delete %
    local delete_loop=1
    local delete_loop_counter=0
    while [ $delete_loop -eq 1 ]; do
        REMAINED=$(neutron security-group-list -c id | grep -v id | grep -v "+---" | wc -l )
        if [ -z "$REMAINED" ] || [ "$REMAINED" == "1" ]; then
            info "Only default security group remained"
            delete_loop=0
        else
            info "Deleting $REMAINED security group\(s\)"
        fi
        delete_loop_counter=$((delete_loop_counter+1))
        if [ $delete_loop_counter -eq 10 ]; then
            delete_loop=0
            warn "Remained $REMAINED security group\(s\) cannot be deleted"
        fi
        sleep 10
    done
}

function delete_sec_group () {
    echo '---------------------------------------------'
    echo 'Delete server groups...'
    nova server-group-list | grep -v Id | grep -v "+---" | awk '{print$2}' | xargs -I % nova server-group-delete %
    local delete_loop=1
    local delete_loop_counter=0
    while [ $delete_loop -eq 1 ]; do
        REMAINED=$(nova server-group-list | grep -v Id | grep -v "+---" | wc -l )
        if [ -z "$REMAINED" ] || [ "$REMAINED" == "0" ]; then
            info "No server group remained"
            delete_loop=0
        else
            info "Deleting $REMAINED server group\(s\)"
        fi
        delete_loop_counter=$((delete_loop_counter+1))
        if [ $delete_loop_counter -eq 10 ]; then
            delete_loop=0
            warn "Remained $REMAINED server group\(s\) cannot be deleted"
        fi
        sleep 10
    done
}

function delete_router () {
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
            info "No router remained"
            delete_loop=0
        else
            info "Deleting $REMAINED router\(s\)"
        fi
        delete_loop_counter=$((delete_loop_counter+1))
        if [ $delete_loop_counter -eq 6 ]; then
            delete_loop=0
            warn "Remained $REMAINED router\(s\) cannot be deleted"
        fi
        sleep 10
    done
}

function delete_subnet () {
    echo '---------------------------------------------'
    echo 'Delete subnets...'
    neutron subnet-list --shared=False | grep -v id | grep -v "+---" | awk '{print$2}' | xargs -I % neutron subnet-delete %
    local delete_loop=1
    local delete_loop_counter=0
    while [ $delete_loop -eq 1 ]; do
        REMAINED=$(neutron subnet-list --shared=False | grep -v id | grep -v "+---" | wc -l )
        if [ -z "$REMAINED" ] || [ "$REMAINED" == "0" ]; then
            info "No subnet remained"
            delete_loop=0
        else
            info "Deleting $REMAINED subnet\(s\)"
        fi
        delete_loop_counter=$((delete_loop_counter+1))
        if [ $delete_loop_counter -eq 6 ]; then
            delete_loop=0
            warn "Remained $REMAINED subnet\(s\) cannot be deleted"
        fi
        sleep 10
    done
}

function delete_network () {
    echo '---------------------------------------------'
    echo 'Delete networks...'
    neutron net-list --shared=False | grep -v id | grep -v "+---" | awk '{print$2}' | xargs -I % neutron net-delete %
    local delete_loop=1
    local delete_loop_counter=0
    while [ $delete_loop -eq 1 ]; do
        REMAINED=$(neutron net-list --shared=False | grep -v id | grep -v "+---" | wc -l )
        if [ -z "$REMAINED" ] || [ "$REMAINED" == "0" ]; then
            info "No network remained"
            delete_loop=0
        else
            info "Deleting $REMAINED network\(s\)"
        fi
        delete_loop_counter=$((delete_loop_counter+1))
        if [ $delete_loop_counter -eq 6 ]; then
            delete_loop=0
            warn "Remained $REMAINED network\(s\) cannot be deleted"
        fi
        sleep 10
    done
}

if [ -z "$1" ] || [ "$1" == "help" ] || [ "$1" == "--help" ]; then print_help; fi

echo '---------------------------------------------'
debug "Source tenant RC file..."
source_tenant $1 $2

delete_stack
delete_instance
delete_port
delete_server_group
delete_router
delete_subnet
delete_network
delete_sec_group
delete_floating_ip
delete_volume

echo '================================================='
info "Done.  It's now your tenant."
echo '================================================='
