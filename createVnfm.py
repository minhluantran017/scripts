#!/usr/bin/python
import argparse
import logging
import time
import sys
from prorietary.general_info import General
from lib.openstack.openstack import Utils

logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
                    level=logging.DEBUG)
logger = logging.getLogger(__name__)

def parseArgs():
    parser = argparse.ArgumentParser(
        usage='Create a HA/GR VNFM instance',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('-c', '--cloud',    type=str,   required=True,
                            help='The cloud to create VNFM',
                            choices=['OTT-PC2', 'PLA-PC2', 'WFD-PC2'])
    parser.add_argument('-t', '--tenant',   type=str,   required=True,
                            help='The tenant to create VNFM')
    parser.add_argument('-n', '--name',     type=str,   required=True,
                            help='The VNFM name you want to create')
    parser.add_argument('-u', '--user',     type=str,   required=False,
                            help='The tenant username',
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
    parser.add_argument('', '--prov',   type=bool, required=False,
                            help='Provider or floating network',
                            default=False)
    return parser.parse_args()

if __name__ == '__main__':
    args = parseArgs()
    logger.info("Creating VNFM {mode} with name '{name}' on tenant {tenant}..."
            .format(mode=args.mode, name=args.name, tenant=args.tenant))
    logger.info("Getting authentication with keystone URL {url}..."
            .format(url=General.cloud_endpoint[args.cloud]))    
    session = Utils.getAuthSession(url=General.cloud_endpoint[args.cloud],
                        tenant=args.tenant,
                        user=args.user, passwd=args.password, domain='Default')
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

    logger.info("Downloading Heat template...")
    heat_template = Utils.downloadHeatTemplate(topology=args.mode, product_release, build_number)

    logger.info("Checking image availability...")
    app_image_name = Utils.getImageName(image_type='app', product_release=product_release, build_number=build_number)
    
    logger.info("Checking image {0}".format(app_image_name))
    app_image_id=Utils.findImageOnCloud(session, app_image_name)
    if app_image_id == null :
        logger.error("Image is not available now. Please upload and try again!")
        exit 1

    db_image_name = Utils.getImageName(image_type='db', product_release=product_release, build_number=build_number)
    logger.info("Checking image {0}".format(db_image_name))
    db_image_id=Utils.findImageOnCloud(session, db_image_name)
    if db_image_id == null :
        logger.error("Image is not available now. Please upload and try again!")
        exit 1
    
    lb_image_name = Utils.getImageName(image_type='lb', product_release=product_release, build_number=build_number)
    logger.info("Checking image {0}".format(lb_image_name))
    lb_image_id=Utils.findImageOnCloud(session, lb_image_name)
    if lb_image_id == null :
        logger.error("Image is not available now. Please upload and try again!")
        exit 1

    if args.cloud == 'OTT-PC2':
        external_net='External OAM-V4'
    else:
        external_net='EXT_RTP_0_V4'

    pub_key=subprocess.Popen('cat {wp}/keypairs/openstack.pub'.format(wp=Utils.WORKSPACE), stdout=subprocess.PIPE, shell=True).communicate()[0].decode("utf-8")
    
    logger.info("Creating stack...")
    parameters={
        "availability_zone": "general",
        "app_image_id": app_image_id,
        "db_image_id": db_image_id,
        "lb_image_id": lb_image_id,
        "ipv4_floating_network": not(args.prov),
        "ipv4_provider_network": args.prov,
        "ipv6_provider_network": "false",
        "public_net_v4" external_net,
        "public_net_v4_subnet_id" : "1111",
        "public_net_v6": external_net,
        "public_net_v6_subnet_id": "1111",
        "vnfm_public_key": pub_key,
        "dns_servers=": ["10.2.1.2"]
    }
    stack_id=Utils.createStack(session, args.name, heat_template, parameters)
    