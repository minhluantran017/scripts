#!/bin/bash
TOPDIR=`git rev-parse --show-toplevel`
source $TOPDIR/proprietary/dc22devops.sh
source $TOPDIR/lib/common/utils.sh

echo "$INFO Getting Jenkins crumb hex..."
JENKINS_CRUMB=`curl -sS -u$JENKINS_USER:$JENKINS_API_TOKEN "$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)"`
echo "$INFO Validating Jenkinsfile $1 ..."
curl -X POST -u$JENKINS_USER:$JENKINS_API_TOKEN -H $JENKINS_CRUMB -F "jenkinsfile=<$1" $JENKINS_URL/pipeline-model-converter/validate