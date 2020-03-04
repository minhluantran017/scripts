import argparse
import logging
import time
import requests

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
        payload = "{{\r\n    \"auth\": {{\r\n        \"identity\": {{\r\n            \"methods\": [\r\n                \"password\"\r\n            ],\r\n            \"password\": {{\r\n                \"user\": {{\r\n                    \"name\": \"{user}\",\r\n                    \"domain\": {{\r\n                    \t\"name\": \"{domain}\"\r\n                    }}, \r\n                    \"password\": \"{passwd}\"\r\n                }}\r\n            }}\r\n        }},\r\n        \"scope\": {{\r\n            \"project\": {{\r\n                \"name\": \"{tenant}\",\r\n                \"domain\": {{\r\n                    \t\"name\": \"{domain}\"\r\n                    }}\r\n            }}\r\n        }}\r\n    }}\r\n}}".format(user=self.username, passwd=self.password, tenant=self.tenant, domain=self.domain)
        headers = {
            'Content-Type': 'application/json'
        }
        url='{url}/v3/auth/tokens'.format(url=self.url)
        response = requests.request("POST", url, data=payload, headers=headers)
        return response.headers["X-Subject-Token"]
