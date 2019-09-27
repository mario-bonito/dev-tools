#!/bin/bash

OCTOOLSBIN=$(dirname $0)

# =================================================================================================================
# Usage:
# -----------------------------------------------------------------------------------------------------------------
usage() {
  cat <<-EOF
  Tests to see if a port is open.  The tests can be run locally or remotely on a pod running in OpenShift.

  Usage: $0 [ options ] [host:port]

  Examples:
    $0 google.com:80

    $0 -f ./listOfUrisToTest.txt

    $0 -n devex-von-tools -p django google.com:80

    $0 -n devex-von-tools -p django -f ./listOfUrisToTest.txt

  Standard Options:

    -f read the connection list from a file
    -h prints the usage for the script

  OpenShift Option:
    -n The OpenShift namespace containing the pod
    -p The friendly name of the pod
EOF
exit 1
}
# =================================================================================================================

# =================================================================================================================
# Funtions:
# -----------------------------------------------------------------------------------------------------------------
function readList(){
  (
    if [ -f ${listFile} ]; then
      # Read in the file minus any comments ...
      echo -e \\n"Reading list of hosts and ports from ${listFile} ...\\n" >&2
      _value=$(sed '/^[[:blank:]]*#/d;s/#.*//' ${listFile})
    fi
    echo "${_value}"
  )
}

# Load openshift-developer-tools functions ...
_includeFile="ocFunctions.inc"
if [ ! -z $(type -p ${_includeFile}) ]; then
  _includeFilePath=$(type -p ${_includeFile})
  export OCTOOLSBIN=$(dirname ${_includeFilePath})

  if [ -f ${OCTOOLSBIN}/${_includeFile} ]; then
    . ${OCTOOLSBIN}/${_includeFile}
  fi
else
  _red='\033[0;31m'
  _yellow='\033[1;33m'
  _nc='\033[0m' # No Color
  echo -e \\n"${_red}${_includeFile} could not be found on the path.${_nc}"
  echo -e "${_yellow}Please ensure the openshift-developer-tools are installed on and registered on your path.${_nc}"
  echo -e "${_yellow}https://github.com/BCDevOps/openshift-developer-tools${_nc}"
fi
# =================================================================================================================

# =================================================================================================================
# Initialization:
# -----------------------------------------------------------------------------------------------------------------
while getopts f:n:p:h FLAG; do
  case $FLAG in
    f) export listFile=$OPTARG ;;
    n) export FULLY_QUALIFIED_NAMESPACE=$OPTARG ;;
    p) export podName=$OPTARG ;;
    h ) usage ;;
    \?) #unrecognized option - show help
      echo -e \\n"Invalid script option"\\n
      usage
      ;;
  esac
done
shift $((OPTIND-1))

if [ ! -z "${listFile}" ]; then
  list=$(readList)
else
  list=${@}
fi

if [ -z "${list}" ]; then
  echoError \\n"Missing parameters."\\n
  usage
fi

if [ ! -z "${FULLY_QUALIFIED_NAMESPACE}" ] || [ ! -z "${podName}" ]; then
  if [ -z "${FULLY_QUALIFIED_NAMESPACE}" ] || [ -z "${podName}" ]; then
    echoError \\n"When using any of the OpenShift options, you MUST specify them all."\\n
    usage
  else
    runInPod=1
  fi
fi
# =================================================================================================================

# =================================================================================================================
# Main Script
# Inspired by; https://stackoverflow.com/questions/4922943/test-from-shell-script-if-remote-tcp-port-is-open/9463554
# -----------------------------------------------------------------------------------------------------------------
for item in ${list}; do
  IFS=':' read -r -a segments <<< "${item}"  && unset IFS
  host=${segments[0]}
  port=${segments[1]}

  _command+="echo -n ${host}:${port} && timeout 1 bash -c \"cat < /dev/null > /dev/tcp/${host}/${port}\" && echo ' - Open' || echo ' - Closed';"
done

if [ -z "${runInPod}" ]; then
  echo -e "Testing connections from the local machine ..."
  eval ${_command}
else
  echo -e "Testing connections from $(getProjectName)/${podName} ..."
  runInContainer \
    "${podName}" \
    "${_command}"
fi