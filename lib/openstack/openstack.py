import subprocess
import os
import logging
import time
import yaml

from propietary.general_info import General

from keystoneauth1 import loading
from keystoneauth1 import session
from heatclient import client as Heat
from novaclient import client as Nova
from glanceclient import client as Glance
from heatclient.common import template_utils

WORKSPACE = os.path.dirname(__file__)[:-11]
logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
                    level=logging.DEBUG)
logger = logging.getLogger(__name__)
class Utils:

    def getLastSuccesfulBuild(product_release='mainline'):
        cmd='curl -sS "{url}/{rel}/Artifacts/lastSuccessfulBuild/heatTemplates/" | grep -E \'href="([^"#]+)"\' |  cut \'-d"\' -f2 | grep {pattern} | awk -F\'_\' \'{{ print $5}}\' | awk -F\'-\' \'{{print $2}}\' | awk -F\'.\' \'{{print $1}}\''.format(url=General.VNFM_ARTIFACTORY_URL, rel=product_release, pattern=General.HA_HEAT_TEMPLATE_PATTERN)
        build_number = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True).communicate()[0].decode("utf-8")
        return 'Build-{0}'.format(build_number)
    
    def getImageName(image_type, product_release='mainline', build_number):
        cmd='curl -sS "{url}/{rel}/Artifacts/{build}/" | grep -E \'href="([^"#]+)"\' |  cut \'-d"\' -f2 | grep {type})'.format(url=General.VNFM_ARTIFACTORY_URL, rel=product_release, build=build_number, type=image_type)
        image_name = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True).communicate()[0].decode("utf-8")
        return image_name

    def downloadHeatTemplate(topology='HA', product_release='mainline', build_number):
        if topology == 'HA':
            cmd='curl -sS -o {wp}/tmp/{build}/{pattern}.yaml "{url}/{rel}/Artifacts/{build}/heatTemplates/{pattern}*.yaml"'.format( wp=WORKSPACE, build=build_number,url=General.VNFM_ARTIFACTORY_URL, rel=product_release, pattern=General.HA_HEAT_TEMPLATE_PATTERN)
            subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True).communicate()
        else:
            cmd='curl -sS -o {wp}/tmp/{build}/{pattern}.yaml "{url}/{rel}/Artifacts/{build}/heatTemplates/{pattern}*.yaml"'.format( wp=WORKSPACE, build=build_number,url=General.VNFM_ARTIFACTORY_URL, rel=product_release, pattern=General.GR_HEAT_TEMPLATE_PATTERN)
            subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True).communicate()

    def getAuthSession(url, tenant, user, passwd, domain='Default'):
        loader = loading.get_plugin_loader('password')
        auth = loader.load_from_options(auth_url=url, project_name=tenant
                                        username=user,password=passwd,
                                        project_domain_name=domain,
                                        user_domain_name=domain)
        return session.Session(auth=auth)

    def findImageOnCloud(auth_session, image_name):
        image_list = Glance.Client('2', auth_session).images.list()
        image_list = json.loads(image_list)
        for image in image_list["images"]:
            if image["name"] == image_name:
                if image['status'] == 'active':
                    return image['id']
        return null  

    def createStack(auth_session, stack_name, heat_template, parameters=None):
        """
        Create a stack
        Parameters
        ----------
        name : str
            The name of the stack
        tenant_id : str
            The tenant (project) ID
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
        _files, template = template_utils.get_template_contents(heat_template)
        # Searlize it into a stream
        s_template = yaml.safe_dump(template)
        heat.stacks.create(stack_name=stack_name, template = s_template,parameters=parameters)
        return stacks.get(stack_name).id

    def deleteStack(auth_session, stack_id):
        """
        """
        heat = Heat.Client('1', session=auth_session)
        heat.stacks.delete(stack_id)
        return 0
