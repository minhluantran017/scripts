#!/bin/bash
function usage() {
   cat << USAGE >&2
Usage:
   build
      -j JOBNAME  | --job test-build-job                 The name of the Jenkins job to trigger
      -p JOBPARAM | --parameter environment=uat&test=1   Jenkins job parameters
      -t TIMEOUT  | --timeout 30                         Job timeout (in minutes)
   
   validate
      -f FILE     | --file Jenkinsfile                   Path to Jenkinsfile to validate
USAGE
   exit 1
}

function get_config_field() {
   local l_item=$1
   local l_profile=$2
   l_profile=${l_profile:=default}
   sed -nr "/^\[$l_profile\]/ { :l /^$l_item[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" $HOME/.jenkins/config
}

function get_crumb_issuer() {
   curl -sS ${USER} "$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)"
}

function get_credential() {
   JENKINS_URL=${JENKINS_URL:-$(get_config_field JENKINS_URL)}
   JENKINS_USER=${JENKINS_USER:-$(get_config_field JENKINS_USER)}
   JENKINS_API_TOKEN=${JENKINS_API_TOKEN:-$(get_config_field JENKINS_API_TOKEN)}
   if [[ -z ${JENKINS_URL} ]]; then
      echo "No Jenkins host set. Exit now."
      exit 1
   elif [[ -n ${JENKINS_USER} ]]; then
      echo "Using ${JENKINS_URL} with user ${JENKINS_USER}..."
      USER="-u$JENKINS_USER:$JENKINS_API_TOKEN"
      echo "Getting crumb issuer..."
      CRUMB="-H $(get_crumb_issuer)"
   else
      echo "Using ${JENKINS_URL}..."
      USER=""
      CRUMB=""
   fi
}

function validate_jenkinsfile() {
   local l_file=$1
   echo "Validating Jenkinsfile $l_file ..."
   curl -X POST ${USER} ${CRUMB} -F "jenkinsfile=<$l_file" $JENKINS_URL/pipeline-model-converter/validate
}

function build_job() {
   local l_jobname=$1
   local l_params=$2
   local l_timeout=$3

   local l_queue_retries=60
   local l_queue_retry_ind=0
   local l_timeout_retries=$(( l_timeout * 6 ))
   local l_timeout_retry_ind=0

   if [[ -n ${l_params} ]]; then
      l_trigger_url="${JENKINS_URL}/job/${l_jobname}/buildWithParameters?${l_params}"
      echo "Making request to trigger ${JENKINS_URL}/job/${l_jobname} with parameter ${l_params}..."
   else
      l_trigger_url="${JENKINS_URL}/job/${l_jobname}/build?delay=0sec"
      echo "Making request to trigger ${JENKINS_URL}/job/${l_jobname} ..."
   fi

   l_trigger=`curl ${USER} -s -D - -X POST "${l_trigger_url}"`
   l_queue_id=`echo "${l_trigger}" | grep Location | cut -d "/" -f 6`
   l_queue_url="${JENKINS_URL}/queue/item/${l_queue_id}/api/json?pretty=true"

   while curl ${USER} -v ${l_queue_url} 2>&1 | egrep -q "BlockedItem|WaitingItem";
   do
      echo "Waiting for queued job to start.."
      sleep 5
      ((l_queue_retry_ind = l_queue_retry_ind + 1))
      if [[ $l_queue_retry_ind -ge $l_queue_retries ]]; then
         echo "ERROR: Exceed number of retries"
         exit 1
      fi
   done

   l_job_number=$(curl ${USER} -s "${l_queue_url}" | jq --raw-output '.executable.number')
   l_job_url=$(curl ${USER} -s "${l_queue_url}" | jq --raw-output '.executable.url')

   if [[ -z "${l_job_number}" ]]; then
      echo "Error when creating job ${l_jobname}."
      exit 1
   else
      echo "Jenkins job ${l_jobname}, build number ${l_job_number} created, waiting to complete..."
      echo "Job URL: ${l_job_url}"
   fi

   local l_status=""
   while [ "${l_status}" != 200 ]
   do
      sleep 1
      l_status=`curl ${USER} -s -o /dev/null -w "%{http_code}" "${l_job_url}"consoleText`
   done

   l_json_url="${l_job_url}"api/json?pretty=true
   l_building=$(curl ${USER} -s "${l_json_url}" |jq --raw-output '.building')

   while $l_building; do
      l_building=$(curl ${USER} -s "${l_json_url}" |jq --raw-output '.building')
      sleep 10
      ((l_timeout_retry_ind = l_timeout_retry_ind + 1))
      if [[ $l_timeout_retry_ind -ge $l_timeout_retries ]]; then
         echo "ERROR: Exceed number of retries"
         exit 1
      fi
   done

   l_job_status=$(curl ${USER} -s "${l_json_url}" |jq --raw-output '.result')
   echo "Job ${l_jobname}#${l_job_number} finished with l_status: ${l_job_status}"
   [[ "${l_job_status}" == "SUCCESS" ]]
}

# process arguments
while [[ $# -gt 0 ]]
do
   case "$1" in
      build)
         ACTION=build
         shift 1
         ;;
      validate)
         ACTION=validate
         shift 1
         ;;
      -f | --file)
         JENKINSFILE="$2"
         shift 2
         ;;
      -j | --job)
         JOBNAME="$2"
         shift 2
         ;;
      -p | --parameter)
         JOBPARAM="$2"
         shift 2
         ;;
      -t | --timeout)
         TIMEOUT="$2"
         shift 2
         ;;
      -h | --help)
         usage
         ;;
      *)
         echo "Unknown argument: $1"
         usage
         ;;
   esac
done

TIMEOUT=${TIMEOUT:-30}

get_credential

if [[ ${ACTION} == 'build' ]]; then
   echo build_job $JOBNAME $JOBPARAM $TIMEOUT
elif [[ ${ACTION} == 'validate' ]]; then
   validate_jenkinsfile $JENKINSFILE
fi