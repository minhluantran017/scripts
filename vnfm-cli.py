#!/usr/bin/python3
import argparse
import logging
import time
import sys
import subprocess
import os
import configparser

from keystoneauth1 import loading
from keystoneauth1 import session
from heatclient import client as Heat
from novaclient import client as Nova
from glanceclient import client as Glance
from heatclient.common import template_utils

WORKSPACE = os.path.dirname(__file__)

def parseArgs():
    parser = argparse.ArgumentParser(
        usage='vnfm-cli',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    
    parser.add_argument('-u', '--user',     type=str,   required=False,
                            help='The tenant username',
                            default='vnfmsv')
    parser.add_argument('-p', '--password', type=str,   required=False,
                            help='The tenant password',
                            default='rbbn')
    
    subparsers = parser.add_subparsers(help='sub-command', dest='subcommand')

    parser_create = subparsers.add_parser('create', help='Create a VNFM')

    parser_delete = subparsers.add_parser('delete', help='Delete a VNFM')

    parser_create.add_argument('-c', '--cloud',    type=str,   required=True,
                            help='The cloud to create VNFM')
    parser_create.add_argument('-t', '--tenant',   type=str,   required=True,
                            help='The tenant to create VNFM')
    parser_create.add_argument('-n', '--name',     type=str,   required=True,
                            help='The VNFM name you want to create')
    parser_create.add_argument('-d', '--domain', type=str,   required=False,
                            help='The tenant domain',
                            default='Default')
    parser_create.add_argument('-k', '--keypair', type=str,   required=False,
                            help='The public key to put into the VNFM',
                            default='Auto')
    parser_create.add_argument('-r', '--release', type=str,   required=False,
                            help='''The release if you do not want
                            to use mainline''',
                            default='')
    parser_create.add_argument('-b', '--build', type=str,   required=False,
                            help='''The build number if you do not want
                            to use the lastSuccessfulBuild''',
                            default='')
    parser_create.add_argument('-m', '--mode',     type=str,   required=False,    
                            help='Create HA/GR VNFM',
                            choices=['HA', 'GR'],
                            default='HA')
    parser_create.add_argument('', '--prov',   type=bool, required=False,
                            help='Provider or floating network',
                            default=False)

    parser_delete.add_argument('-c', '--cloud',    type=str,   required=True,
                            help='The cloud to delete VNFM')
    parser_delete.add_argument('-t', '--tenant',   type=str,   required=True,
                            help='The tenant to delete VNFM')
    parser_delete.add_argument('-n', '--name',     type=str,   required=True,
                            help='The VNFM name you want to delete')
    parser_delete.add_argument('', '--clean-volume',   type=bool, required=False,
                            help='Cleanup Cinder volume after deletion',
                            default=True)
    return parser.parse_args()

def get_config(config_name):
    """
        Get configurations from config file
        Parameters
        ----------
        config_name : str
            The name of config in format `section.config`

        Returns
        ----------
        config_value : str
            Value of the required config
    """
    config_file = '{}/.vnfm/config'.format(os.environ['HOME'])
    if not os.path.exists(config_file):
        logger.error("Cannot found the config file {}. Exitting...".format(config_file))
        exit(1)
    config_session = config_name.split('.')[0]
    config_key  = config_name.split('.')[1]
    vnfm_config = configparser.ConfigParser()
    vnfm_config.read(config_file)
    return vnfm_config[config_session][config_key]


def get_last_succesful_build(product_release='mainline'):
    """
        Get VNFM last successful build number from Artifactory
        Parameters
        ----------
        product_release: str
            Product release. Default is 'mainline'

        Returns
        ----------
        build_number : str
            Build number in format 'Build-xxxx'
    """
    url = get_config('general.VNFM_ARTIFACTORY_URL')
    pattern=get_config('general.HA_HEAT_TEMPLATE_PATTERN')
    cmd='''curl -sS "{0}/{1}/Artifacts/lastSuccessfulBuild/heatTemplates/" | grep -E \'href="([^"#]+)"\' |\\
      cut \'-d"\' -f2 | grep {2} | awk -F\'_\' \'{{ print $5}}\' | awk -F\'-\' \'{{print $2}}\' | awk -F\'.\' \'{{print $1}}\'
    '''.format(url, product_release, pattern)
    build_number = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True).communicate()[0].decode("utf-8")
    return 'Build-{0}'.format(build_number)

def get_image_name(image_type, product_release='mainline', build_number):
    """
        Get VNFM image name from Artifactory
        Parameters
        ----------
        image_type : str
            VNFM image type: 'app' or 'lb' or 'db'
        product_release: str
            Product release. Default is 'mainline'
        build_number: str
            VNFM build number to get

        Returns
        ----------
        path : str
            Name of the VNFM image
    """
    url = get_config('general.VNFM_ARTIFACTORY_URL')
    cmd='curl -sS "{0}/{1}/Artifacts/{2}/" | grep -E \'href="([^"#]+)"\' |  cut \'-d"\' -f2 | grep {3})'
        .format(url, product_release, build_number, image_type)
    image_name = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True).communicate()[0].decode("utf-8")
    return image_name

def download_heat_template(topology='HA', product_release='mainline', build_number):
    """
        Download VNFM Heat template to local machine
        Parameters
        ----------
        topology : str
            VNFM topology: HA or GR. Default is 'HA'
        product_release: str
            Product release. Default is 'mainline'
        build_number: str
            VNFM build number to get

        Returns
        ----------
        path : str
            Path of the downloaded template
    """
    url = get_config('general.VNFM_ARTIFACTORY_URL')
    pattern=get_config('general.'+ topology +'_HEAT_TEMPLATE_PATTERN')
    cmd='curl -sS -o {0}/tmp/{1}/{2}.yaml "{3}/{4}/Artifacts/{5}/heatTemplates/{6}*.yaml"'
        .format(WORKSPACE, build_number, url, product_release, pattern)
    subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True).communicate()

    return '{0}/tmp/{1}/{2}.yaml'.format(WORKSPACE, build_number, pattern)

def get_auth_session(url, tenant, user, passwd, domain='Default'):
    """
        Get authentication session from Openstack
        Parameters
        ----------
        url : str
            The Identity service (Keystone) URL
        tenant : str
            The OpenStack tenant
        user : str
            The OpenStack tenant username
        passwd : str
            The OpenStack tenant password
        domain : str
            The OpenStack tenant domain

        Returns
        ----------
        session : str
            The session
    """
    loader = loading.get_plugin_loader('password')
    auth = loader.load_from_options(auth_url=url, project_name=tenant
                                    username=user,password=passwd,
                                    project_domain_name=domain,
                                    user_domain_name=domain)
    return session.Session(auth=auth)

def find_image_on_cloud(auth_session, image_name):
    """
        Find Glance image on OpenStack
        Parameters
        ----------
        name : str
            The name of the image

        Returns
        ----------
        id : str
            ID of the image or 'null' if image does not exist or active
    """
    image_list = Glance.Client('2', auth_session).images.list()
    image_list = json.loads(image_list)
    for image in image_list["images"]:
        if image["name"] == image_name:
            if image['status'] == 'active':
                return image['id']
    return null  

def create_stack(auth_session, stack_name, heat_template, parameters=None):
    """
        Create a stack
        Parameters
        ----------
        name : str
            The name of the stack
        heat_template : str
            The Heat Orchestration Template for creating stack
        parameters : dict
            The parameters for the stack in json format (dict)

        Returns
        ----------
        stack_id : str
            ID of the created stack
    """
    heat = Heat.Client('1', session=auth_session)
    # Load the template
    _files, template = template_get_template_contents(heat_template)
    # Searlize it into a stream
    s_template = yaml.safe_dump(template)
    heat.stacks.create(stack_name=stack_name, template = s_template,parameters=parameters)
    return stacks.get(stack_name).id

def delete_stack(auth_session, stack_id):
    """
        Delete a stack
        Parameters
        ----------
        name : str
            The name of the stack

        Returns
        ----------
        exit_code : int
            returns 0 if success
    """
    heat = Heat.Client('1', session=auth_session)
    heat.stacks.delete(stack_id)
    return 0

def create_vnfm():
    logger.info("Creating VNFM {0} '{1}' on tenant {2}..."
            .format(args.mode, args.name, args.tenant))
    keystone_url = get_config('cloud.' + args.cloud)
    logger.info("Getting authentication with keystone URL {0}...".format(keystone_url)
    session = get_auth_session(url=keystone_url, tenant=args.tenant,
                        user=args.user, passwd=args.password, domain='Default')

    logger.info("Getting build info...")
    product_release = 'mainline' if args.release == '' else args.release
    build_number = get_last_succesful_build(product_release) if args.build == '' else args.build
    logger.info("Build number: {0}".format(build_number))

    logger.info("Downloading Heat template...")
    heat_template = download_heat_template(topology=args.mode, product_release, build_number)

    logger.info("Checking image availability...")
    for index in ['app', 'db', 'lb']:
        image_name = get_image_name(image_type=index, product_release=product_release, build_number=build_number)
        
        logger.info("Checking image {0}".format(image_name))
        image_id=find_image_on_cloud(session, image_name)
        if image_id == null :
            logger.error("Image is not available now. Please upload and try again!")
            exit()

    logger.info("Getting network information...")
    external_net='EXT_RTP_0_V4'

    pub_key=subprocess.Popen('cat {0}/keypairs/openstack.pub'.format(WORKSPACE), stdout=subprocess.PIPE, shell=True)
        .communicate()[0].decode("utf-8")
    
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
    stack_id=create_stack(session, args.name, heat_template, parameters)

if __name__ == '__main__':
    args = parse_args()
    logging.basicConfig(format='%(asctime)s - %(levelname)s - %(message)s',
                    level=logging.DEBUG)
    logger = logging.getLogger(__name__)

    if args.subcommand == 'create':
        create_vnfm()
    elif args.subcommand == 'delete':
        delete_vnfm()
