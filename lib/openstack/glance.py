import argparse
import logging
import time
import requests
import json
logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
                    level=logging.DEBUG)
logger = logging.getLogger(__name__)

class Glance(object):
    def __init__(self,glance_url,auth_token):
        self.url=glance_url
        self.auth_token=auth_token

    def findImage(self, image_name):
        image_list = self.listImage()
        image_list = json.loads(image_list)
        for image in image_list["images"]:
            if image["name"] == image_name:
                if image['status'] == 'active':
                    return image['id']
        return null
    def listImage(self):
        url = "{url}/v2/images".format(url=self.url)
        headers = {
            'X-Auth-Token': "{token}".format(token=self.auth_token),
            'Accept': "application/json"
            }
        response = requests.request("GET", url, headers=headers)
        return response.text