#!/usr/bin/env python3

import argparse
import logging
import time
import sys
import urllib3
import os
import configparser
from os import path

def parse_args():
    parser = argparse.ArgumentParser(
        usage='jenkins-cli',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument('--url', type=str,   required=False,
                            help='The Jenkins master URL')
    parser.add_argument('-u', '--user', type=str,   required=False,
                            help='Your Jenkins username')
    parser.add_argument('-p', '--password', type=str,   required=False,
                            help='Your Jenkins password or API token')
    parser.add_argument('-profile', type=str,   required=False,
                            help='The Jenkins profile name in Jenkins config file')

    subparsers = parser.add_subparsers(help='sub-command', dest='subcommand')

    parser_validate = subparsers.add_parser('validate', help='Validate a jenkinsfile')

    parser_validate.add_argument('-f', '--file',    type=str,   required=True,
                            help='The Jenkinsfile to validate')
    

    parser_build = subparsers.add_parser('build', help='Build a Jenkins job')

    parser_build.add_argument('-j', '--job',    type=str,   required=True,
                            help='The Jenkins job to build')

    parser_build.add_argument('-p', '--parameters',    type=str,   required=False,
                            help='The Jenkins job parameters to build')

    return parser.parse_args()

def get_jenkins_cred():
    logger.info("Getting Jenkins credentials...")
    if (args.url != None) :
        logger.info("Using direct parameters...")
        jenkins_cred = [args.url, args.user, args.password]
    elif path.exists("{}/.jenkins/config".format(os.environ.get('HOME'))):
        logger.info("Using config file (~/.jenkins/config)...")
        jenkins_cred = get_jenkins_cred_file()
    else:
        logger.info("Using environment variables...")
        jenkins_cred = get_jenkins_cred_env()
    logger.info(jenkins_cred[0])
    if (jenkins_cred[0] == None):
        logger.error("Errors encountered: Jenkins credentials are not defined. Please define them.")
        logger.error("OPTION 1: Direct parameters:")
        logger.error("    --url http://jenkins.example.com:8080")
        logger.error("    --user user")
        logger.error("    --password secret")
        logger.error("OPTION 2: Jenkins profile config:")
        logger.error("Specify Jenkins credentials in config file as example below:")
        logger.error("cat > ~/.jenkins/config <<EOF")
        logger.error("[profile_name]")
        logger.error("JENKINS_URL=http://jenkins.example.com:8080")
        logger.error("JENKINS_USER=user")
        logger.error("JENKINS_API_TOKEN=secret")
        logger.error("EOF")
        logger.error("OPTION 3: Environment variable:")
        logger.error("On Linux, follow the example:")
        logger.error("    export JENKINS_URL=http://jenkins.example.com:8080")
        logger.error("    export JENKINS_USER=user")
        logger.error("    export JENKINS_API_TOKEN=secret")
        logger.error("On Windows, follow the example:")
        logger.error("    set JENKINS_URL=http://jenkins.example.com:8080")
        logger.error("    set JENKINS_USER=user")
        logger.error("    set JENKINS_API_TOKEN=secret")
        raise Exception("Errors encountered: Jenkins credentials are not defined. Please define them.")
    else:
        logger.info("Using Jenkins URL: {} with user {}".format(jenkins_cred[0], jenkins_cred[1]))
        return jenkins_cred

def get_jenkins_cred_file():
    jenkins_profile = 'default' if (args.profile == None) else args.profile
    jenkins_config = configparser.ConfigParser()
    jenkins_config.read('{}/.jenkins/config'.format(os.environ.get('HOME')))
    JENKINS_URL = jenkins_config[jenkins_profile]['JENKINS_URL']
    JENKINS_USER = jenkins_config[jenkins_profile]['JENKINS_USER']
    JENKINS_API_TOKEN = jenkins_config[jenkins_profile]['JENKINS_API_TOKEN']
    return [ JENKINS_URL, JENKINS_USER, JENKINS_API_TOKEN ]

def get_jenkins_cred_env():
    JENKINS_URL = os.environ.get('JENKINS_URL')
    JENKINS_USER = os.environ.get('JENKINS_USER')
    JENKINS_API_TOKEN = os.environ.get('JENKINS_API_TOKEN')
    return [ JENKINS_URL, JENKINS_USER, JENKINS_API_TOKEN ]

def validate_jenkinsfile(jenkins_cred, file_name):
    http = urllib3.PoolManager()
    crumb_url = '{}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)'.format(jenkins_cred[0])
    header = urllib3.util.make_headers(basic_auth=jenkins_cred[1]+':'+jenkins_cred[2])
    crumb_req = http.request('GET', crumb_url, headers=header)
    crumb = crumb_req.data.decode("utf-8")
    validate_url = '{}/pipeline-model-converter/validate'.format(jenkins_cred[0])
    jenkins_file = file_name if args.file.startswith("/") else os.getcwd() + "/" + file_name
    logger.info("Validating {}...".format(jenkins_file))
    with open(jenkins_file) as fp:
        file_data = fp.read()
    validate_req = http.request('POST',validate_url, headers=header, 
                                fields = {'jenkinsfile' : file_data })
    logger.info(validate_req.data.decode("utf-8"))


def build_job(jenkins_cred, job_name, parameters):
    print('TODO')

if __name__ == '__main__':
    args = parse_args()
    logging.basicConfig(format='%(asctime)s - %(levelname)s - %(message)s',
                    level=logging.DEBUG)
    logger = logging.getLogger(__name__)
    logging.getLogger("urllib3").setLevel(logging.INFO)

    jenkins_cred = get_jenkins_cred()
    if args.subcommand == 'validate':
        validate_jenkinsfile(jenkins_cred, args.file)
    elif args.subcommand == 'build':
        build_job(jenkins_cred, args.job, args.parameters)


