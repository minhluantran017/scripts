import argparse
import logging
import time

logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
                    level=logging.DEBUG)
logger = logging.getLogger(__name__)
class Heat(object):
    def __init__(self, heat_endpoint, auth_token):
        self.heatclient = Heat_Client('1', endpoint=heat_endpoint, token=auth_token)
    def create_stack(self, stack_file_path, stack_name, parameters=None):
        return 0

    def delete_stack(self, stack_id):
        return 0

    def list_stacks(self):
        return 0
