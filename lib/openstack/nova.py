import argparse
import logging
import time
import requests
import json
logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
                    level=logging.DEBUG)
logger = logging.getLogger(__name__)

class Nova (object):
    def __init__(self, nova_endpoint):
        print(a)
