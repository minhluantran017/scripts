#!/usr/bin/env python3

import argparse
import logging
import time
import sys
import urllib3
import os
from os import path

def parseArgs():
    parser = argparse.ArgumentParser(
        usage='jenkins',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument('--url', type=str,   required=False,
                            help='The Jenkins master URL')
    parser.add_argument('-u', '--user', type=str,   required=False,
                            help='Your Jenkins username')
    parser.add_argument('-p', '--password', type=str,   required=False,
                            help='Your Jenkins password')
    parser.add_argument('-profile', type=str,   required=False,
                            help='The Jenkins profile name in Jenkins config file')

    subparsers = parser.add_subparsers(help='sub-command help', dest='subcommand')

    parser_validate = subparsers.add_parser('validate', help='validate help')

    parser_validate.add_argument('-f', '--file',    type=str,   required=True,
                            help='The Jenkinsfile to validate')
    

    parser_build = subparsers.add_parser('build', help='build help')

    parser_build.add_argument('-j', '--job',    type=str,   required=True,
                            help='The Jenkins job to build')

    parser_build.add_argument('-p', '--parameters',    type=str,   required=False,
                            help='The Jenkins job parameters to build')

    return parser.parse_args()

def getJenkinsCred():
    logger.info("Getting Jenkins credentials...")
    if (args.url != None) :
        jenkins_cred = [args.url, args.user, args.password]
    elif path.exists("~/.jenkins/config"):
        jenkins_cred = getJenkinsCredFile()
    else:
        jenkins_cred = getJenkinsCredEnv()
    logger.info(jenkins_cred[0])
    if (jenkins_cred[0] == None):
        logger.error("Error while processing: Jenkins credentials are not defined. Please define them.")
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
        logger.error("JENKINS_TOKEN=secret")
        logger.error("EOF")
        logger.error("OPTION 3: Environment variable:")
        logger.error("On Linux, follow the example:")
        logger.error("    export JENKINS_URL=http://jenkins.example.com:8080")
        logger.error("    export JENKINS_USER=user")
        logger.error("    export JENKINS_TOKEN=secret")
        logger.error("On Windows, follow the example:")
        logger.error("    set JENKINS_URL=http://jenkins.example.com:8080")
        logger.error("    set JENKINS_USER=user")
        logger.error("    set JENKINS_TOKEN=secret")
    else:
        logger.info("Using Jenkins URL: {} with user {}".format(jenkins_cred[0], jenkins_cred[1]))

def getJenkinsCredFile():
    print('TODO')
def getJenkinsCredEnv():
    JENKINS_URL = os.environ.get('JENKINS_URL')
    JENKINS_USER = os.environ.get('JENKINS_USER')
    JENKINS_TOKEN = os.environ.get('JENKINS_TOKEN')

    return [ JENKINS_URL, JENKINS_USER, JENKINS_TOKEN ]
        

def validate_jenkinsfile(Jenkins, File):
    logger.info("Validating {file}".format(file=File))
    http = urllib3.PoolManager()
    logger.info(Jenkins)
    crumb_url = '{url}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)'.format(url=Jenkins)
    headers = urllib3.util.make_headers(basic_auth=Jenkins[1]+':'+Jenkins[2])
    logger.info("Headers:" + headers)
    #r = http.request('GET', crumb_url,, )
    #logger.info("CRUMB_ISSUER="+ r.data)


if __name__ == '__main__':
    args = parseArgs()
    logging.basicConfig(format='%(message)s',
                    level=logging.DEBUG)
    logger = logging.getLogger(__name__)

    jenkins = getJenkinsCred()
    # if args.subcommand == 'validate':
    #     validate_jenkinsfile(jenkins, args.file)
    # elif args.subcommand == 'build':
    #     build_job(jenkins, args.job, args.parameters)


