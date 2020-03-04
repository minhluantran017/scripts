#!/usr/bin/python

import argparse
import logging
import time
import sys
from lib.openstack.keystone import Keystone
from lib.openstack.heat import Heat
from lib.openstack.glance import Glance
from lib.openstack.neutron import Neutron
from lib.openstack.nova import Nova
from lib.common.utils import *

logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
                    level=logging.DEBUG)
logger = logging.getLogger(__name__)

def parseArgs():
    parser = argparse.ArgumentParser(
        usage='Create a HA/GR VNFM instance',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('-c', '--cloud',    type=str,   required=True,
                            help='The cloud to create VNFM')
    parser.add_argument('-t', '--tenant',   type=str,   required=True,
                            help='The tenant to create VNFM')
    parser.add_argument('-n', '--name',     type=str,   required=False,
                            help='The VNFM name you want to create',
                            default='VNFM_'+ time.strftime("%Y-%m-%d-%H-%M-%S"))
    parser.add_argument('-u', '--user',     type=str,   required=False,
                            help='The tenant user name',
                            default='vnfmsv')
    parser.add_argument('-p', '--password', type=str,   required=False,
                            help='The tenant password',
                            default='rbbn')
    parser.add_argument('-d', '--domain', type=str,   required=False,
                            help='The tenant domain',
                            default='Default')
    parser.add_argument('-k', '--keypair', type=str,   required=False,
                            help='The public key to put into the VNFM',
                            default='Auto')
    parser.add_argument('-r', '--release', type=str,   required=False,
                            help='''The release if you do not want
                            to use mainline''',
                            default='')
    parser.add_argument('-b', '--build', type=str,   required=False,
                            help='''The build number if you do not want
                            to use the lastSuccessfulBuild''',
                            default='')
    parser.add_argument('-m', '--mode',     type=str,   required=False,    
                            help='Create HA/GR VNFM',
                            choices=['HA', 'GR'],
                            default='HA')
    return parser.parse_args()
if __name__ == '__main__':
    args = parseArgs()
    logger.info("Creating VNFM {mode} with name '{name}' on tenant {tenant}..."
            .format(mode=args.mode, name=args.name, tenant=args.tenant))
    logger.info("Getting authentication with keystone URL {url}..."
            .format(url=Utils.apiEndpoints[args.cloud]["keystone"]))

    keystone=Keystone(ks_url=Utils.apiEndpoints[args.cloud]["keystone"], 
                        tenant=args.tenant, username=args.user, password=args.password, domain=args.domain)
    token=keystone.getToken()

    logger.info("Getting build info...")
    if args.release == '':
        product_release = 'mainline'
    else :
        product_release = args.release

    if args.build == '':
        build_number = Utils.getLastSuccesfulBuild(product_release)
    else :
        build_number = args.build
    logger.info("Build number: {0}".format(build_number))

    logger.info("Checking image availability...")
    app_image_name = Utils.getImageName(image_type='app', product_release=product_release, build_number=build_number)
    logger.info("Checking image {0}".format(app_image_name))
    glance=Glance(gl_url=Utils.apiEndpoints[args.cloud]["glance"],auth_token=token)
    print(glance.findImage("sbc-V08.01.00A011-connexip-os_07.01.01-A011_351_amd64.qcow2"))
    #glance.listImage()
