#!/bin/bash
function get_jenkins_cred() {
    local l_item=$1
    local l_profile=$2
    l_profile=${l_profile:=default}
    sed -nr "/^\[$l_profile\]/ { :l /^$l_item[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" $HOME/.jenkins/config
}

JENKINS_URL=${JENKINS_URL:=$(get_jenkins_cred JENKINS_URL)}
JENKINS_USER=${JENKINS_USER:=$(get_jenkins_cred JENKINS_USER)}
JENKINS_API_TOKEN=${JENKINS_API_TOKEN:=$(get_jenkins_cred JENKINS_API_TOKEN)}
JENKINS_FILE=$1

echo "Using ${JENKINS_URL} with user ${JENKINS_USER}"
echo "Getting Jenkins crumb hex..."
JENKINS_CRUMB=`curl -sS -u$JENKINS_USER:$JENKINS_API_TOKEN "$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)"`
echo "Validating Jenkinsfile $JENKINS_FILE ..."
curl -X POST -u$JENKINS_USER:$JENKINS_API_TOKEN -H $JENKINS_CRUMB -F "jenkinsfile=<$JENKINS_FILE" $JENKINS_URL/pipeline-model-converter/validate