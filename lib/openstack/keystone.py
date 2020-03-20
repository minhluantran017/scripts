import argparse
import logging
import time
import requests
import json
logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
                    level=logging.DEBUG)
logger = logging.getLogger(__name__)
class Keystone(object):
    def __init__(self, ks_url, tenant, username, password, domain):
        self.url=ks_url
        self.tenant=tenant
        self.username=username
        self.password=password
        self.domain=domain
        self.tenantId=''
    def getToken(self):
        payload = "{{\"auth\": {{\"identity\": {{\"methods\": [\"password\"],\"password\": {{\"user\": {{\"name\": \"{user}\",\"domain\": {{\"name\": \"{domain}\"}},\"password\": \"{passwd}\"}}}}}},\"scope\": {{\"project\": {{\"name\": \"{tenant}\",\"domain\": {{\"name\": \"{domain}\"}}}}}}}}}}".format(user=self.username, passwd=self.password, tenant=self.tenant, domain=self.domain)
        headers = {
            'Content-Type': 'application/json'
        }
        url='{url}/v3/auth/tokens'.format(url=self.url)
        response = requests.request("POST", url, data=payload, headers=headers)
        return response.headers["X-Subject-Token"]
