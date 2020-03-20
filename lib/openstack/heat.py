import argparse
import logging
import time
import requests
import json
logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
                    level=logging.DEBUG)
logger = logging.getLogger(__name__)
class Heat(object):
    def __init__(self,heat_url,auth_token):
        self.url=heat_url
        self.auth_token=auth_token
    def create_stack(self, tenant_id, stack_name, heat_template, parameters=None):
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
        url = "{url}/v1/{tenant_id}/stacks".format(url=self.url, tenant_id=tenant_id)

        payload="{{\"files\":{{}},\"disable_rollback\":true,\"parameters\":\"{parameter}\",\"stack_name\":\"{name}\",\"template_url\":\"{template}\",\"timeout_mins\":60}}".format(parameter=parameters, name=stack_name, template=heat_template)

        headers = {
            'X-Auth-Token': "{token}".format(token=self.auth_token),
            'Accept': "application/json"
            }

        response = requests.request("POST", url, data=payload, headers=headers)
        return response.text["stack"]["id"]

    def delete_stack(self, tenant_id, stack_name, stack_id):
        """
        DELETE /v1/{tenant_id}/stacks/{stack_name}/{stack_id}
        """
        return 0

    def list_stacks(self):
        return 0
